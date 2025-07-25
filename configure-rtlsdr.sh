#!/bin/bash

# RTL-SDR Device Configuration Script
# This script ensures each RTL-SDR device has a unique index number
# starting from 0, using rtl_eeprom to set serial numbers if needed

# Don't exit on error - we want to continue the main script even if this fails
set +e

echo "=== RTL-SDR Device Configuration ==="
echo "Ensuring all devices have unique index numbers"
echo

# Check if rtl-sdr tools are installed
if ! command -v rtl_test &> /dev/null || ! command -v rtl_eeprom &> /dev/null; then
    echo "Installing rtl-sdr tools..."
    apt update
    apt install -y rtl-sdr
fi

# Count connected RTL-SDR devices
count_devices() {
    # Try to get device count using rtl_test
    local count
    count=$(rtl_test -t 2>&1 | grep -o "Found [0-9]* device" | grep -o "[0-9]*")
    
    # If that fails, try lsusb
    if [ -z "$count" ]; then
        count=$(lsusb | grep -c "RTL2838")
    fi
    
    # If still no count, try another lsusb pattern
    if [ -z "$count" ] || [ "$count" -eq "0" ]; then
        count=$(lsusb | grep -c "0bda:2838")
    fi
    
    echo "$count"
}

# Function to check if devices have unique serial numbers
check_serials() {
    echo "Checking device serial numbers..."
    
    # Array to store serials
    declare -a SERIALS
    local DUPLICATE=0
    local device_count=$1
    
    # Check each device
    for i in $(seq 0 $((device_count-1))); do
        # Get serial for this device
        SERIAL=$(rtl_eeprom -d $i 2>&1 | grep "Serial number:" | awk '{print $3}')
        
        echo "Device $i: Serial = $SERIAL"
        
        # Check if this serial is already in our array
        for s in "${SERIALS[@]}"; do
            if [ "$s" == "$SERIAL" ]; then
                echo "⚠️  Duplicate serial detected: $SERIAL"
                DUPLICATE=1
            fi
        done
        
        # Add to array
        SERIALS+=("$SERIAL")
    done
    
    return $DUPLICATE
}

# Function to assign new serial numbers
assign_serials() {
    echo "Assigning unique serial numbers to devices..."
    
    # Base serial prefix
    PREFIX="TRUNK"
    local device_count=$1
    
    # Assign for each device
    for i in $(seq 0 $((device_count-1))); do
        NEW_SERIAL="${PREFIX}00${i}"
        echo "Setting device $i serial to: $NEW_SERIAL"
        
        # Write new serial
        rtl_eeprom -d $i -s "$NEW_SERIAL" 2>&1 > /dev/null
        
        # Verify write
        CURRENT=$(rtl_eeprom -d $i 2>&1 | grep "Serial number:" | awk '{print $3}')
        if [ "$CURRENT" == "$NEW_SERIAL" ]; then
            echo "✅ Device $i serial set successfully"
        else
            echo "❌ Failed to set serial for device $i"
        fi
    done
    
    echo "Serial numbers assigned. Devices need to be unplugged and reconnected."
    echo "Please unplug all RTL-SDR devices, wait 5 seconds, then plug them back in."
    read -p "Press Enter after reconnecting devices..." -r
}

# Function to update config.json with correct device indices
update_config() {
    echo "Config.json already has correct device indices from fetch script"
    echo "Skipping device index update to preserve correct assignments"
}

# Main execution
echo "This script will configure RTL-SDR devices with unique index numbers"
echo "WARNING: This will modify the EEPROM of your RTL-SDR devices!"
echo "Make sure all RTL-SDR devices you want to use are connected."
echo

# Check if trunk-recorder service is running
if systemctl is-active --quiet trunk-recorder; then
    echo "⚠️ WARNING: trunk-recorder service is currently running!"
    echo "RTL-SDR configuration may fail if the service is using the devices."
    echo "It's recommended to stop the service before continuing."
    read -p "Stop trunk-recorder service and continue? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Stopping trunk-recorder service..."
        systemctl stop trunk-recorder
        sleep 3
    else
        echo "Continuing with service running (not recommended)..."
    fi
fi

# Prompt for confirmation
read -p "Continue with RTL-SDR configuration? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Configuration cancelled."
    exit 0
fi

# Count devices
echo "Detecting connected RTL-SDR devices..."
DEVICE_COUNT=$(count_devices)

# Check if we found any devices
if [ -z "$DEVICE_COUNT" ] || [ "$DEVICE_COUNT" -eq "0" ]; then
    echo "❌ No RTL-SDR devices detected!"
    echo "Please connect at least one RTL-SDR device and try again."
    exit 0
fi

echo "✅ Found $DEVICE_COUNT RTL-SDR device(s)"

# Check if devices have unique serials
check_serials $DEVICE_COUNT
NEEDS_SERIALS=$?

# Assign serials if needed
if [ $NEEDS_SERIALS -eq 1 ]; then
    echo "Devices need unique serial numbers for proper indexing"
    assign_serials $DEVICE_COUNT
    
    # Re-count devices after reconnection
    echo "Re-detecting devices after serial number assignment..."
    DEVICE_COUNT=$(count_devices)
    
    # Verify serials are now unique
    check_serials $DEVICE_COUNT
    STILL_DUPLICATE=$?
    
    if [ $STILL_DUPLICATE -eq 1 ]; then
        echo "❌ Failed to assign unique serials. Please try again or manually configure."
        exit 0
    fi
else
    echo "✅ All devices have unique serial numbers"
fi

# Update config.json with correct indices
update_config $DEVICE_COUNT

echo
echo "=== RTL-SDR Configuration Complete ==="
echo "Your RTL-SDR devices are now configured with unique index numbers"
echo "Device indices: 0 to $((DEVICE_COUNT-1))"
echo
echo "These indices are used in config.json for the 'device' parameter:"
echo "  \"device\": \"rtl=0\"  # First device"
if [ "$DEVICE_COUNT" -gt 1 ]; then
    echo "  \"device\": \"rtl=1\"  # Second device"
fi
if [ "$DEVICE_COUNT" -gt 2 ]; then
    echo "  \"device\": \"rtl=2\"  # Third device"
fi
echo

# Return success to continue with master-build.sh
exit 0