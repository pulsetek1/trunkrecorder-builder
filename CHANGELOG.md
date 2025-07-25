# 📋 Changelog

All notable changes to the Trunk Recorder Master Build System will be documented in this file.

## [2.0.3] 📻

### ✨ Added
- **📻 RTL-SDR Device Configuration**: Automatic assignment of unique device indices
- **🔑 Serial Number Management**: Uses rtl_eeprom to set unique serial numbers
- **⚙️ Config Integration**: Updates config.json with correct device indices
- **🔧 Device Verification**: Checks for duplicate serials and resolves conflicts

### 🔧 Fixed
- **📻 Service Handling**: Automatically stops trunk-recorder service before RTL-SDR configuration
- **🔒 Device Access**: Prevents device access conflicts during configuration
- **🔄 Service Recovery**: Restores service state after configuration

## [2.0.2] 🎆

### ✨ Added
- **🔍 Smart OS Detection**: Comprehensive system analysis with detect-system.sh
- **🐳 Multi-Platform Support**: Docker, Linux native, Raspberry Pi OS, and macOS guidance
- **📦 Distribution-Specific Packages**: Support for Ubuntu, Debian, Fedora, CentOS, Arch, openSUSE
- **🥧 Raspberry Pi OS Integration**: Dedicated Pi OS support with performance tuning
- **📊 System Recommendations**: Memory, architecture, and platform-based installation advice

### 🔧 Fixed
- **📦 Package Installation**: Fixed apt install command with malformed line continuations
- **🐛 Dependency Resolution**: Removed inline comments breaking package installation

## [2.0.1] 🌟

### 🚀 Released
- **🌐 GitHub Public Release**: Made repository public on GitHub at https://github.com/pulsetek1/trunkrecorder-pi-builder
- **📚 Documentation Polish**: Enhanced README and DEPLOYMENT guides with icons and improved formatting
- **🧹 Code Cleanup**: Removed legacy AACO-specific references for universal deployment

### 🔧 Fixed
- **👤 User Creation**: Added trunkrecorder user/group creation to master-build.sh
- **📁 Directory Setup**: Ensured /etc/trunk-recorder directory is created before use
- **🔒 Permissions**: Fixed initial directory ownership and permissions

## [2.0.0] 🎉

### ✨ Added
- **🔗 Universal System Support**: Complete rewrite to support any P25 system via RadioReference.com
- **🤖 Automated RadioReference Integration**: Live data fetching with login authentication
- **🏢 Multi-Site Support**: Automatic detection and user selection of multiple sites per system
- **📤 Triple Upload Service Integration**: Full support for Broadcastify, OpenMHz, and RDIOScanner
- **🌙 Nightly Auto-Updates**: Automatic talkgroup refresh from RadioReference.com
- **⏰ Time Synchronization**: Chrony NTP client for accurate timestamps
- **🔧 Intelligent RTL-SDR Configuration**: Auto-calculates optimal dongle setup (1-3 dongles)
- **📊 Enhanced Monitoring**: Comprehensive system health checks and diagnostics
- **🛡️ Security Hardening**: Secure credential storage and non-root service execution
- **📚 Production Documentation**: Complete deployment and maintenance guides with icons

### 🔄 Changed
- **🎯 Generic Branding**: Removed AACO-specific references for universal deployment
- **⚡ One-Command Deploy**: Single `master-build.sh` script handles everything
- **📁 Improved File Structure**: Better organization of config files and logs
- **🔧 Enhanced Error Handling**: Better validation and user feedback
- **📦 Ubuntu 24.04 LTS**: Updated for latest Ubuntu LTS compatibility

### 🐛 Fixed
- **⏰ Clock Skew Issues**: Resolved Broadcastify upload rejections due to time drift
- **🎯 Site Selection**: Fixed site ID capture for nightly update service
- **✅ Config Validation**: Proper JSON format validation and error reporting
- **🔄 Service Management**: Improved handling of existing installations
- **📻 RTL-SDR Detection**: Enhanced hardware detection and configuration

### 🔒 Security
- **🛡️ Credential Protection**: Secure storage of RadioReference credentials (600 permissions)
- **👤 Service Isolation**: Non-root service execution with minimal privileges
- **🔐 File Permissions**: Proper ownership and permissions for all system files

## [1.4.0]

### ✨ Added
- **📊 System Verification**: Added comprehensive system verification script
- **🧹 Automatic Cleanup**: Recording cleanup after 14 days
- **📝 Log Rotation**: 7-day log retention with automatic rotation
- **🔄 Service Recovery**: Automatic service restart on failure

### 🔄 Changed
- **📦 Package Management**: Updated dependency list for better compatibility
- **⚙️ Configuration Structure**: Improved JSON structure for upload services

## [1.3.0]

### ✨ Added
- **📥 CSV Download Integration**: Direct CSV downloads from RadioReference
- **📊 Multiple Talkgroup Formats**: Generate files for different upload services
- **🎯 Site-Specific Configuration**: Extract frequencies and NAC from selected sites
- **⚙️ Automated Service Setup**: Complete systemd service configuration

### 🔄 Changed
- **📊 Data Source**: Switched from web scraping to official CSV downloads
- **⚙️ Configuration Structure**: Improved JSON structure for better compatibility

## [1.2.0]

### ✨ Added
- **🔗 RadioReference Integration**: Automated login and data fetching
- **📤 Upload Service Support**: Initial support for Broadcastify and OpenMHz
- **📻 RTL-SDR Configuration**: Automatic RTL-SDR setup and testing
- **✅ System Verification**: User confirmation of system information

