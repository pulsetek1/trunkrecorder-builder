#!/bin/bash

# Test script for RTL-SDR configuration
# This simulates the detection and configuration of RTL-SDR devices

echo "=== RTL-SDR Configuration Test ==="
echo

# Function to simulate RTL-SDR detection
simulate_rtl_test() {
    echo "Simulating rtl_test output..."
    echo "Found $1 device(s)"
    return 0
}

# Function to simulate rtl_eeprom
simulate_rtl_eeprom() {
    local device=$1
    local serial=$2
    
    echo "Simulating rtl_eeprom for device $device..."
    echo "Serial number: $serial"
    return 0
}

# Mock the real commands for testing
rtl_test() {
    simulate_rtl_test 3
}

rtl_eeprom() {
    if [[ "$*" == *"-d 0"* ]]; then
        simulate_rtl_eeprom 0 "00000001"
    elif [[ "$*" == *"-d 1"* ]]; then
        simulate_rtl_eeprom 1 "00000001" # Duplicate serial
    elif [[ "$*" == *"-d 2"* ]]; then
        simulate_rtl_eeprom 2 "00000003"
    fi
}

# Count connected RTL-SDR devices
count_devices() {
    echo "3" # Simulate 3 devices
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
        # Get serial for this device (simulated)
        if [ "$i" -eq 0 ]; then
            SERIAL="00000001"
        elif [ "$i" -eq 1 ]; then
            SERIAL="00000001" # Duplicate
        else
            SERIAL="00000003"
        fi
        
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

# Function to assign new serial numbers (simulated)
assign_serials() {
    echo "Assigning unique serial numbers to devices..."
    
    # Base serial prefix
    PREFIX="TRUNK"
    local device_count=$1
    
    # Assign for each device
    for i in $(seq 0 $((device_count-1))); do
        NEW_SERIAL="${PREFIX}00${i}"
        echo "Setting device $i serial to: $NEW_SERIAL"
        echo "✅ Device $i serial set successfully"
    done
    
    echo "Serial numbers assigned. Devices need to be unplugged and reconnected."
    echo "Please unplug all RTL-SDR devices, wait 5 seconds, then plug them back in."
    echo "[Simulated reconnection]"
}

# Function to update config.json with correct device indices
update_config() {
    echo "Updating config.json with correct device indices..."
    local device_count=$1
    
    echo "✅ Updated config.json with device indices 0 to $((device_count-1))"
}

# Main execution
echo "This script will test RTL-SDR device configuration"
echo

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
    
    # Verify serials are now unique (simulate success)
    echo "✅ All devices now have unique serial numbers"
else
    echo "✅ All devices have unique serial numbers"
fi

# Update config.json with correct indices
update_config $DEVICE_COUNT

echo
echo "=== RTL-SDR Configuration Test Complete ==="
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

exit 0