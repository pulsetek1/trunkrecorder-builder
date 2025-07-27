#!/bin/bash

# RTL-SDR v4 Gain Calibration Test Script
# Tests optimal gain settings for each RTL device using control channels from siteinfo.json

echo "🔧 RTL-SDR v4 Gain Calibration Test"
echo "=================================="

# Stop trunk-recorder to release USB devices
echo "Stopping trunk-recorder service..."
sudo systemctl stop trunk-recorder
sleep 2

# Load control channels from siteinfo.json
SITEINFO="/etc/trunk-recorder/siteinfo.json"
if [[ ! -f "$SITEINFO" ]]; then
    echo "❌ siteinfo.json not found at $SITEINFO"
    exit 1
fi

# Extract control channels (use strongest ones for testing)
CONTROL_CHANNELS=($(jq -r '.control_channels[]' "$SITEINFO" 2>/dev/null))
if [[ ${#CONTROL_CHANNELS[@]} -eq 0 ]]; then
    echo "❌ No control channels found in siteinfo.json"
    exit 1
fi

echo "Found ${#CONTROL_CHANNELS[@]} control channels: ${CONTROL_CHANNELS[@]}"

# Use control channels for testing (they're the strongest signals)
RTL0_FREQ="${CONTROL_CHANNELS[0]}"  # First control channel
RTL1_FREQ="${CONTROL_CHANNELS[1]:-${CONTROL_CHANNELS[0]}}"  # Second or fallback to first
RTL2_FREQ="${CONTROL_CHANNELS[-1]}"  # Last control channel (usually strongest)

# Gain levels to test
GAINS=(20 25 30 35 40 45)

test_gain() {
    local device=$1
    local freq_hz=$2
    local gain=$3
    
    # Convert Hz to MHz and create frequency range (±1kHz)
    local freq_mhz=$(echo "scale=6; $freq_hz/1000000" | bc)
    local freq_low=$(echo "scale=6; $freq_mhz - 0.001" | bc)
    local freq_high=$(echo "scale=6; $freq_mhz + 0.001" | bc)
    local freq_range="${freq_low}M:${freq_high}M:1k"
    
    # Run rtl_power with correct frequency range format
    rtl_power -f $freq_range -g $gain -i 1 -d $device -1 2>/dev/null | \
    awk 'NF>=7 && $7~/^-?[0-9]/ {print $7; exit}' | head -1 | awk '{if(NF>0) printf "%.2f", $1; else print "-999"}'
}

calibrate_device() {
    local device=$1
    local freq=$2
    local freq_mhz=$(echo "scale=3; $freq/1000000" | bc)
    
    echo ""
    echo "📡 Calibrating RTL=$device (${freq_mhz} MHz)"
    echo "----------------------------------------"
    
    best_gain=20
    best_power=-999
    
    for gain in "${GAINS[@]}"; do
        power=$(test_gain $device $freq $gain)
        
        if [[ $power != "-999" ]] && [[ $power =~ ^-?[0-9]+\.?[0-9]*$ ]]; then
            printf "Gain %2ddB: %6.2f dBm\n" $gain $power
            
            # Check for improvement (higher is better, but watch for saturation)
            if (( $(echo "$power > $best_power" | bc -l) )); then
                # Check if power increase is reasonable (not saturated)
                if [[ $best_power == "-999" ]]; then
                    # First valid reading
                    best_gain=$gain
                    best_power=$power
                else
                    power_diff=$(echo "$power - $best_power" | bc)
                    if (( $(echo "$power_diff < 15" | bc -l) )); then  # Avoid saturation jumps
                        best_gain=$gain
                        best_power=$power
                    fi
                fi
            fi
        else
            echo "Gain ${gain}dB: ERROR - device busy or not found"
        fi
    done
    
    echo "✓ Optimal gain for RTL=$device: ${best_gain}dB (${best_power} dBm power)"
    echo "RTL${device}_OPTIMAL_GAIN=${best_gain}" >> gain_results.txt
}

# Check if RTL devices are available
echo "Checking RTL-SDR devices..."
if ! rtl_test -d 0 -t 2>&1 | grep -q "Found.*device"; then
    echo "❌ No RTL-SDR devices found. Make sure devices are connected."
    exit 1
fi
echo "✓ RTL-SDR devices detected"

# Initialize results file
echo "# RTL-SDR Gain Calibration Results" > gain_results.txt
echo "# Generated: $(date)" >> gain_results.txt

# Test each device
calibrate_device 0 $RTL0_FREQ
calibrate_device 1 $RTL1_FREQ  
calibrate_device 2 $RTL2_FREQ

echo ""
echo "🎯 Calibration Complete!"
echo "======================="
echo "Results saved to: gain_results.txt"
echo ""
cat gain_results.txt

echo ""
echo "Restarting trunk-recorder service..."
sudo systemctl start trunk-recorder
echo "✓ Service restarted"