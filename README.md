# 📡 Trunk Recorder Master Build System

A complete automated deployment system for P25 trunked radio monitoring using Trunk Recorder with RadioReference.com integration.

## 🔍 Overview

This system is a comprehensive one-command deployment solution for P25 trunked radio monitoring that completely automates the setup of a Raspberry Pi with RTL-SDR devices. Here's what it does:

The system automatically connects to RadioReference.com using your login credentials, downloads live talkgroup data and system configuration for any P25 radio system (you just provide the System ID from the RadioReference URL), then intelligently calculates RTL-SDR requirements by analyzing the frequency span and automatically configures 1-3 RTL-SDR dongles with optimal center frequencies. It analyzes your operating system and hardware to provide tailored installation recommendations including Docker, native Linux packages, or source compilation. The system generates a complete Trunk Recorder configuration, sets up multiple upload services (Broadcastify, OpenMHz, RDIOScanner), installs all dependencies, compiles Trunk Recorder from source, creates systemd services for automatic startup, and establishes nightly automatic updates that refresh talkgroup data from RadioReference to keep everything current.

The entire process requires just running sudo ./master-build.sh, entering your RadioReference credentials and system ID, and the system analyzes your platform to recommend the best installation approach - whether that's Docker for simplicity, native packages for speed, or source compilation for latest features. It handles everything else - from hardware detection and driver configuration to service management and log rotation. It's designed for production deployment with security hardening, automatic cleanup of old recordings, and comprehensive monitoring capabilities.

## ✨ Features

- 🔗 **Automated RadioReference Integration**: Live data fetching with login authentication
- 🏢 **Multi-Site Support**: Handles systems with multiple sites/towers
- 📤 **Upload Service Integration**: Broadcastify, OpenMHz, and RDIOScanner support
- 🌙 **Nightly Updates**: Automatic talkgroup updates from RadioReference
- 📻 **RTL-SDR Management**: Automatic device configuration with unique index numbers
- 🔧 **Hardware Management**: RTL-SDR configuration and testing
- ⏰ **Time Synchronization**: Chrony NTP for accurate timestamps
- ⚙️ **Service Management**: Complete systemd integration
- 🔍 **Smart OS Detection**: Analyzes your system and recommends optimal installation method
- 🐳 **Multi-Platform Support**: Docker, Linux native, Raspberry Pi OS, and macOS guidance

## 🖥️ Hardware Requirements

- 🥧 **Raspberry Pi 4** (4GB+ RAM recommended) or compatible ARM64/x86_64 system
- 📻 **RTL-SDR Dongles**: 1-3 dongles depending on frequency span
- 🌐 **Network Connection**: For RadioReference access and uploads
- 💾 **Storage**: 32GB+ SD card (recordings stored in RAM for SD protection)

## 💻 Software Requirements

- 🐧 **Ubuntu 24.04 LTS** (ARM64 or x86_64)
- 🔐 **Root Access**: Installation requires sudo privileges
- 👤 **RadioReference Account**: Premium account for CSV downloads

## 🚀 Quick Start

1. 📥 **Clone Repository**:
   ```bash
   git clone https://github.com/pulsetek1/trunkrecorder-builder.git
   cd trunkrecorder-builder
   ```

2. ⚡ **Run Master Build**:
   ```bash
   sudo ./master-build.sh
   ```

3. 📝 **Follow Prompts**:
   - RadioReference username/password
   - System ID (from RadioReference URL)
   - System short name
   - Site selection (if multiple sites)
   - System analysis and installation method selection
   - Upload service configuration

## 🔍 Installation Options

The system automatically detects your platform and provides tailored recommendations:

### 🐳 **Docker Installation** (Recommended)
- ✅ Works on all platforms
- ✅ Isolated environment
- ✅ Easy updates and management
- ✅ No dependency conflicts

### 🐧 **Linux Native Installation**
- ✅ Best performance
- ✅ Distribution-specific packages
- ✅ Supports Ubuntu, Debian, Fedora, CentOS, Arch, openSUSE
- ⚠️ Longer installation time

### 🥧 **Raspberry Pi OS**
- ✅ Optimized for Pi hardware
- ✅ Performance tuning included
- ✅ Thermal management guidance
- ⚠️ Requires adequate cooling

### 🍎 **macOS Support**
- ✅ Homebrew-based installation
- ✅ Complete dependency management
- 📚 Manual installation guide provided

## 📋 Detailed Installation

