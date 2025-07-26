# Changelog

All notable changes to the Trunk Recorder Master Build System will be documented in this file.

## [v1.8] - 2025-01-25

### Added
- **Intelligent System Analysis**: Comprehensive OS, architecture, memory, and hardware detection
- **Installation Method Selection**: Automated recommendations for Docker, native packages, or source compilation
- **Enhanced Docker Support**: Complete containerized deployment with proper volume management
- **System Requirements Analysis**: Memory, CPU, and dependency validation before installation
- **Platform-Specific Support**: Tailored installation for Ubuntu, Debian, Fedora, CentOS, Arch, openSUSE, and macOS
- **Interactive Configuration**: Guided setup with intelligent defaults and input validation
- **Performance Recommendations**: Hardware-specific tuning suggestions based on system analysis

### Changed
- **Modular Architecture**: Separated system detection (`detect-system.sh`) from main installation logic
- **Installation Flow**: User now selects from recommended installation methods based on system analysis
- **Configuration Management**: Enhanced validation and error handling throughout setup process

### Improved
- **User Experience**: Clear system analysis results with tailored recommendations
- **Installation Reliability**: Better error handling and dependency management
- **Documentation**: Updated with new installation options and system requirements

## [v1.7] - 2025-01-25

### Added
- **Deployment Settings Storage**: User inputs from master-build.sh saved to `/etc/trunk-recorder/deployment-settings.json`
- **Automated Nightly Updates**: Systemd timer service for automatic talkgroup updates
- **Update Logging**: Daily update logs stored in `/var/log/trunkrecorder/YYYYMMDD_update.log`
- **Update-Only Mode**: New `--update-only` flag for fetch-radioreference.py

### Changed
- **Service Restart**: Automatic trunk-recorder restart after talkgroup updates
- **Log Location**: Update logs moved from RAM drive to persistent storage

### Improved
- **Maintenance Automation**: Reduced manual intervention for talkgroup updates
- **System Reliability**: Automated service restart ensures configuration changes take effect

## [v1.6] - 2025-01-25

### Fixed
- **RDIOScanner Upload Issue**: Corrected shortName mismatch between system configuration and RDIOScanner plugin that prevented uploads
- **Configuration Script**: Modified `fetch-radioreference.py` to automatically default RDIOScanner shortName to match system shortName

### Improved
- **Configuration Prompts**: Enhanced RDIOScanner setup prompts with clearer guidance
- **Documentation**: Added troubleshooting section for RDIOScanner upload issues
- **Error Handling**: Better error messages for RDIOScanner configuration problems

## [v1.5] - 2024-12-15

### Added
- **Complete RAM Drive System**: All recordings and logs stored in RAM (1GB tmpfs at `/trunkrecorder`)
- **Automated Cleanup Service**: Systemd timer runs every 2 minutes to manage RAM usage
- **Enhanced Site Selection**: Multi-column display shows all available site information

### Changed
- **SD Card Protection**: Zero write operations to SD card for recordings/logs
- **Optimized Timeouts**: Reduced call timeout to 120 seconds for faster recorder availability
- **Balanced Recorder Distribution**: Improved algorithm distributes 36 recorders evenly across RTL-SDR devices

### Improved
- **Smart Installation**: Setup script now prompts before rebuilding trunk-recorder binary
- **Automatic Cleanup**: Recordings deleted after 5 minutes, logs after 30 minutes

## [v1.4] - 2024-11-20

### Added
- Production hardening and comprehensive documentation
- Security considerations and best practices
- Performance optimization guidelines

### Improved
- System monitoring and maintenance procedures
- Backup and recovery strategies
- API documentation

## [v1.3] - 2024-10-15

### Improved
- Time synchronization with Chrony NTP
- Timestamp accuracy for recordings
- System clock management

## [v1.2] - 2024-09-10

### Enhanced
- Upload service integration for Broadcastify, OpenMHz, and RDIOScanner
- Multi-service configuration support
- Upload reliability improvements

## [v1.1] - 2024-08-05

### Added
- Multi-site support for complex radio systems
- Site selection interface
- Enhanced system configuration

## [v1.0] - 2024-07-01

### Initial Release
- Basic Trunk Recorder deployment automation
- RadioReference.com integration
- RTL-SDR configuration
- Systemd service management