## [1.1.0]

### ✨ Added
- **🚀 Master Build Script**: Single command deployment system
- **📦 Dependency Management**: Automatic installation of required packages
- **⚙️ Service Management**: Systemd service creation and management

## [1.0.0]

### ✨ Added
- **🎉 Initial Release**: Basic Trunk Recorder installation script
- **📻 Hardware Support**: RTL-SDR configuration
- **⚙️ Basic Configuration**: Static configuration files

---

## 📊 Version Numbering

This project follows [Semantic Versioning](https://semver.org/):
- **🔴 MAJOR**: Incompatible API changes
- **🟡 MINOR**: New functionality in a backwards compatible manner  
- **🟢 PATCH**: Backwards compatible bug fixes

## 🚀 Release Process

1. **💻 Development**: Feature development in feature branches
2. **🧪 Testing**: Comprehensive testing in development environment
3. **📚 Documentation**: Update README, DEPLOYMENT, and CHANGELOG
4. **🏷️ Release**: Tag version and create release notes
5. **🚀 Deployment**: Deploy to production environments

## ⬆️ Upgrade Notes

### From 1.x to 2.0.0
- **🔄 Complete Rewrite**: New universal system support
- **⚠️ Breaking Changes**: Configuration format completely changed
- **🔧 Fresh Install**: Recommended to start with fresh installation
- **📊 Data Migration**: Talkgroup data will be refreshed from RadioReference

## 🛠️ Support Matrix

| Version | Ubuntu 20.04 | Ubuntu 22.04 | Ubuntu 24.04 | Support Status |
|---------|--------------|--------------|--------------|----------------|
| 2.0.x   | ❌           | ⚠️           | ✅           | 🟢 Active      |
| 1.4.x   | ❌           | ⚠️           | ✅           | 🟡 Security Only |
| 1.3.x   | ❌           | ❌           | ❌           | 🔴 End of Life |

**Legend:**
- ✅ Fully Supported
- ⚠️ Limited Support (may work but not tested)
- ❌ Not Supported

## ⚠️ Known Issues

### Version 2.0.0
- **📻 RTL-SDR V4**: Some RTL-SDR Blog V4 dongles may require firmware updates
- **💻 ARM64 Performance**: High CPU usage on some ARM64 systems during peak activity
- **📤 Upload Delays**: Occasional delays in upload services during high traffic

### 🔧 Workarounds
- **📻 RTL-SDR V4**: Update firmware using rtl_eeprom tool
- **💻 ARM64 Performance**: Reduce digitalRecorders count in config
- **📤 Upload Delays**: Monitor logs and restart service if needed

## 🔄 Migration Guide

### Migrating from 1.x to 2.0

1. **💾 Backup Current Config**:
   ```bash
   sudo cp -r /etc/trunk-recorder /etc/trunk-recorder.backup
   ```

2. **🚀 Run Master Build**:
   ```bash
   git clone https://github.com/pulsetek1/trunkrecorder-pi-builder.git
   cd trunkrecorder-pi-builder
   sudo ./master-build.sh
   ```

3. **✅ Verify Configuration**:
   ```bash
   sudo systemctl status trunk-recorder
   ```

## 🗺️ Future Roadmap

### Version 2.1.0 (Planned Q1 2025)
- **🌐 Web Interface**: Basic web interface for monitoring and configuration
- **📊 Enhanced Analytics**: Recording statistics and system metrics
- **☁️ Cloud Storage**: Support for cloud-based recording storage
- **📱 Mobile Notifications**: Push notifications for system alerts

### Version 2.2.0 (Planned Q2 2025)
- **🔗 Multi-System Support**: Support for monitoring multiple radio systems
- **📊 Prometheus Integration**: Metrics export for monitoring systems
- **🤖 API Integration**: RESTful API for external integrations
- **🔄 Clustering**: Support for distributed deployments

### Long-term Goals
- **🧠 Machine Learning**: Automatic talkgroup classification
- **⚡ Real-time Processing**: Live audio processing and alerting
- **🏢 Enterprise Features**: Multi-tenant support and advanced management
- **☁️ Cloud Native**: Kubernetes deployment support

## 🤝 Contributing

### Development Workflow
1. **🍴 Fork Repository**: Create personal fork
2. **🌿 Feature Branch**: Create feature branch from main
3. **💻 Development**: Implement changes with tests
4. **📚 Documentation**: Update relevant documentation
5. **🔄 Pull Request**: Submit PR with detailed description

### Testing Requirements
- **🧪 Unit Tests**: All new functions must have tests
- **🔗 Integration Tests**: End-to-end testing required
- **📚 Documentation**: All changes must be documented
- **⬅️ Backwards Compatibility**: Maintain compatibility when possible

### Code Standards
- **🐚 Shell Scripts**: Follow ShellCheck recommendations
- **🐍 Python**: Follow PEP 8 style guide
- **📝 Documentation**: Use Markdown for all documentation
- **💬 Comments**: Inline comments for complex logic

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **📻 Trunk Recorder Project**: Core radio monitoring software by robotastic
- **📊 RadioReference.com**: Radio system database and community
- **📻 RTL-SDR Community**: Hardware drivers and support libraries
- **📤 Upload Services**: Broadcastify, OpenMHz, and RDIOScanner teams
- **🐧 Open Source Community**: All the amazing tools that make this possible

---

*🎉 Thank you for using Trunk Recorder Master Build System!*