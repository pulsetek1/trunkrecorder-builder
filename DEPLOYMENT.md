# 🚀 Production Deployment Guide

## 📋 One-Command Deploy

### 🎯 Complete System Setup
```bash
git clone https://github.com/pulsetek1/trunkrecorder-builder.git
cd trunkrecorder-builder
sudo ./master-build.sh
```

**⏱️ Time Required:** 20-45 minutes  
**🔄 Process:** Fully automated with guided prompts

**The script will:**
1. 📡 Connect to RadioReference.com and download your system data
2. 📊 Generate optimized RTL-SDR frequency distribution graph
3. 🔧 Install and configure Trunk Recorder from source
4. ⏰ Set up automatic nightly updates from RadioReference
5. 📤 Configure upload services (optional)
6. 🛡️ Enable SD card protection with RAM-based storage

## 🔍 Finding Your System ID

1. 🌐 Go to [RadioReference.com](https://www.radioreference.com)
2. 🔍 Search for your county/city radio system
3. 📋 Click on your P25 trunked system
4. 👀 Look at the URL: `/db/sid/XXXXX` (XXXXX is your System ID)
5. ✅ Ensure you have a **premium account** for CSV downloads

### 📋 Required Information
- 🔐 **RadioReference.com** premium account (username/password)
- 🆔 **System ID** (find at RadioReference.com in URL: /db/sid/XXXXX)
- 📝 **Short name** (4-10 characters, e.g., "metro", "county")
- 🏷️ **System abbreviation** (e.g., "METRO", "COUNTY")

### 📤 Upload Services (Optional)
- 📻 **Broadcastify**: API key + System ID
- 🌐 **OpenMHz**: API key
- 📊 **RDIOScanner**: Server URL + API key + System ID

## ✅ Pre-Flight Checklist

### 🖥️ Hardware Requirements
- [ ] 🥧 **Raspberry Pi 4** (4GB+ RAM) or compatible x86_64/ARM64 system
- [ ] 📻 **1-3 RTL-SDR dongles** connected via USB
- [ ] 🔌 **Powered USB hub** (recommended for multiple dongles)
- [ ] 🌐 **Internet connection** (for RadioReference and uploads)
- [ ] 💾 **32GB+ storage** (SD card or SSD)

### 📡 Software Requirements
- [ ] 🐧 **Ubuntu 24.04 LTS** (ARM64 or x86_64) or compatible Linux
- [ ] 👤 **RadioReference premium account** (required for CSV downloads)
- [ ] 🔐 **Root access** (script uses sudo)

### 📻 RTL-SDR Setup
- [ ] 🔑 **Unique serial numbers** (script will configure if needed)
- [ ] 🧪 **Device testing** (script will verify functionality)
- [ ] ⚡ **Adequate power supply** (especially for Pi with multiple dongles)

## 🔧 Hardware Test

```bash
# Test RTL-SDR dongles
for i in {0..2}; do
    echo "Testing RTL-SDR $i..."
    timeout 5 rtl_test -d $i -s 2400000
done

# Check system resources
free -h
df -h
```

## 📻 RTL-SDR Configuration

```bash
# Stop trunk-recorder service first
sudo systemctl stop trunk-recorder

# Configure RTL-SDR devices with unique indices
sudo ./configure-rtlsdr.sh

# Verify device serials
for i in {0..2}; do rtl_eeprom -d $i | grep Serial; done

# Check device indices in config
grep -A 1 "device" /etc/trunk-recorder/config.json

# Restart service when done
sudo systemctl start trunk-recorder
```

> **⚠️ Important**: The trunk-recorder service must be stopped before configuring RTL-SDR devices, as it locks the devices and prevents configuration.

## 📊 Post-Deploy Verification

### 🔍 System Status
```bash
# Check service status
sudo systemctl status trunk-recorder

# Monitor real-time logs
sudo journalctl -u trunk-recorder -f

# Verify recordings directory
ls -la /trunkrecorder/recordings/

# Check nightly update timer
sudo systemctl status talkgroup-update.timer
```

### 📈 Performance Monitoring
```bash
# View frequency distribution
cat /etc/trunk-recorder/siteinfo.json

# Check RTL-SDR device assignments
grep -A 1 "device" /etc/trunk-recorder/config.json

# Monitor RAM usage (recordings stored in RAM)
df -h /trunkrecorder

# View system resource usage
htop
```

## 🎯 Production Checklist

### ✅ Day 1 - Initial Deployment
- [ ] 🟢 Service running without errors
- [ ] 📻 All RTL-SDR dongles detected and configured
- [ ] 📡 Control channels locked and receiving
- [ ] 🎵 First recordings captured in /trunkrecorder/recordings/
- [ ] 📊 Frequency distribution graph shows optimal coverage
- [ ] 📤 Upload services configured and working (if enabled)

### ✅ Week 1 - System Validation
- [ ] 🔄 Nightly talkgroup updates successful
- [ ] 🧹 Automatic cleanup functioning (RAM management)
- [ ] 📈 Upload services delivering recordings
- [ ] 🔍 Log monitoring shows no critical errors
- [ ] 💾 Storage usage stable (RAM-based recordings)

### ✅ Month 1 - Long-term Stability
- [ ] 📊 Performance baseline established
- [ ] 💾 Configuration backup strategy implemented
- [ ] 🚨 Monitoring alerts configured
- [ ] 📚 Local documentation updated with system-specific notes
- [ ] 🔧 Hardware inspection completed

## 🆘 Troubleshooting Guide

### 📻 RTL-SDR Issues

**No RTL-SDR Detected:**
```bash
# Check USB devices
lsusb | grep RTL

# Reload udev rules
sudo udevadm control --reload-rules
sudo udevadm trigger

# Reconfigure devices
sudo ./configure-rtlsdr.sh
```

**Device Index Problems:**
```bash
# Stop service first
sudo systemctl stop trunk-recorder

# Reset device serials
sudo ./configure-rtlsdr.sh

# Verify configuration
grep -A 1 "device" /etc/trunk-recorder/config.json

# Restart service
sudo systemctl start trunk-recorder
```

### 🔧 Service Issues

**Service Won't Start:**
```bash
# Check detailed status
sudo systemctl status trunk-recorder -l

# View recent logs
sudo journalctl -u trunk-recorder --since "1 hour ago"

# Validate configuration
sudo -u trunkrecorder /opt/trunk-recorder/trunk-recorder --config=/etc/trunk-recorder/config.json --test
```

**No Recordings:**
```bash
# Check control channel lock
sudo journalctl -u trunk-recorder | grep "Control Channel"

# Verify talkgroup activity
cat /etc/trunk-recorder/talkgroup.csv | head -10

# Check frequency coverage
cat /etc/trunk-recorder/siteinfo.json
```

### 📤 Upload Service Issues

**Broadcastify Errors:**
- `REJECTED-CALL-SKEW`: Time sync issue - run `sudo chronyc makestep`
- `REJECTED-API-KEY`: Check API key in config.json
- `REJECTED-SYSTEM-ID`: Verify Broadcastify system ID

**OpenMHz Errors:**
- `ShortName does not exist`: System not configured in OpenMHz
- `Invalid API Key`: Verify API key in config.json

**RDIOScanner Errors:**
- Check shortName matches system shortName in config
- Verify server URL and port accessibility
- Confirm API key in RDIOScanner admin panel

## 📞 Support & Resources

### 🆘 Getting Help
- 🐛 **Bug Reports**: [GitHub Issues](https://github.com/pulsetek1/trunkrecorder-builder/issues)
- 📚 **Documentation**: [README.md](https://github.com/pulsetek1/trunkrecorder-builder/blob/main/README.md)
- 👥 **Community**: RadioReference.com forums
- 💬 **Discussions**: GitHub Discussions for questions

### 📋 Important Files
- 📄 **Main Config**: `/etc/trunk-recorder/config.json`
- 📊 **Talkgroups**: `/etc/trunk-recorder/talkgroup.csv`
- 🗂️ **Site Info**: `/etc/trunk-recorder/siteinfo.json`
- ⚙️ **Deployment Settings**: `/etc/trunk-recorder/deployment-settings.json`
- 🎵 **Recordings**: `/trunkrecorder/recordings/` (RAM-based)
- 📝 **Logs**: `/trunkrecorder/logs/` (RAM-based)

### 🔧 Useful Commands
```bash
# Service management
sudo systemctl {start|stop|restart|status} trunk-recorder

# Real-time monitoring
sudo journalctl -u trunk-recorder -f

# Manual talkgroup update
sudo /usr/local/bin/update-talkgroups.sh

# Check system health
sudo systemctl status trunk-recorder talkgroup-update.timer cleanup-ram-recordings.timer
```

---
*🎉 Happy monitoring! Your P25 system is now live and optimized.*