### 🔧 Step 1: System Preparation

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Clone repository
git clone https://github.com/pulsetek1/trunkrecorder-builder.git
cd trunkrecorder-builder
chmod +x *.sh
```

### 📡 Step 2: RadioReference Setup

1. 👤 **Create RadioReference Account**: Visit https://www.radioreference.com
2. 🔍 **Find System ID**: Navigate to your system page, note the SID from URL
3. ✅ **Verify Premium Access**: Ensure you can download CSV files

### ⚡ Step 3: Run Installation

```bash
sudo ./master-build.sh
```

**Installation Process**:
1. **System Analysis**: Detects OS, architecture, memory, and available tools
2. **RadioReference Login**: Enter your credentials and system ID
3. **Site Selection**: Choose specific site if multiple available
4. **Installation Method**: System recommends optimal approach:
   - Docker (easiest, works everywhere)
   - Native packages (fastest)
   - Source compilation (latest features)
5. **Configuration**: Automatic setup of services and monitoring

### 📻 Step 4: RTL-SDR Device Configuration

The system automatically configures your RTL-SDR devices with unique index numbers:

1. **Device Detection**: Identifies all connected RTL-SDR dongles
2. **Serial Number Check**: Verifies each device has a unique serial number
3. **Automatic Assignment**: Sets unique serials using rtl_eeprom if needed
4. **Config Integration**: Updates config.json with correct device indices

```bash
# Manual RTL-SDR configuration (if needed):
sudo ./configure-rtlsdr.sh
```

> **Note**: After serial number assignment, devices need to be unplugged and reconnected.

### 📤 Step 5: Upload Service Configuration (Optional)

📻 **Broadcastify**:
- 🔑 API Key: From your Broadcastify account
- 🆔 System ID: Numeric ID for your system on Broadcastify

🌐 **OpenMHz**:
- 🔑 API Key: From your OpenMHz account

📊 **RDIOScanner**:
- 🌐 Server URL: Your RDIOScanner server address
- 🔑 API Key: From your RDIOScanner account
- 📝 Short Name: System identifier for RDIOScanner

## 📁 File Structure

```
/opt/trunk-recorder/
├── trunk-recorder              # Main executable
├── fetch-radioreference.py     # Data fetching script
└── plugins/                    # Upload plugins

/etc/trunk-recorder/
├── config.json                 # Main configuration
├── talkgroup.csv              # Talkgroup definitions
├── deployment-settings.json   # Stored deployment settings
└── radioreference-creds       # Encrypted credentials

/trunkrecorder/                # RAM Drive (tmpfs - 1GB)
├── recordings/                # Audio recordings (RAM)
└── logs/                      # Log files (RAM)

/var/lib/trunk-recorder/       # Legacy location (unused)
```

## ⚙️ Configuration Files

### 📄 config.json
Main Trunk Recorder configuration with:
- RTL-SDR source definitions
- P25 system parameters
- Upload service credentials
- Recording settings

### 📊 talkgroup.csv
Talkgroup definitions with:
- Decimal/Hex IDs
- Alpha tags
- Descriptions
- Categories

### 🔄 Generated Files
- `talkgroup-openmhz.csv`: OpenMHz compatible (25-char descriptions)
- `talkgroup-rdio.csv`: RDIOScanner import format

## 🔧 Service Management

### 📡 Trunk Recorder Service
```bash
# Start/stop service
sudo systemctl start trunk-recorder
sudo systemctl stop trunk-recorder

# Check status
sudo systemctl status trunk-recorder

# View logs
sudo journalctl -u trunk-recorder -f
```

### 🌙 Nightly Update Service
```bash
# Check update timer
sudo systemctl status talkgroup-update.timer

# Manual update
sudo /usr/local/bin/update-talkgroups.sh

# View update logs
sudo tail -f /var/log/trunkrecorder/$(date +%Y%m%d)_update.log
```

## 📊 Monitoring and Maintenance

### 🏥 System Health Checks

1. ✅ **Service Status**:
   ```bash
   sudo systemctl status trunk-recorder
   ```

2. 📻 **RTL-SDR Detection**:
   ```bash
   rtl_test -t
   ```

3. 🎵 **Recording Activity**:
   ```bash
   ls -la /trunkrecorder/recordings/
   ```

4. 📤 **Upload Status**: Check logs for upload confirmations/errors

### 📝 Log Locations

- 📄 **Main Logs**: `/trunkrecorder/logs/` (RAM drive)
- 🖥️ **System Logs**: `journalctl -u trunk-recorder`
- 🔄 **Update Logs**: `/var/log/trunkrecorder/YYYYMMDD_update.log`

### 🤖 Automatic Maintenance

- 🔄 **RAM Cleanup**: Recordings deleted after 5 minutes, logs after 30 minutes
- 🧹 **Automated Timer**: Cleanup runs every 2 minutes via systemd timer
- 🔧 **System Updates**: Unattended upgrades enabled
- 🌙 **Nightly Updates**: Automatic talkgroup refresh with systemd timer

## 🔧 Troubleshooting

### ⚠️ Common Issues

📻 **RTL-SDR Not Detected**:
```bash
# Check USB devices
lsusb | grep RTL

