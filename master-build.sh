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
echo "🚀 Complete P25 Radio System Deployment"
echo
echo "This script will:"
echo "  1. Connect to RadioReference.com to download your radio system data"
echo "  2. Generate optimized RTL-SDR configuration for your frequencies"
echo "  3. Install and configure Trunk Recorder from source"
echo "  4. Set up automatic nightly updates from RadioReference"
echo "  5. Configure upload services (Broadcastify, OpenMHz, RDIOScanner)"
echo
echo "⏱️  Estimated time: 20-45 minutes (depending on system)"
echo "📡 Requirements: 1-3 RTL-SDR dongles, RadioReference premium account"
echo

# Check if script is being run with root privileges
if [[ $EUID -ne 0 ]]; then
   echo "❌ This script must be run as root (use sudo)" 
   exit 1
fi

echo "📋 Step 1: RadioReference.com Configuration"
echo "==========================================="
echo
echo "RadioReference.com is a database of radio frequencies and talkgroups."
echo "You need a PREMIUM account to download CSV data for your radio system."
echo
echo "To find your System ID:"
echo "  1. Go to RadioReference.com"
echo "  2. Search for your county/city radio system"
echo "  3. Look at the URL: /db/sid/XXXXX (XXXXX is your System ID)"
echo

# Prompt user for RadioReference.com credentials and system information
read -p "RadioReference.com Username: " RR_USERNAME
read -s -p "RadioReference.com Password: " RR_PASSWORD
echo
read -p "System ID (numbers only, e.g., 12059): " RR_SID

# Validate System ID is numeric
if ! [[ "$RR_SID" =~ ^[0-9]+$ ]]; then
    echo "❌ Error: System ID must be numbers only"
    exit 1
fi

while true; do
    read -p "System short name (4-10 chars, e.g., metro, county): " SHORT_NAME
    if [[ ${#SHORT_NAME} -ge 4 && ${#SHORT_NAME} -le 10 ]]; then
        break
    else
        echo "❌ Error: Short name must be 4-10 characters long"
    fi
done
read -p "System abbreviation for categories (e.g., METRO, COUNTY): " SYSTEM_ABBREV

echo
echo "📋 Step 2: System Verification & Setup"
echo "====================================="
echo "🔍 Verifying RadioReference.com credentials and system data..."
echo

# Install required Python packages for the RadioReference scraper
echo "📦 Installing required Python packages..."
safe_apt update
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
    echo "❌ Failed to generate configuration files"
    echo "Please check your RadioReference credentials and System ID"
    exit 1
fi

echo "✅ Configuration files generated successfully"

echo
echo "📋 Step 3: RadioReference Data Fetch"
echo "==================================="
echo "🌐 Connecting to RadioReference.com..."
echo "📊 This will show your frequency distribution and RTL-SDR requirements"
echo

# Run the RadioReference data fetcher script to get system config and capture siteid
cd "$SCRIPT_DIR"
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

echo
echo "📋 Step 4: Nightly Update Configuration"
echo "======================================"
echo "⏰ Setting up automatic talkgroup updates from RadioReference..."
echo

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
echo
echo "📋 Step 5: Trunk Recorder Installation"
echo "====================================="
echo "🔨 Installing Trunk Recorder from source..."
echo "⏱️  This may take 15-30 minutes depending on your system"
echo
./setup.sh

# Display completion message and status
echo
echo "🎉 === Master Build Complete === 🎉"
echo "Your Trunk Recorder system is now fully configured!"
echo
echo "📁 Generated files:"
echo "  ✓ config.json (optimized RTL-SDR configuration)"
echo "  ✓ talkgroup.csv (RadioReference talkgroup data)"
echo "  ✓ siteinfo.json (frequency and site information)"
echo
echo "🔄 Automatic features enabled:"
echo "  ✓ Nightly talkgroup updates from RadioReference"
echo "  ✓ RAM-based recording storage (SD card protection)"
echo "  ✓ Automatic cleanup of old recordings"
echo
echo "📊 System status:"
sudo systemctl status trunk-recorder --no-pager || true
echo
echo "📚 Next steps:"
echo "  • Monitor logs: sudo journalctl -u trunk-recorder -f"
echo "  • Check recordings: ls -la /trunkrecorder/recordings/"
echo "  • View configuration: cat /etc/trunk-recorder/config.json"
echo
echo "🆘 Need help? Check DEPLOYMENT.md or GitHub issues"
