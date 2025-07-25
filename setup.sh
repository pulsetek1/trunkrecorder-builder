#!/bin/bash

# Enable exit on error
set -e

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

# Define key directory paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"  # Get current script directory
INSTALL_DIR="/opt/trunk-recorder"                           # Main installation directory
SERVICE_USER="trunkrecorder"                               # Service user account
RECORDINGS_DIR="/var/lib/trunk-recorder/recordings"         # Directory for radio recordings
LOG_DIR="/var/log/trunk-recorder"                          # Directory for log files

# Print welcome message
echo "=== Trunk Recorder System Deployment ==="
echo "Installing P25 trunked radio monitoring system"
echo "System will use 1-3 RTL-SDR radios as needed"
echo

# Verify script is run with root privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)" 
   exit 1
fi

# Check for existing installation and handle accordingly
if [ -f "/opt/trunk-recorder/trunk-recorder" ] || [ -f "/usr/local/bin/trunk-recorder" ]; then
    echo "📡 Trunk Recorder is already installed"
    
    # Check if service is currently running
    if systemctl is-active --quiet trunk-recorder; then
        echo "⚠️  Trunk Recorder service is currently running"
    fi
    
    # Prompt for reinstall or config update only
    read -p "Would you like to reinstall Trunk Recorder? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        # Update config files only
        echo "Updating configuration files only..."
        cp "$SCRIPT_DIR/config.json" /etc/trunk-recorder/
        cp "$SCRIPT_DIR/talkgroup.csv" /etc/trunk-recorder/
        chown trunkrecorder:trunkrecorder /etc/trunk-recorder/config.json /etc/trunk-recorder/talkgroup.csv
        
        # Restart service to apply new config
        echo "Restarting Trunk Recorder to apply new configuration..."
        systemctl restart trunk-recorder
        sleep 3
        systemctl status trunk-recorder --no-pager
        
        echo "Configuration updated successfully!"
        exit 0
    fi
    
    # Stop existing service if running
    if systemctl is-active --quiet trunk-recorder; then
        echo "Stopping Trunk Recorder service..."
        systemctl stop trunk-recorder
        sleep 2
    fi
fi

# Update system packages
echo "Updating system packages..."
safe_apt update && safe_apt upgrade -y

# Install required dependencies
echo "Installing dependencies..."
safe_apt install -y \
    build-essential \
    cmake \
    git \
    libboost-all-dev \
    libcurl4-openssl-dev \
    libgmp-dev \
    libhackrf-dev \
    libpthread-stubs0-dev \
    librtlsdr-dev \
    libsndfile1-dev \
    libsoapysdr-dev \
    libuhd-dev \
    libusb-1.0-0-dev \
    pkg-config \
    qtbase5-dev \
    qtmultimedia5-dev \
    rtl-sdr \
    soapysdr-tools \
    sox \
    gnuradio \
    gnuradio-dev \
    gr-osmosdr \
    liborc-0.4-dev \
    libfftw3-dev \
    libgsl-dev \
    libssl-dev \
    fdkaac \
    unattended-upgrades \
    apt-listchanges

# Create service user account if it doesn't exist
echo "Creating service user..."
if ! id "$SERVICE_USER" &>/dev/null; then
    useradd -r -s /bin/false -d /var/lib/trunk-recorder "$SERVICE_USER"
fi

# Add service user to required groups
usermod -a -G dialout,plugdev "$SERVICE_USER"

# Create required directories
echo "Creating directory structure..."
mkdir -p "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR/logs"
mkdir -p "$RECORDINGS_DIR"
mkdir -p "$LOG_DIR"
mkdir -p /etc/trunk-recorder

# Set directory ownership
chown -R "$SERVICE_USER:$SERVICE_USER" "$RECORDINGS_DIR"
chown -R "$SERVICE_USER:$SERVICE_USER" "$LOG_DIR"
chown -R "$SERVICE_USER:$SERVICE_USER" "$INSTALL_DIR"

# Configure RTL-SDR devices
echo "Configuring RTL-SDR..."
# Blacklist conflicting kernel modules
cat > /etc/modprobe.d/blacklist-rtl.conf << 'EOF'
blacklist dvb_usb_rtl28xxu
blacklist rtl2832
blacklist rtl2830
EOF

# Set up udev rules for RTL-SDR device access
cat > /etc/udev/rules.d/20-rtlsdr.rules << 'EOF'
SUBSYSTEM=="usb", ATTRS{idVendor}=="0bda", ATTRS{idProduct}=="2838", GROUP="trunkrecorder", MODE="0666", SYMLINK+="rtl_sdr"
EOF

# Apply new udev rules
udevadm control --reload-rules
udevadm trigger

# Clone and build Trunk Recorder from source
echo "Cloning Trunk Recorder..."
cd /tmp
if [ -d "trunk-recorder" ]; then
    rm -rf trunk-recorder
fi

git clone https://github.com/robotastic/trunk-recorder.git
cd trunk-recorder

# Build the application
echo "Building Trunk Recorder (this may take 15-30 minutes)..."
mkdir build
cd build
cmake ..
make -j$(nproc)