# Test RTL-SDR
rtl_test -d 0

# Configure RTL-SDR devices with unique indices
sudo ./configure-rtlsdr.sh
```

🔑 **RTL-SDR Index Issues**:
```bash
# Stop trunk-recorder service first
sudo systemctl stop trunk-recorder

# Check device serials
for i in {0..2}; do rtl_eeprom -d $i | grep Serial; done

# Reset device serials
sudo ./configure-rtlsdr.sh

# Verify config.json device indices
grep -A 1 "device" /etc/trunk-recorder/config.json

# Restart service when done
sudo systemctl start trunk-recorder
```

> **Important**: Always stop the trunk-recorder service before configuring RTL-SDR devices, as the service locks the devices and prevents configuration.

⏰ **Time Sync Issues**:
```bash
# Check time sync
sudo chronyc tracking

# Force sync
sudo chronyc makestep
```

📤 **Upload Failures**:
- ✅ Verify API keys in config.json
- 🌐 Check network connectivity
- 📝 Review service logs for specific errors

🎵 **No Audio Recordings**:
- ✅ Verify control channels are correct
- 📻 Check RTL-SDR gain settings
- 👥 Confirm talkgroups are active

📊 **RDIOScanner Not Uploading**:
- ✅ Verify shortName in plugin config matches system shortName
- 🔍 Check logs for "[Rdio Scanner]" messages during startup
- 🎯 Ensure API key and system ID are correct
- 🔄 Restart service after config changes: `sudo systemctl restart trunk-recorder`

### 📊 Log Analysis

**Broadcastify Errors**:
- `REJECTED-CALL-SKEW`: Time synchronization issue
- `REJECTED-API-KEY`: Invalid API key
- `REJECTED-SYSTEM-ID`: Wrong system ID

**OpenMHz Errors**:
- `ShortName does not exist`: System not configured in OpenMHz
- `Invalid API Key`: Check API key configuration

**RDIOScanner Errors**:
- `No upload messages in logs`: Check shortName matches system shortName in config
- `Connection refused`: Verify RDIOScanner server URL and port
- `Invalid API Key`: Check API key configuration in RDIOScanner admin

## 🔒 Security Considerations

### 🛡️ Credential Protection
- Credentials stored in `/etc/trunk-recorder/radioreference-creds`
- File permissions: 600 (owner read/write only)
- Owner: trunkrecorder user

### 🌐 Network Security
- Consider firewall rules for upload services
- Monitor outbound connections
- Use HTTPS for all uploads

### 🔧 System Hardening
- Regular security updates via unattended-upgrades
- Non-root service execution
- Minimal service exposure

## ⚡ Performance Optimization

### 📻 RTL-SDR Settings
- **Gain**: 49 (maximum for most dongles)
- **Sample Rate**: 2.4 MHz per dongle
- **PPM Correction**: Adjust if frequency drift observed

### 💻 System Resources
- **CPU**: Monitor with `htop` during peak activity
- **Memory**: 4GB+ recommended for 3 RTL-SDR setup
- **Storage**: Monitor recording disk usage

### 🌐 Network Bandwidth
- **Uploads**: ~1-5 Mbps depending on activity
- **Updates**: Minimal daily bandwidth for talkgroup refresh

## 🚀 Production Deployment

### ✅ Pre-Deployment Checklist

- [ ] Hardware tested and verified
- [ ] RadioReference account confirmed
- [ ] Upload service accounts configured
- [ ] Network connectivity verified
- [ ] Storage capacity planned
- [ ] Backup strategy implemented

### 📋 Deployment Steps

1. 🔧 **System Installation**: Run master-build.sh
2. ✅ **Configuration Verification**: Test all upload services
3. 📊 **Monitoring Setup**: Configure log monitoring
4. 📝 **Documentation**: Record system-specific settings
5. 💾 **Backup Configuration**: Save config files

### 🎯 Post-Deployment

1. 👀 **Monitor Initial Operation**: Watch logs for 24-48 hours
2. ✅ **Verify Uploads**: Confirm recordings appear on services
3. 📊 **Performance Baseline**: Document normal resource usage
4. 📅 **Schedule Maintenance**: Plan regular system checks

## 🛠️ Support and Maintenance

### 🔄 Regular Maintenance Tasks

📅 **Weekly**:
- ✅ Check service status
- 📝 Review error logs
- 📤 Verify upload functionality

📅 **Monthly**:
- 🔧 System updates
- 🧹 Storage cleanup verification
- 📊 Performance review

📅 **Quarterly**:
- 💾 Configuration backup
- 🔍 Hardware inspection
- 🔒 Security review

### 💾 Backup Strategy

📄 **Configuration Files**:
```bash
# Backup essential configs
sudo tar -czf trunk-recorder-backup.tar.gz \
  /etc/trunk-recorder/ \
  /opt/trunk-recorder/fetch-radioreference.py
