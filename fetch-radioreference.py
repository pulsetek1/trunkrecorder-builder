#!/usr/bin/env python3

"""
RadioReference Configuration Generator

This script fetches system data from RadioReference.com and generates configuration files
for trunk-recorder and related services. It handles:

- Authentication to RadioReference.com
- Fetching system information and talkgroup data
- Calculating RTL-SDR requirements
- Generating trunk-recorder config.json
- Creating talkgroup CSV files for various services
- Configuring upload services like Broadcastify, OpenMHz and RDIOScanner

Author: Amazon Q
"""

import requests
import csv
import json
import sys
import argparse
from bs4 import BeautifulSoup

def calculate_recorders(device_index, center_freq, bandwidth, all_frequencies, control_channels, total_devices=3):
    """
    Calculate the optimal number of digital recorders for each RTL-SDR device based on
    the frequencies it can receive and the number of control channels in its range.
    
    The number of digital recorders determines how many simultaneous calls can be
    recorded at the same time in the frequency range of this source.
    
    Args:
        device_index (int): Index of the current device
        center_freq (int): Center frequency of this RTL-SDR device in Hz
        bandwidth (int): Bandwidth of the RTL-SDR device in Hz
        all_frequencies (list): All frequencies in the system in Hz
        control_channels (list): Control channel frequencies in Hz
        total_devices (int): Total number of RTL-SDR devices
        
    Returns:
        int: Number of digital recorders to allocate to this device
    """
    # Calculate the frequency range this device can receive
    lower_limit = center_freq - (bandwidth // 2)
    upper_limit = center_freq + (bandwidth // 2)
    
    # Count frequencies and control channels in this device's range
    freqs_in_range = [f for f in all_frequencies if lower_limit <= f <= upper_limit]
    controls_in_range = [f for f in control_channels if lower_limit <= f <= upper_limit]
    
    # Base number of recorders on frequencies in range
    freq_count = len(freqs_in_range)
    control_count = len(controls_in_range)
    
    # Calculate total recorders needed (aim for 36 total across all devices)
    total_recorders = 36
    base_per_device = total_recorders // total_devices
    remainder = total_recorders % total_devices
    
    # Distribute evenly with slight adjustment for control channels
    if control_count > 0:
        # Device has control channels - gets base + small bonus
        recorders = base_per_device + min(2, control_count)
    else:
        # No control channels - gets base allocation
        recorders = base_per_device
    
    # Distribute remainder to later devices
    if device_index < remainder:
        recorders += 1
    
    # Ensure reasonable limits (minimum 6, maximum 10)
    return max(6, min(10, recorders))

def login_radioreference(username, password):
    """
    Authenticate with RadioReference.com and establish a session
    
    Args:
        username (str): RadioReference.com username
        password (str): RadioReference.com password
        
    Returns:
        requests.Session: Authenticated session object if successful, None if failed
    """
    session = requests.Session()
    session.headers.update({
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
    })
    
    try:
        # Use the working login data
        login_data = {
            'username': username,
            'password': password,
            'action': 'auth',
            'redirect': 'https://www.radioreference.com'
        }
        
        # Submit login to the correct endpoint
        response = session.post('https://www.radioreference.com/login/', data=login_data, allow_redirects=True)
        
        # Check if login was successful by looking for logged-in indicators
        if "logout" in response.text.lower() or "sign out" in response.text.lower() or "my account" in response.text.lower():
            print("✓ Successfully logged into RadioReference.com")
            return session
        else:
            print("✗ Failed to login to RadioReference.com")
            print("   Check your username and password")
            return None
            
    except Exception as e:
        print(f"✗ Login error: {str(e)}")
        return None

def get_system_info(session, sid):
    """
    Fetch basic system information from RadioReference.com
    
    Args:
        session (requests.Session): Authenticated session
        sid (int): System ID number
        
    Returns:
        dict: System information including name, location and ID if found, None if not found
    """
    site_url = f"https://www.radioreference.com/db/sid/{sid}"
    response = session.get(site_url)
    
    if response.status_code != 200:
        return None
    
    soup = BeautifulSoup(response.content, 'html.parser')
    
    # Try to find system name from page title
    title = soup.find('title')
    system_name = "Unknown System"
    
    if title:
        title_text = title.text.strip()
        if 'Trunked Radio System' in title_text:
            system_name = title_text.replace('Trunked Radio System', '').strip()
        elif 'Radio System' in title_text:
            system_name = title_text.replace('Radio System', '').strip()
    
    # Try to find location/county info in page text
    location = "Unknown Location"
    for text in soup.find_all(string=True):
        if 'County' in str(text) and len(str(text).strip()) < 50:
            location = str(text).strip()
            break
    
    return {
        'name': system_name,
        'location': location,
        'sid': sid
    }

def fetch_system_data(session, sid, siteid=None):
    """
    Download and parse system data including talkgroups and site information
    
    Args:
        session (requests.Session): Authenticated session
        sid (int): System ID number
        siteid (str, optional): Specific site ID to use
        
    Returns:
        tuple: (talkgroups list, system_info dict) if successful, (None, None) if failed
    """
    
    # Download talkgroups CSV
    tg_csv_url = f"https://www.radioreference.com/db/download/trs/tgs/?type=csv&sid={sid}"
    response = session.get(tg_csv_url)
    
    if response.status_code != 200:
        print(f"✗ Failed to download talkgroups CSV for SID {sid}")
        return None, None
    
    # Parse talkgroups CSV
    talkgroups = []
    lines = response.text.strip().split('\n')
    
    if len(lines) > 1:  # Skip header
        reader = csv.reader(lines[1:])  # Skip header row
        for row in reader:
            if len(row) >= 4:
                dec_id = row[0].strip()
                hex_id = row[1].strip() if len(row) > 1 else ''
                alpha_tag = row[2].strip() if len(row) > 2 else ''
                description = row[3].strip() if len(row) > 3 else ''
                
                if dec_id.isdigit():
                    talkgroups.append([dec_id, hex_id, alpha_tag, 'T', description, 'Fire/EMS', 'Fire/EMS'])
    
    # Download sites CSV
    sites_csv_url = f"https://www.radioreference.com/db/download/trs/sites/?type=csv&sid={sid}"
    response = session.get(sites_csv_url)
    
    if response.status_code != 200:
        print(f"✗ Failed to download sites CSV for SID {sid}")
        return talkgroups, None
    
    # Parse sites CSV and let user select site
    lines = response.text.strip().split('\n')
    sites = []
    
    if len(lines) > 1:  # Skip header
        reader = csv.reader(lines[1:])  # Skip header row
        for row in reader:
            if len(row) >= 10:  # Ensure we have enough columns
                site_dec = row[1].strip() if len(row) > 1 else ''
                site_desc = row[2].strip() if len(row) > 2 else 'Unknown Site'
                site_nac = row[3].strip() if len(row) > 3 else ''
                
                if site_dec:
                    sites.append({
                        'dec': site_dec,
                        'description': site_desc,
                        'nac': site_nac,
                        'row': row
                    })
    
    if not sites:
        print(f"✗ No sites found for SID {sid}")
        return talkgroups, None
    
    # Let user select site if multiple available (or use provided siteid)
    selected_site = None
    
    if siteid:
        # Use provided site ID (for automated updates)
        for site in sites:
            if site['dec'] == siteid:
                selected_site = site
                print(f"Using specified site: {selected_site['description']} (ID: {selected_site['dec']})")
                break
        if not selected_site:
            print(f"✗ Site ID {siteid} not found, using first available site")
            selected_site = sites[0]
    elif len(sites) == 1:
        selected_site = sites[0]
        print(f"Using site: {selected_site['description']} (ID: {selected_site['dec']})")
    else:
        print(f"\n📍 Multiple sites found:")
        print(f"{'#':<3} {'ID':<6} {'Description':<30} {'NAC':<6} {'Additional Info':<50}")
        print("-" * 95)
        for i, site in enumerate(sites):
            # Get additional info from remaining columns
            row = site['row']
            additional_info = ' | '.join([col.strip() for col in row[4:9] if col.strip()])
            if len(additional_info) > 47:
                additional_info = additional_info[:47] + "..."
            
            print(f"{i+1:<3} {site['dec']:<6} {site['description']:<30} {site['nac']:<6} {additional_info:<50}")
        
        while True:
            try:
                choice = int(input(f"\nSelect site (1-{len(sites)}): ")) - 1
                if 0 <= choice < len(sites):
                    selected_site = sites[choice]
                    break
                else:
                    print(f"Please enter a number between 1 and {len(sites)}")
            except ValueError:
                print("Please enter a valid number")
    
    # Process selected site
    system_info = {
        'sid': sid,
        'control_channels': [],
        'frequencies': [],
        'nac': None,
        'name': None,
        'siteid': selected_site['dec']
    }
    
    # Extract NAC (Network Access Code)
    if selected_site['nac']:
        system_info['nac'] = f"0x{selected_site['nac']}"
    
    # Extract frequencies from selected site row
    row = selected_site['row']
    for i in range(9, len(row)):
        freq_text = row[i].strip()
        if freq_text and '.' in freq_text:
            try:
                if freq_text.endswith('c'):  # Control channel
                    freq = freq_text.replace('c', '')
                    freq_hz = int(float(freq) * 1000000)
                    system_info['control_channels'].append(freq_hz)
                    system_info['frequencies'].append(freq_hz)
                else:  # Regular frequency
                    freq_hz = int(float(freq_text) * 1000000)
                    system_info['frequencies'].append(freq_hz)
            except:
                pass
    
    return talkgroups, system_info

def generate_config(system_info, shortname="system", upload_config=None):
    """
    Generate trunk-recorder config.json structure
    
    Args:
        system_info (dict): System information including frequencies
        shortname (str): Short name identifier for the system
        upload_config (dict): Upload service configuration settings
        
    Returns:
        dict: Complete config.json structure if successful, None if failed
    """
    
    if not system_info['frequencies']:
        print("✗ No frequencies found")
        return None
    
    # Calculate optimal RTL-SDR center frequencies
    freqs = sorted(system_info['frequencies'])
    min_freq = min(freqs)
    max_freq = max(freqs)
    span = max_freq - min_freq
    
    # Calculate number of sources needed (2.4MHz bandwidth per RTL-SDR)
    num_sources = max(1, int((span / 2400000) + 1))
    
    sources = []
    bandwidth = 2400000  # 2.4 MHz bandwidth
    
    # First calculate all center frequencies
    centers = []
    for i in range(num_sources):
        center = min_freq + (span * (i + 0.5) / num_sources)
        centers.append(int(center))
    
    # Then create sources with calculated recorders
    for i in range(num_sources):
        center = centers[i]
        sources.append({
            "center": center,
            "rate": bandwidth,
            "ppm": 0,
            "gain": 49,
            "agc": False,
            "digitalRecorders": calculate_recorders(i, center, bandwidth, freqs, system_info['control_channels'], num_sources),
            "analogRecorders": 0,
            "driver": "osmosdr",
            "device": f"rtl={i}"
        })
    
    # Base config structure
    config = {
        "ver": 2,
        "sources": sources,
        "systems": [{
            "control_channels": system_info['control_channels'],
            "type": "p25",
            "digitalLevels": 1,
            "talkgroupsFile": "/etc/trunk-recorder/talkgroup.csv",
            "shortName": shortname,
            "modulation": "qpsk",
            "hideEncrypted": False,
            "talkgroupDisplayFormat": "id_tag",
            "compressWav": True
        }],
        "captureDir": "/trunkrecorder/recordings",
        "logLevel": "info",
        "broadcastSignals": True,
        "frequencyFormat": "mhz",
        "logFile": True,
        "logDir": "/trunkrecorder/logs",
        "callTimeout": 120,
        "transmissionTimeout": 30,
        "audioFormat": "wav",
        "removeRecording": True
    }
    
    # Add NAC if available
    if system_info['nac']:
        # Convert hex string to integer
        nac_str = system_info['nac']
        if nac_str.startswith('0x'):
            config['systems'][0]['nac'] = int(nac_str, 16)
        else:
            config['systems'][0]['nac'] = int(nac_str, 16)
    
    # Add upload service configurations
    if upload_config:
        plugins = []
        
        # Broadcastify configuration
        if upload_config['broadcastify']['enabled']:
            config['broadcastifyCallsServer'] = "https://api.broadcastify.com/call-upload"
            config['systems'][0]['broadcastifyApiKey'] = upload_config['broadcastify']['api_key']
            config['systems'][0]['broadcastifySystemId'] = upload_config['broadcastify']['system_id']
        
        # OpenMHz configuration
        if upload_config['openmhz']['enabled']:
            config['uploadServer'] = "https://api.openmhz.com"
            config['systems'][0]['apiKey'] = upload_config['openmhz']['api_key']
        
        # RDIOScanner configuration
        if upload_config['rdio']['enabled']:
            plugins.append({
                "name": "rdioscanner_uploader",
                "library": "librdioscanner_uploader.so",
                "server": upload_config['rdio']['server'],
                "systems": [{
                    "shortName": upload_config['rdio']['shortname'],
                    "apiKey": upload_config['rdio']['api_key'],
                    "systemId": upload_config['rdio']['system_id']
                }]
            })
        
        if plugins:
            config['plugins'] = plugins
    
    return config

def load_existing_config():
    """
    Load existing config.json if present (for upload service defaults)
    
    Returns:
        dict: Existing configuration if found, None if not found
    """
    # Try system config first, then local config
    config_paths = ['/etc/trunk-recorder/config.json', 'config.json']
    
    for config_path in config_paths:
        try:
            with open(config_path, 'r') as f:
                return json.load(f)
        except:
            continue
    return None

def get_upload_config(system_shortname=None):
    """
    Get upload service configuration from user with existing values as defaults
    
    Args:
        system_shortname (str): System shortname to use as default for RDIOScanner
    
    Returns:
        dict: Upload service configuration settings
    """
    existing_config = load_existing_config()
    
    upload_config = {
        'broadcastify': {'enabled': False},
        'openmhz': {'enabled': False},
        'rdio': {'enabled': False}
    }
    
    # Extract existing values from current config if present
    existing_broadcastify_key = ''
    existing_broadcastify_id = ''
    existing_openmhz_key = ''
    existing_rdio_server = ''
    existing_rdio_key = ''
    existing_rdio_shortname = ''
    existing_rdio_system_id = ''
    
    if existing_config:
        if 'systems' in existing_config and len(existing_config['systems']) > 0:
            sys_config = existing_config['systems'][0]
            existing_broadcastify_key = sys_config.get('broadcastifyApiKey', '')
            existing_broadcastify_id = str(sys_config.get('broadcastifySystemId', ''))
            existing_openmhz_key = sys_config.get('apiKey', '')
        
        if 'plugins' in existing_config:
            for plugin in existing_config['plugins']:
                if plugin.get('name') == 'rdioscanner_uploader':
                    existing_rdio_server = plugin.get('server', '')
                    if 'systems' in plugin and len(plugin['systems']) > 0:
                        existing_rdio_key = plugin['systems'][0].get('apiKey', '')
                        existing_rdio_shortname = plugin['systems'][0].get('shortName', '')
                        existing_rdio_system_id = str(plugin['systems'][0].get('systemId', ''))
    
    # Configure Broadcastify
    while True:
        broadcastify_choice = input("\nUse Broadcastify upload? (y/n): ").lower().strip()
        if broadcastify_choice in ['y', 'yes', 'n', 'no']:
            break
        print("Please enter 'y' or 'n'")
    
    if broadcastify_choice.startswith('y'):
        upload_config['broadcastify']['enabled'] = True
        
        if existing_broadcastify_key:
            key_input = input(f"Broadcastify API Key [{existing_broadcastify_key}]: ").strip()
            upload_config['broadcastify']['api_key'] = key_input if key_input else existing_broadcastify_key
        else:
            upload_config['broadcastify']['api_key'] = input("Broadcastify API Key: ")
        
        if existing_broadcastify_id:
            id_input = input(f"Broadcastify System ID [{existing_broadcastify_id}]: ").strip()
            id_value = id_input if id_input else existing_broadcastify_id
        else:
            id_value = input("Broadcastify System ID: ")
        
        try:
            upload_config['broadcastify']['system_id'] = int(id_value)
        except ValueError:
            print("   Error: Broadcastify System ID must be a number")
            upload_config['broadcastify']['enabled'] = False
    
    # Configure OpenMHz
    while True:
        openmhz_choice = input("\nUse OpenMHz upload? (y/n): ").lower().strip()
        if openmhz_choice in ['y', 'yes', 'n', 'no']:
            break
        print("Please enter 'y' or 'n'")
    
    if openmhz_choice.startswith('y'):
        upload_config['openmhz']['enabled'] = True
        
        if existing_openmhz_key:
            key_input = input(f"OpenMHz API Key [{existing_openmhz_key}]: ").strip()
            upload_config['openmhz']['api_key'] = key_input if key_input else existing_openmhz_key
        else:
            upload_config['openmhz']['api_key'] = input("OpenMHz API Key: ")
    
    # Configure RDIOScanner
    while True:
        rdio_choice = input("\nUse RDIOScanner upload? (y/n): ").lower().strip()
        if rdio_choice in ['y', 'yes', 'n', 'no']:
            break
        print("Please enter 'y' or 'n'")
    
    if rdio_choice.startswith('y'):
        upload_config['rdio']['enabled'] = True
        
        if existing_rdio_server:
            server_input = input(f"RDIOScanner Server URL [{existing_rdio_server}]: ").strip()
            upload_config['rdio']['server'] = server_input if server_input else existing_rdio_server
        else:
            upload_config['rdio']['server'] = input("RDIOScanner Server URL: ")
        
        if existing_rdio_key:
            key_input = input(f"RDIOScanner API Key [{existing_rdio_key}]: ").strip()
            upload_config['rdio']['api_key'] = key_input if key_input else existing_rdio_key
        else:
            upload_config['rdio']['api_key'] = input("RDIOScanner API Key: ")
        
        # Use system shortname as default if no existing config
        default_shortname = existing_rdio_shortname or system_shortname or 'system'
        name_input = input(f"System short name for RDIOScanner [{default_shortname}]: ").strip()
        upload_config['rdio']['shortname'] = name_input if name_input else default_shortname
        
        # Get system ID for RDIOScanner
        if existing_rdio_system_id:
            system_id_input = input(f"RDIOScanner System ID [{existing_rdio_system_id}]: ").strip()
            id_value = system_id_input if system_id_input else existing_rdio_system_id
        else:
            id_value = input("RDIOScanner System ID (numeric): ").strip()
        
        try:
            upload_config['rdio']['system_id'] = int(id_value)
        except ValueError:
            print("   Error: System ID must be a number, using default 1")
            upload_config['rdio']['system_id'] = 1
    
    return upload_config

def main():
    """
    Main execution function
    
    Handles command line arguments and orchestrates the configuration generation process
    """
    parser = argparse.ArgumentParser(description='Fetch RadioReference data and generate Trunk Recorder config')
    parser.add_argument('username', help='RadioReference.com username')
    parser.add_argument('password', help='RadioReference.com password')
    parser.add_argument('sid', type=int, help='System ID (from URL like /db/sid/12059)')
    parser.add_argument('--shortname', default='system', help='Short name for system')
    parser.add_argument('--abbrev', default='SYSTEM', help='System abbreviation for categories')
    parser.add_argument('--siteid', help='Specific site ID to use (for automated updates)')
    parser.add_argument('--update-only', action='store_true', help='Only update talkgroups, skip configuration prompts')
    parser.add_argument('--capture-siteid', action='store_true', help='Save selected siteid to file for future updates')
    
    args = parser.parse_args()
    
    print(f"Fetching data for SID {args.sid}...")
    
    # Login to RadioReference
    session = login_radioreference(args.username, args.password)
    if not session:
        sys.exit(1)
    
    # Get basic system info for verification
    print(f"\nLooking up system information for SID {args.sid}...")
    basic_info = get_system_info(session, args.sid)
    
    if not basic_info:
        print(f"✗ Could not find system with SID {args.sid}")
        sys.exit(1)
    
    print(f"\n📡 System Found:")
    print(f"   Name: {basic_info['name']}")
    print(f"   Location: {basic_info['location']}")
    print(f"   SID: {basic_info['sid']}")
    
    if not args.update_only:
        confirm = input(f"\nIs this the correct system? (y/n): ")
        if not confirm.lower().startswith('y'):
            print("Aborted by user")
            sys.exit(0)
    else:
        print(f"\n✓ Updating system: {basic_info['name']}")
    
    # Fetch detailed system data to calculate RTL-SDR requirements
    if not args.update_only:
        print(f"\nAnalyzing frequency requirements...")
    else:
        print(f"\nFetching talkgroup data...")
        
    talkgroups, system_info = fetch_system_data(session, args.sid, args.siteid)
    
    if not args.update_only and system_info and system_info['frequencies']:
        freqs = sorted(system_info['frequencies'])
        min_freq = min(freqs) / 1000000
        max_freq = max(freqs) / 1000000
        span = max_freq - min_freq
        
        # Calculate RTL-SDR requirements (2.4MHz bandwidth each)
        rtl_needed = max(1, int((span / 2.4) + 1))
        
        print(f"\n📻 RTL-SDR Requirements:")
        print(f"   Frequency range: {min_freq:.3f} - {max_freq:.3f} MHz")
        print(f"   Total span: {span:.3f} MHz")
        print(f"   RTL-SDR dongles needed: {rtl_needed}")
        print(f"   (Each RTL-SDR covers ~2.4 MHz bandwidth)")
        print(f"\n⚠️  Make sure you have {rtl_needed} RTL-SDR dongles connected before deployment.")
    
    # Get upload service configuration (skip if update-only)
    if args.update_only:
        upload_config = None
        print("\nSkipping upload service configuration (update-only mode)")
    else:
        input("\nPress Enter to continue with configuration...")
        upload_config = get_upload_config(args.shortname)
    
    # System data already fetched above
    if not args.update_only:
        print(f"\nProcessing data for {basic_info['name']}...")
    else:
        print(f"\nProcessing talkgroup data for {basic_info['name']}...")
    
    if not talkgroups:
        print("✗ No talkgroups found")
        sys.exit(1)
    
    if not args.update_only and not system_info:
        print("✗ No system info found")
        sys.exit(1)
    
    # Get raw RadioReference CSV for saving
    tg_csv_url = f"https://www.radioreference.com/db/download/trs/tgs/?type=csv&sid={args.sid}"
    tg_response = session.get(tg_csv_url)
    
    if tg_response.status_code == 200:
        lines = tg_response.text.strip().split('\n')
        
        # Process CSV to append system abbreviation to category
        def process_csv_with_system_abbrev(filename, truncate_desc=False):
            with open(filename, 'w', newline='') as f:
                writer = csv.writer(f)
                
                for i, line in enumerate(lines):
                    row = list(csv.reader([line]))[0]  # Parse each line individually
                    
                    if i == 0:  # Header row
                        writer.writerow(row)
                    else:  # Data rows
                        if len(row) >= 7:  # Ensure we have category column (index 6)
                            # Prepend system abbreviation to category (column 6)
                            if row[6].strip():
                                row[6] = f"{args.abbrev.upper()} - {row[6]}"
                            else:
                                row[6] = args.abbrev.upper()
                        
                        if truncate_desc and len(row) >= 5:  # Truncate description for OpenMHz
                            row[4] = row[4][:25] if len(row[4]) > 25 else row[4]
                        
                        writer.writerow(row)
        
        # Generate all three CSV files with system abbreviation appended to category
        process_csv_with_system_abbrev('talkgroup.csv')
        if not args.update_only:  # Only generate additional formats during full deployment
            process_csv_with_system_abbrev('talkgroup-rdio.csv')
            process_csv_with_system_abbrev('talkgroup-openmhz.csv', truncate_desc=True)
    
    print(f"✓ Found {len(talkgroups)} talkgroups")
    
    if args.update_only:
        print("✓ Talkgroup update completed successfully")
    
    # Save siteid for future updates if requested
    if args.capture_siteid and system_info:
        with open('siteid.txt', 'w') as f:
            f.write(system_info['siteid'])
        print(f"✓ Site ID {system_info['siteid']} saved for future updates")
    
    # Generate config.json (skip if update-only)
    if not args.update_only:
        config = generate_config(system_info, args.shortname, upload_config)
        if config:
            print(f"✓ Found {len(system_info['control_channels'])} control channels")
            print(f"✓ Found {len(system_info['frequencies'])} total frequencies")
            print(f"✓ Generated {len(config['sources'])} RTL-SDR sources")
            
            with open('config.json', 'w') as f:
                json.dump(config, f, indent=2)
            
            print("\n✓ Files generated:")
            print("  - config.json")
            print("  - talkgroup.csv (full descriptions)")
            print("  - talkgroup-openmhz.csv (25-char descriptions)")
            print("  - talkgroup-rdio.csv (original RadioReference format)")
            print("\n📋 Note: talkgroup-rdio.csv can be imported into RDIOScanner admin site")
            
            if not any(upload_config[svc]['enabled'] for svc in upload_config):
                print("\n⚠ No upload services configured - recordings will be local only")
            else:
                print("\n✓ Upload services configured successfully!")
        else:
            print("✗ Failed to generate config")
            sys.exit(1)
    else:
        print("\n✓ Talkgroup files updated:")
        print("  - talkgroup.csv (full descriptions)")
        print("  - talkgroup-openmhz.csv (25-char descriptions)")
        print("  - talkgroup-rdio.csv (original RadioReference format)")

if __name__ == "__main__":
    main()
