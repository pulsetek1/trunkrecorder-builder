# Changelog

All notable changes to the Trunk Recorder Master Build System will be documented in this file.

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