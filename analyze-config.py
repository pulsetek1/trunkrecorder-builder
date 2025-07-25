#!/usr/bin/env python3

import json

# Load current config
with open('config.json', 'r') as f:
    config = json.load(f)

print("=== Current Configuration Analysis ===\n")

# Extract data
sources = config['sources']
control_channels = config['systems'][0]['control_channels']

print(f"Control Channels: {len(control_channels)}")
for i, cc in enumerate(control_channels):
    print(f"  {i+1}. {cc:,} Hz ({cc/1000000:.3f} MHz)")

print(f"\nRTL-SDR Sources: {len(sources)}")
total_recorders = 0

for i, source in enumerate(sources):
    center = source['center']
    bandwidth = source['rate']
    recorders = source['digitalRecorders']
    total_recorders += recorders
    
    # Calculate frequency range this RTL-SDR covers
    lower = center - (bandwidth // 2)
    upper = center + (bandwidth // 2)
    
    # Count control channels in this range
    controls_in_range = [cc for cc in control_channels if lower <= cc <= upper]
    
    print(f"\n  RTL-SDR {i} (rtl={i}):")
    print(f"    Center: {center:,} Hz ({center/1000000:.3f} MHz)")
    print(f"    Range: {lower:,} - {upper:,} Hz ({lower/1000000:.3f} - {upper/1000000:.3f} MHz)")
    print(f"    Bandwidth: {bandwidth/1000000:.1f} MHz")
    print(f"    Digital Recorders: {recorders}")
    print(f"    Control Channels in range: {len(controls_in_range)}")
    for cc in controls_in_range:
        print(f"      - {cc:,} Hz ({cc/1000000:.3f} MHz)")

print(f"\nTotal Digital Recorders: {total_recorders}")

# Show the new calculation method
print("\n=== New Calculation Method ===")
print("Target: 22 total recorders distributed evenly")
print("Base per device: 22 ÷ 3 = 7 recorders each")
print("Remainder: 22 % 3 = 1 extra recorder")
print("Control channel bonus: +1-2 for devices with control channels")

print("\nRecommended distribution:")
for i, source in enumerate(sources):
    center = source['center']
    bandwidth = source['rate']
    lower = center - (bandwidth // 2)
    upper = center + (bandwidth // 2)
    controls_in_range = [cc for cc in control_channels if lower <= cc <= upper]
    
    # Apply new calculation
    base = 7  # 22 // 3
    if len(controls_in_range) > 0:
        recommended = base + min(2, len(controls_in_range))
    else:
        recommended = base
    
    # Add remainder to first device
    if i == 0:
        recommended += 1  # 22 % 3 = 1
    
    # Apply limits
    recommended = max(6, min(10, recommended))
    
    print(f"  RTL-SDR {i}: {recommended} recorders (was {source['digitalRecorders']})")
    print(f"    Base: 7, Control bonus: {min(2, len(controls_in_range))}, Remainder: {1 if i == 0 else 0}")