# Install the built application
echo "Installing Trunk Recorder..."
make install
cp trunk-recorder "$INSTALL_DIR/"

# Copy any available plugins
if [ -d "plugins" ]; then
    cp -r plugins "$INSTALL_DIR/"
fi

# Install configuration files (skip if already exist to preserve device assignments)
echo "Setting up configuration..."
if [ ! -f "/etc/trunk-recorder/config.json" ]; then
    cp "$SCRIPT_DIR/config.json" /etc/trunk-recorder/
else
    echo "Config already exists, preserving existing configuration"
fi
cp "$SCRIPT_DIR/talkgroup.csv" /etc/trunk-recorder/

# Process talkgroup file to limit description length
echo "Truncating talkgroup descriptions..."
python3 << 'TGEOF'
import csv

# Read the talkgroup file
with open('/etc/trunk-recorder/talkgroup.csv', 'r') as f:
    reader = csv.reader(f)
    rows = list(reader)

# Process each row (skip header)
for i in range(1, len(rows)):
    if len(rows[i]) >= 5:  # Make sure we have enough columns
        desc = rows[i][4]  # Description column
        if len(desc) > 25:
            # Truncate to 25 characters
            rows[i][4] = desc[:25]

# Write back to file
with open('/etc/trunk-recorder/talkgroup.csv', 'w', newline='') as f:
    writer = csv.writer(f)
    writer.writerows(rows)

print("Talkgroup descriptions truncated to 25 characters")
TGEOF

# Skip config modification to preserve device assignments
echo "Configuration file paths already set correctly"

# Create systemd service definition
echo "Creating systemd service..."
cat > /etc/systemd/system/trunk-recorder.service << EOF
[Unit]
Description=Trunk Recorder - P25 Radio System Monitor
After=network.target
Wants=network.target

[Service]
Type=simple
User=$SERVICE_USER
Group=$SERVICE_USER
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/trunk-recorder --config=/etc/trunk-recorder/config.json
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

# Resource limits
LimitNOFILE=65536
LimitNPROC=32768

[Install]
WantedBy=multi-user.target
EOF

# Configure log rotation
echo "Setting up log rotation..."
cat > /etc/logrotate.d/trunk-recorder << 'EOF'
/var/log/trunk-recorder/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 644 trunkrecorder trunkrecorder
    postrotate
        systemctl reload trunk-recorder || true
    endscript
}
EOF

# Set up automatic cleanup of old recordings
echo "Setting up automatic recording cleanup..."
cat > /usr/local/bin/cleanup-recordings.sh << 'EOF'
#!/bin/bash

# Delete recordings older than 14 days
find /var/lib/trunk-recorder/recordings -type f -name "*.wav" -mtime +14 -delete

# Delete empty directories
find /var/lib/trunk-recorder/recordings -type d -empty -delete
EOF

chmod +x /usr/local/bin/cleanup-recordings.sh

# Create daily cleanup cron job
cat > /etc/cron.daily/cleanup-recordings << 'EOF'
#!/bin/sh
/usr/local/bin/cleanup-recordings.sh
EOF

chmod +x /etc/cron.daily/cleanup-recordings

# Set final file permissions
chown -R "$SERVICE_USER:$SERVICE_USER" /etc/trunk-recorder
chmod 755 "$INSTALL_DIR/trunk-recorder"

# Enable the service
echo "Enabling Trunk Recorder service..."
systemctl daemon-reload
systemctl enable trunk-recorder

# Test RTL-SDR radio devices
echo "Testing RTL-SDR devices..."
for i in {0..2}; do
    echo "Testing RTL-SDR device $i..."
    timeout 5 rtl_test -d $i -s 2400000 || echo "Warning: RTL-SDR device $i test failed"
done

# Print installation summary
echo
echo "=== Installation Complete ==="
echo "Configuration files: /etc/trunk-recorder/"
echo "Recordings directory: $RECORDINGS_DIR"
echo "Log directory: $LOG_DIR"
echo
echo "To start the service:"
echo "  sudo systemctl start trunk-recorder"
echo
echo "To check status:"
echo "  sudo systemctl status trunk-recorder"
echo
echo "To view logs:"
echo "  sudo journalctl -u trunk-recorder -f"
echo
echo "To check recordings:"
echo "  ls -la $RECORDINGS_DIR"
echo

# Prompt to start service
read -p "Start Trunk Recorder service now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    systemctl start trunk-recorder
    echo "Service started. Checking status..."
    sleep 3
    systemctl status trunk-recorder --no-pager
fi

# Configure automatic system updates
echo "Configuring automatic system updates..."
cat > /etc/apt/apt.conf.d/20auto-upgrades << 'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF

# Configure automatic system reboots after updates
sed -i 's|//Unattended-Upgrade::Automatic-Reboot "false";|Unattended-Upgrade::Automatic-Reboot "true";|' /etc/apt/apt.conf.d/50unattended-upgrades
sed -i 's|//Unattended-Upgrade::Automatic-Reboot-Time "02:00";|Unattended-Upgrade::Automatic-Reboot-Time "03:00";|' /etc/apt/apt.conf.d/50unattended-upgrades

echo "Setup complete!"