```

🔄 **System Recovery**:
- 💾 Keep copy of master-build.sh and credentials
- 📝 Document system-specific settings
- 🧪 Test recovery procedures

## 📚 API Documentation

### 📡 RadioReference Integration
- **Authentication**: Username/password login
- **Data Sources**: CSV downloads for talkgroups and sites
- **Update Frequency**: Nightly automatic updates
- **Rate Limiting**: Respectful API usage

### 📤 Upload Services

**Broadcastify**:
- **Endpoint**: https://api.broadcastify.com/call-upload
- **Authentication**: API key + System ID
- **Format**: WAV files with metadata

**OpenMHz**:
- **Endpoint**: https://api.openmhz.com
- **Authentication**: API key
- **Format**: JSON metadata + audio

**RDIOScanner**:
- **Endpoint**: Configurable server URL
- **Authentication**: API key
- **Format**: Plugin-based upload

## 📈 Version History

- **v1.0**: Initial release with basic functionality
- **v1.1**: Added multi-site support
- **v1.2**: Enhanced upload service integration
- **v1.3**: Improved time synchronization
- **v1.4**: Production hardening and documentation
- **v1.5**: SD Card Protection and Performance Improvements
  - 💾 **Complete RAM Drive System**: All recordings and logs stored in RAM (1GB tmpfs at `/trunkrecorder`)
  - 🛡️ **SD Card Longevity**: Zero write operations to SD card for recordings/logs
  - 🧹 **Automatic Cleanup**: Recordings deleted after 5 minutes, logs after 30 minutes
  - ⚖️ **Balanced Recorder Distribution**: Improved algorithm distributes 36 recorders evenly across RTL-SDR devices
  - 🔧 **Smart Installation**: Setup script now prompts before rebuilding trunk-recorder binary
  - 📊 **Enhanced Site Selection**: Multi-column display shows all available site information
  - ⏱️ **Optimized Timeouts**: Reduced call timeout to 120 seconds for faster recorder availability
  - 🔄 **Automated Cleanup Service**: Systemd timer runs every 2 minutes to manage RAM usage
- **v1.6**: RDIOScanner Configuration Fix
  - 🔧 **Fixed RDIOScanner Upload Issue**: Corrected shortName mismatch that prevented uploads
  - 🎯 **Automatic Shortname Matching**: RDIOScanner plugin now defaults to system shortName
  - 📝 **Improved Configuration Prompts**: Clearer guidance for upload service setup
- **v1.7**: Automated Nightly Updates
  - 💾 **Deployment Settings Storage**: User inputs saved to `/etc/trunk-recorder/deployment-settings.json`
  - 🌙 **Automated Talkgroup Updates**: Nightly systemd timer updates talkgroups from RadioReference
  - 📅 **Update Logging**: Daily update logs stored in `/var/log/trunkrecorder/`
  - 🔄 **Service Restart**: Automatic trunk-recorder restart after talkgroup updates
- **v1.8**: Intelligent System Analysis and Installation
  - 🔍 **Smart System Detection**: Comprehensive OS, architecture, and hardware analysis
  - 🎯 **Installation Method Selection**: Automated recommendations for Docker, native, or source installation
  - 🐳 **Enhanced Docker Support**: Complete containerized deployment with volume management
  - 📊 **System Requirements Analysis**: Memory, CPU, and dependency checking
  - 🔧 **Modular Architecture**: Separated system detection, analysis, and installation logic
  - 📋 **Interactive Configuration**: Guided setup with intelligent defaults and validation
  - 🛠️ **Platform-Specific Optimization**: Tailored installation for Ubuntu, Debian, Fedora, CentOS, Arch, openSUSE, and macOS
  - 📈 **Performance Recommendations**: Hardware-specific tuning suggestions

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes with appropriate documentation
4. Test thoroughly
5. Submit pull request

## 💬 Support

For issues and support:
- 🐛 **GitHub Issues**: Report bugs and feature requests
- 📚 **Documentation**: Check this README and inline comments
- 👥 **Community**: RadioReference.com forums for radio-specific questions