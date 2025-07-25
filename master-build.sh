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
read -p "System short name (e.g., aaco, metro, county): " SHORT_NAME

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
mkdir -p /var/lib/trunk-recorder/recordings
mkdir -p /var/log/trunk-recorder

# Set initial permissions
chown -R trunkrecorder:trunkrecorder /var/lib/trunk-recorder
chown -R trunkrecorder:trunkrecorder /var/log/trunk-recorder

# Run the RadioReference data fetcher script to get system config
cd "$SCRIPT_DIR"
echo "Connecting to RadioReference.com..."
python3 fetch-radioreference.py "$RR_USERNAME" "$RR_PASSWORD" "$RR_SID" --shortname "$SHORT_NAME"

# Verify that the required config files were generated
if [ ! -f "config.json" ] || [ ! -f "talkgroup.csv" ]; then
    echo "✗ Failed to generate configuration files"
    exit 1
fi

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

echo "✓ Configuration complete - nightly updates disabled for now"

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
