# 🤖 Amazon Q Project Specification

## How to Ask Amazon Q to Build This Trunk Recorder System

Based on analysis of this complete project, here's exactly what you would need to ask Amazon Q to recreate this automated P25 radio monitoring deployment system.

---

## 🎯 Primary Request

"Create a complete automated deployment system for P25 trunked radio monitoring using Trunk Recorder with RadioReference.com integration. The system should be a one-command deployment that automatically fetches live radio system data and configures everything needed for production monitoring."

---

## 📋 Detailed Requirements

### 🔧 Core Functionality
"Build a master deployment script that:
1. Prompts for RadioReference.com credentials and system ID
2. Automatically logs into RadioReference.com and downloads CSV data for any P25 system
3. Parses the CSV to extract control channels, frequencies, NAC codes, and talkgroup data
4. Intelligently calculates optimal RTL-SDR dongle configuration (1-3 dongles) based on frequency span
5. Generates a complete Trunk Recorder config.json with proper RTL-SDR source definitions
6. Creates talkgroup files in multiple formats (standard, OpenMHz 25-char limit, RDIOScanner import)
7. Sets up automatic nightly updates to refresh data from RadioReference"

### ⚙️ System Integration
"Include comprehensive system integration:
1. Create trunkrecorder system user and all required directories
2. Install all dependencies for Ubuntu/Debian, Fedora, CentOS, Arch, openSUSE
3. Configure RTL-SDR drivers with proper udev rules and blacklisted conflicting modules
4. Build Trunk Recorder from source with full compilation process
5. Create systemd service with proper resource limits and restart policies
6. Set up log rotation, automatic recording cleanup, and system maintenance"

### 🔍 Intelligent System Analysis
"Create a comprehensive system analysis engine that:
1. Detects OS (Ubuntu, Debian, Fedora, CentOS, RHEL, Arch, openSUSE, Raspberry Pi OS, macOS)
2. Identifies architecture (x86_64, ARM64, ARM32), CPU cores, and available memory
3. Analyzes Docker availability, container environments, and virtualization
4. Detects Raspberry Pi hardware models and thermal capabilities
5. Evaluates system dependencies and build tool availability
6. Provides intelligent installation method recommendations with detailed pros/cons
7. Offers guided selection between Docker (easiest), native packages (fastest), or source compilation (latest features)
8. Validates system requirements before proceeding with installation"

### 📤 Upload Service Integration
"Support multiple upload services with user configuration:
1. Broadcastify - API key and system ID configuration
2. OpenMHz - API key configuration with 25-character description limits
3. RDIOScanner - server URL, API key, and system short name
4. Generate appropriate config sections and talkgroup formats for each service"

### 🥧 Raspberry Pi Specific Features
"Include dedicated Raspberry Pi OS support:
1. Detect Pi OS vs Ubuntu on Pi
2. Pi-specific dependency installation and system configuration
3. Performance tuning (CPU overclocking, GPU memory split, swap increase)
4. Thermal management guidance and power supply requirements
5. RTL-SDR USB power considerations and powered hub recommendations"

### 🐳 Enhanced Docker Integration
"Provide complete Docker deployment option:
1. Automatic Docker installation for each Linux distribution
2. Docker Compose configuration with proper volume mounts and USB device access
3. Privileged container setup for RTL-SDR hardware access
4. Container management commands and update procedures
5. Complete containerized deployment with volume management
6. Docker-specific configuration templates and service management
7. Container health checks and restart policies"

### 🚀 Production Features
"Include production-ready features:
1. Secure credential storage with proper file permissions
2. Automatic system updates and security hardening
3. Comprehensive logging and monitoring capabilities
4. Backup and recovery procedures
5. Service health checks and restart mechanisms
6. Performance optimization recommendations"

### 📚 Documentation
"Create comprehensive documentation:
1. README with icons and clear installation steps
2. Deployment guide for production environments
3. Troubleshooting section with common issues and solutions
4. Changelog with version history and upgrade notes
5. Support matrix showing platform compatibility"

### 📁 File Structure
"Organize the project with these key files:
- `master-build.sh` - Main deployment script with system analysis integration
- `fetch-radioreference.py` - RadioReference.com data fetcher with CSV parsing
- `setup.sh` - Trunk Recorder source compilation and installation
- `detect-system.sh` - Comprehensive system analysis and installation recommendations
- `analyze-config.py` - Configuration analysis and validation tools
- `configure-rtlsdr.sh` - RTL-SDR device configuration and management
- `README.md` - Complete documentation with icons and v1.8 features
- `DEPLOYMENT.md` - Quick deployment guide with new installation methods
- `CHANGELOG.md` - Version history including v1.8 system analysis features"

---

## 🔧 Technical Specifications

### 🐍 Python RadioReference Fetcher
"The Python RadioReference fetcher should:
1. Handle login authentication with session management
2. Parse HTML to extract system information for user verification
3. Download and parse CSV files for talkgroups and sites
4. Support multi-site systems with user selection
5. Calculate RTL-SDR center frequencies based on frequency span analysis
6. Generate JSON configuration with proper data types and structure"

### 🖥️ System Detection Requirements
"The system detection should support:
1. All major Linux distributions with specific package managers
2. Docker with compose file generation
3. Raspberry Pi OS with performance optimizations
4. macOS with Homebrew dependency management
5. Memory and architecture-based recommendations"

### 📦 Package Management
"Include distribution-specific package installation:
- **Ubuntu/Debian**: apt with complete dependency list
- **Fedora**: dnf with EPEL repository support
- **CentOS/RHEL**: yum with EPEL requirements
- **Arch Linux**: pacman with AUR package notes
- **openSUSE**: zypper with proper package names
- **macOS**: Homebrew with all required formulas"

### 🔒 Security Requirements
"Implement security best practices:
1. Non-root service execution with dedicated user account
2. Secure credential storage with 600 permissions
3. Proper file ownership and directory permissions
4. Service isolation and resource limits
5. Automatic security updates configuration"

---

## 🎯 Expected Outcome

This comprehensive request would result in exactly the system you have - a universal P25 radio monitoring deployment tool that:

✅ **Works across multiple platforms** with intelligent system analysis and automated recommendations  
✅ **Provides complete automation** from RadioReference data fetch to production deployment  
✅ **Includes comprehensive documentation** with troubleshooting and maintenance guides  
✅ **Supports multiple installation methods** with guided selection (Docker, native packages, source compilation)  
✅ **Handles production requirements** with security, monitoring, and maintenance features  
✅ **Offers platform-specific optimizations** for Raspberry Pi, different Linux distributions, and macOS  
✅ **Features intelligent system detection** with hardware analysis and performance recommendations  
✅ **Provides installation method guidance** based on system capabilities and user preferences  

---

## 💡 Usage Tips for Amazon Q

When asking Amazon Q to build this system:

1. **Start with the primary request** to establish the overall scope
2. **Follow with detailed requirements** section by section
3. **Specify technical requirements** for each component
4. **Request comprehensive documentation** and error handling
5. **Ask for production-ready features** including security and monitoring
6. **Specify file organization** and project structure

This approach ensures Amazon Q understands both the technical complexity and the production-ready nature of the system you want to build.

---

*This specification represents a complete automated P25 radio monitoring deployment system with multi-platform support, intelligent system detection, and production-ready features.*