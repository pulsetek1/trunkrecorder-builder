# 🚀 Production Deployment Guide

## 📋 Quick Deploy

### 1️⃣ Clone & Setup
```bash
git clone https://github.com/pulsetek1/trunkrecorder-builder.git
cd trunkrecorder-builder
sudo ./master-build.sh
```

### 2️⃣ Required Info
- 🔐 **RadioReference.com** username/password
- 🆔 **System ID** (from RadioReference URL)
- 📝 **Short name** (e.g., "metro", "county")

### 3️⃣ Upload Services (Optional)
- 📻 **Broadcastify**: API key + System ID
- 🌐 **OpenMHz**: API key
- 📊 **RDIOScanner**: Server URL + API key

## ✅ Pre-Flight Checklist

- [ ] 🥧 Raspberry Pi 4 (4GB+ RAM)
- [ ] 📻 1-3 RTL-SDR dongles connected
- [ ] 🔑 RTL-SDR dongles with unique serial numbers
- [ ] 🌐 Internet connection active
- [ ] 💾 32GB+ storage available
- [ ] 👤 RadioReference premium account

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

```bash
# Check service status
sudo systemctl status trunk-recorder

# Monitor logs
sudo journalctl -u trunk-recorder -f

# Verify recordings
ls -la /var/lib/trunk-recorder/recordings/

# Test nightly updates
sudo systemctl status radioreference-update.timer
```

## 🎯 Production Checklist

### ✅ Day 1
- [ ] Service running without errors
- [ ] RTL-SDR dongles detected
- [ ] Control channels locked
- [ ] First recordings captured

### ✅ Week 1
- [ ] Upload services working
- [ ] Nightly updates successful
- [ ] Log rotation functioning
- [ ] Storage usage monitored

### ✅ Month 1
- [ ] Performance baseline established
- [ ] Backup strategy implemented
- [ ] Monitoring alerts configured
- [ ] Documentation updated

## 🆘 Quick Fixes

### 📻 No RTL-SDR Detected
```bash
# Reload udev rules
sudo udevadm control --reload-rules
sudo udevadm trigger

# Configure device indices
sudo ./configure-rtlsdr.sh
```

### 🔑 RTL-SDR Index Problems
```bash
# Reset device serials and indices
sudo ./configure-rtlsdr.sh

# Unplug and reconnect devices if needed
```

### ⏰ Time Sync Issues
```bash
sudo chronyc makestep
sudo systemctl restart trunk-recorder
```

### 📤 Upload Failures
```bash
# Check config
sudo nano /etc/trunk-recorder/config.json

# Restart service
sudo systemctl restart trunk-recorder
```

## 📞 Support

- 🐛 **Issues**: [GitHub Issues](https://github.com/pulsetek1/trunkrecorder-builder/issues)
- 📚 **Docs**: [README.md](https://github.com/pulsetek1/trunkrecorder-builder/blob/main/README.md)
- 👥 **Community**: RadioReference.com forums

---
*🎉 Happy monitoring! Your P25 system is now live.*