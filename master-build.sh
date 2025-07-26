#!/bin/bash

# Trunk Recorder Master Build System
# This script automates the setup of a complete Trunk Recorder system by:
# - Getting RadioReference.com credentials and system info from user
# - Fetching system configuration and talkgroup data
# - Setting up nightly updates
# - Installing and configuring the full Trunk Recorder system

# Exit immediately if any command fails
set -e

# Get absolute path to script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to wait for apt lock to be released
wait_for_apt_lock() {
    echo "Checking for apt lock conflicts..."
    while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do
        echo "Waiting for other package managers to finish..."
        sleep 5
    done
    echo "✓ Apt lock available"
}

# Function to run apt commands with lock handling
safe_apt() {
    wait_for_apt_lock
    apt "$@"
}

echo "=== Trunk Recorder Master Build System ==="
echo "This will fetch data from RadioReference.com and deploy a complete system"
echo

# Check if script is being run with root privileges
# This is required for system configuration and package installation
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)" 
   exit 1
fi

# Prompt user for RadioReference.com credentials and system information
# RR_USERNAME - RadioReference.com account username
# RR_PASSWORD - RadioReference.com account password 
# RR_SID - System ID number from RadioReference URL
# SHORT_NAME - Brief name to identify this system
echo "RadioReference.com Login Required:"
read -p "Username: " RR_USERNAME
read -s -p "Password: " RR_PASSWORD
echo
read -p "System ID (from URL like /db/sid/12059): " RR_SID
while true; do
    read -p "System short name (4-10 characters, e.g., aaco, metro, county): " SHORT_NAME
    if [[ ${#SHORT_NAME} -ge 4 && ${#SHORT_NAME} -le 10 ]]; then
        break
    else
        echo "Error: Short name must be 4-10 characters long"
    fi
done
read -p "System abbreviation for categories (e.g., AACO, METRO, COUNTY): " SYSTEM_ABBREV

echo
echo "Verifying system information..."

# Install required Python packages for the RadioReference scraper
echo "Updating package lists..."
safe_apt update
echo "Installing required Python packages..."
safe_apt install -y python3-requests python3-bs4

# Create service user and group if they don't exist
echo "Creating trunkrecorder user and group..."
if ! id "trunkrecorder" &>/dev/null; then
    useradd -r -s /bin/false -d /var/lib/trunk-recorder trunkrecorder
fi

# Create required directories
echo "Creating directory structure..."
mkdir -p /etc/trunk-recorder
mkdir -p /opt/trunk-recorder
mkdir -p /var/lib/trunk-recorder

# Set initial permissions (legacy directory for user home)
chown -R trunkrecorder:trunkrecorder /var/lib/trunk-recorder



# Verify that the required config files were generated
if [ ! -f "config.json" ] || [ ! -f "talkgroup.csv" ]; then
    echo "✗ Failed to generate configuration files"
    exit 1
fi

# Run the RadioReference data fetcher script to get system config and capture siteid
cd "$SCRIPT_DIR"
echo "Connecting to RadioReference.com..."
python3 fetch-radioreference.py "$RR_USERNAME" "$RR_PASSWORD" "$RR_SID" --shortname "$SHORT_NAME" --abbrev "$SYSTEM_ABBREV" --capture-siteid

# Get the siteid from the generated file
SITEID=""
if [ -f "siteid.txt" ]; then
    SITEID=$(cat siteid.txt)
    rm siteid.txt
fi

# Store deployment settings for nightly updates
echo "Storing deployment settings..."
cat > /etc/trunk-recorder/deployment-settings.json << EOF
{
  "username": "$RR_USERNAME",
  "password": "$RR_PASSWORD",
  "sid": "$RR_SID",
  "shortname": "$SHORT_NAME",
  "abbrev": "$SYSTEM_ABBREV",
  "siteid": "$SITEID",
  "deployed_date": "$(date -Iseconds)"
}
EOF
chown trunkrecorder:trunkrecorder /etc/trunk-recorder/deployment-settings.json
chmod 600 /etc/trunk-recorder/deployment-settings.json

# Copy generated config files to system directories
echo "Installing configuration files..."
echo "DEBUG: Local config device assignments:"
grep -A 1 "device" config.json
cp config.json /etc/trunk-recorder/
cp talkgroup.csv /etc/trunk-recorder/
chown trunkrecorder:trunkrecorder /etc/trunk-recorder/config.json /etc/trunk-recorder/talkgroup.csv
echo "DEBUG: System config device assignments after copy:"
grep -A 1 "device" /etc/trunk-recorder/config.json

echo "✓ Configuration files installed successfully"
echo "✓ Deployment settings saved for nightly updates"
echo

# Configure RTL-SDR devices with unique index numbers
echo "Checking RTL-SDR devices..."
if [ -x "$SCRIPT_DIR/configure-rtlsdr.sh" ]; then
    # Check if trunk-recorder service is running and stop it if needed
    SERVICE_WAS_RUNNING="false"
    if systemctl is-active --quiet trunk-recorder; then
        SERVICE_WAS_RUNNING="true"
        echo "Stopping trunk-recorder service for RTL-SDR configuration..."
        systemctl stop trunk-recorder
        echo "Waiting for service to stop completely..."
        sleep 3
    fi
    
    # Run the configuration script but don't exit if it fails
    "$SCRIPT_DIR/configure-rtlsdr.sh" || {
        echo "⚠️  RTL-SDR configuration encountered an issue"
        echo "Continuing with deployment anyway"
    }
    
    # Restart trunk-recorder service if it was running before
    if [ "$SERVICE_WAS_RUNNING" = "true" ]; then
        echo "Restarting trunk-recorder service..."
        systemctl start trunk-recorder
    fi
else
    echo "⚠️  RTL-SDR configuration script not found or not executable"
    echo "Continuing without RTL-SDR device configuration"
fi

echo "✓ Configuration complete - setting up nightly updates..."

# Create nightly update script
cat > /usr/local/bin/update-talkgroups.sh << 'EOF'
#!/bin/bash
set -e

LOG_DIR="/var/log/trunkrecorder"
LOG_FILE="$LOG_DIR/$(date +%Y%m%d)_update.log"
SETTINGS_FILE="/etc/trunk-recorder/deployment-settings.json"
SCRIPT_DIR="/opt/trunk-recorder"

# Create log directory
mkdir -p "$LOG_DIR"

# Function to log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "Starting nightly talkgroup update"

# Check if settings file exists
if [ ! -f "$SETTINGS_FILE" ]; then
    log "ERROR: Deployment settings file not found at $SETTINGS_FILE"
    exit 1
fi

# Read settings
USERNAME=$(python3 -c "import json; print(json.load(open('$SETTINGS_FILE'))['username'])")
PASSWORD=$(python3 -c "import json; print(json.load(open('$SETTINGS_FILE'))['password'])")
SID=$(python3 -c "import json; print(json.load(open('$SETTINGS_FILE'))['sid'])")
SHORTNAME=$(python3 -c "import json; print(json.load(open('$SETTINGS_FILE'))['shortname'])")
ABBREV=$(python3 -c "import json; print(json.load(open('$SETTINGS_FILE'))['abbrev'])")

log "Updating talkgroups for SID $SID ($SHORTNAME)"

# Change to script directory
cd "$SCRIPT_DIR"

# Run the fetch script to update talkgroups only
if python3 fetch-radioreference.py "$USERNAME" "$PASSWORD" "$SID" --shortname "$SHORTNAME" --abbrev "$ABBREV" --update-only 2>&1 | tee -a "$LOG_FILE"; then
    log "Successfully fetched updated talkgroup data"
    
    # Copy new talkgroup file
    if [ -f "talkgroup.csv" ]; then
        cp talkgroup.csv /etc/trunk-recorder/
        chown trunkrecorder:trunkrecorder /etc/trunk-recorder/talkgroup.csv
        log "Updated talkgroup.csv installed"
        
        # Restart trunk-recorder service
        log "Restarting trunk-recorder service"
        systemctl restart trunk-recorder
        
        if systemctl is-active --quiet trunk-recorder; then
            log "Service restarted successfully"
        else
            log "ERROR: Service failed to restart"
            exit 1
        fi
    else
        log "ERROR: talkgroup.csv not generated"
        exit 1
    fi
else
    log "ERROR: Failed to fetch talkgroup data"
    exit 1
fi

log "Nightly update completed successfully"
EOF

chmod +x /usr/local/bin/update-talkgroups.sh

# Create systemd service for nightly updates
cat > /etc/systemd/system/talkgroup-update.service << EOF
[Unit]
Description=Nightly Talkgroup Update
After=network.target

[Service]
Type=oneshot
User=root
ExecStart=/usr/local/bin/update-talkgroups.sh
EOF

# Create systemd timer for nightly updates
cat > /etc/systemd/system/talkgroup-update.timer << EOF
[Unit]
Description=Run talkgroup update nightly
Requires=talkgroup-update.service

[Timer]
OnCalendar=daily
RandomizedDelaySec=1800
Persistent=true

[Install]
WantedBy=timers.target
EOF

# Enable and start the timer
systemctl daemon-reload
systemctl enable talkgroup-update.timer
systemctl start talkgroup-update.timer

echo "✓ Nightly talkgroup updates configured"

# Install Trunk Recorder from source
echo "Installing Trunk Recorder from source..."
./setup.sh

# Display completion message and status
echo
echo "=== Master Build Complete ==="
echo "Your Trunk Recorder system is now fully configured and running!"
echo
echo "Generated files:"
echo "  - config.json (with RadioReference data)"
echo "  - talkgroup.csv (with RadioReference talkgroups)"
echo
echo "System status:"
sudo systemctl status trunk-recorder --no-pager || true
