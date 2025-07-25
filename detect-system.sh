#!/bin/bash

# System Detection and Trunk Recorder Installation Recommendation Script
# Analyzes the current system and provides installation recommendations

set -e

echo "🔍 Analyzing System for Trunk Recorder Installation..."
echo

# Detect operating system and distribution
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            OS=$NAME
            VER=$VERSION_ID
            DISTRO_ID=$ID
        elif type lsb_release >/dev/null 2>&1; then
            OS=$(lsb_release -si)
            VER=$(lsb_release -sr)
            DISTRO_ID=$(echo $OS | tr '[:upper:]' '[:lower:]')
        else
            OS="Unknown Linux"
            VER="Unknown"
            DISTRO_ID="unknown"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macOS"
        VER=$(sw_vers -productVersion)
        DISTRO_ID="macos"
    else
        OS="Unknown"
        VER="Unknown"
        DISTRO_ID="unknown"
    fi
}

# Detect architecture
detect_arch() {
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)
            ARCH_TYPE="x86_64"
            ;;
        aarch64|arm64)
            ARCH_TYPE="ARM64"
            ;;
        armv7l)
            ARCH_TYPE="ARM32"
            ;;
        *)
            ARCH_TYPE="Unknown"
            ;;
    esac
}

# Detect if running in container
detect_container() {
    if [ -f /.dockerenv ]; then
        CONTAINER="Docker"
    elif [ -n "${container}" ]; then
        CONTAINER="Container"
    else
        CONTAINER="None"
    fi
}

# Check for Raspberry Pi
detect_raspberry_pi() {
    if [ -f /proc/device-tree/model ]; then
        MODEL=$(cat /proc/device-tree/model 2>/dev/null | tr -d '\0')
        if [[ $MODEL == *"Raspberry Pi"* ]]; then
            IS_PI=true
            PI_MODEL=$MODEL
        else
            IS_PI=false
        fi
    else
        IS_PI=false
    fi
}

# Check available memory
check_memory() {
    if command -v free >/dev/null 2>&1; then
        MEMORY_GB=$(free -g | awk '/^Mem:/{print $2}')
        MEMORY_MB=$(free -m | awk '/^Mem:/{print $2}')
    else
        MEMORY_GB="Unknown"
        MEMORY_MB="Unknown"
    fi
}

# Check for Docker
check_docker() {
    if command -v docker >/dev/null 2>&1; then
        DOCKER_AVAILABLE=true
        DOCKER_VERSION=$(docker --version 2>/dev/null | cut -d' ' -f3 | cut -d',' -f1)
    else
        DOCKER_AVAILABLE=false
    fi
}

# Check for package managers and set install commands
check_package_managers() {
    if command -v apt >/dev/null 2>&1; then
        PKG_MANAGER="apt"
        PKG_UPDATE="apt update"
        PKG_INSTALL="apt install -y"
    elif command -v dnf >/dev/null 2>&1; then
        PKG_MANAGER="dnf"
        PKG_UPDATE="dnf update -y"
        PKG_INSTALL="dnf install -y"
    elif command -v yum >/dev/null 2>&1; then
        PKG_MANAGER="yum"
        PKG_UPDATE="yum update -y"
        PKG_INSTALL="yum install -y"
    elif command -v pacman >/dev/null 2>&1; then
        PKG_MANAGER="pacman"
        PKG_UPDATE="pacman -Sy"
        PKG_INSTALL="pacman -S --noconfirm"
    elif command -v zypper >/dev/null 2>&1; then
        PKG_MANAGER="zypper"
        PKG_UPDATE="zypper refresh"
        PKG_INSTALL="zypper install -y"
    elif command -v brew >/dev/null 2>&1; then
        PKG_MANAGER="brew"
        PKG_UPDATE="brew update"
        PKG_INSTALL="brew install"
    else
        PKG_MANAGER="unknown"
        PKG_UPDATE=""
        PKG_INSTALL=""
    fi
}

# Run all detection functions
detect_os
detect_arch
detect_container
detect_raspberry_pi
check_memory
check_docker
check_package_managers

# Display system information
echo "📊 System Information:"
echo "   OS: $OS $VER"
echo "   Architecture: $ARCH_TYPE ($ARCH)"
echo "   Container: $CONTAINER"
if [ "$IS_PI" = true ]; then
    echo "   Device: $PI_MODEL"
fi
echo "   Memory: ${MEMORY_GB}GB (${MEMORY_MB}MB)"
echo "   Package Manager: $PKG_MANAGER"
if [ "$DOCKER_AVAILABLE" = true ]; then
    echo "   Docker: Available ($DOCKER_VERSION)"
else
    echo "   Docker: Not Available"
fi
echo

# Provide recommendations based on system
echo "🎯 Trunk Recorder Installation Recommendations:"
echo

# Docker recommendation
if [ "$DOCKER_AVAILABLE" = true ]; then
    echo "🐳 Docker Installation (Recommended for most users):"
    echo "   ✅ Easy setup and management"
    echo "   ✅ Isolated environment"
    echo "   ✅ No dependency conflicts"
    echo "   📋 Command: docker run -d --name trunk-recorder --privileged -v /dev/bus/usb:/dev/bus/usb trunkrecorder/trunk-recorder"
    echo
fi

# Linux-specific recommendations
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "🐧 Linux Native Installation:"
    
    # Get dependency packages for different distributions
    get_dependencies() {
        case $DISTRO_ID in
            ubuntu|debian)
                DEPS="build-essential cmake git libboost-all-dev libcurl4-openssl-dev libgmp-dev libhackrf-dev libpthread-stubs0-dev librtlsdr-dev libsndfile1-dev libsoapysdr-dev libuhd-dev libusb-1.0-0-dev pkg-config qtbase5-dev qtmultimedia5-dev rtl-sdr soapysdr-tools sox gnuradio gnuradio-dev gr-osmosdr liborc-0.4-dev libfftw3-dev libgsl-dev libssl-dev fdkaac"
                ;;
            fedora)
                DEPS="gcc gcc-c++ cmake git boost-devel libcurl-devel gmp-devel hackrf-devel rtl-sdr-devel libsndfile-devel SoapySDR-devel uhd-devel libusb1-devel pkgconfig qt5-qtbase-devel qt5-qtmultimedia-devel rtl-sdr SoapySDR sox gnuradio-devel gr-osmosdr orc-devel fftw-devel gsl-devel openssl-devel fdkaac"
                ;;
            centos|rhel)
                DEPS="gcc gcc-c++ cmake3 git boost-devel libcurl-devel gmp-devel hackrf-devel rtl-sdr-devel libsndfile-devel SoapySDR-devel uhd-devel libusb1-devel pkgconfig qt5-qtbase-devel qt5-qtmultimedia-devel rtl-sdr SoapySDR sox gnuradio-devel gr-osmosdr orc-devel fftw-devel gsl-devel openssl-devel"
                ;;
            arch|manjaro)
                DEPS="base-devel cmake git boost curl gmp hackrf rtl-sdr libsndfile soapysdr uhd libusb pkgconf qt5-base qt5-multimedia rtl-sdr-git soapysdr sox gnuradio gnuradio-osmosdr orc fftw gsl openssl fdkaac"
                ;;
            opensuse*|sles)
                DEPS="gcc gcc-c++ cmake git libboost_system-devel libcurl-devel gmp-devel hackrf-devel rtl-sdr-devel libsndfile-devel SoapySDR-devel uhd-devel libusb-1_0-devel pkg-config libqt5-qtbase-devel libqt5-qtmultimedia-devel rtl-sdr SoapySDR sox gnuradio-devel gr-osmosdr liborc-devel fftw3-devel gsl-devel libopenssl-devel"
                ;;
            *)
                DEPS=""
                ;;
        esac
    }
    
    get_dependencies
    
    # Ubuntu/Debian
    if [[ $DISTRO_ID == "ubuntu" ]] || [[ $DISTRO_ID == "debian" ]]; then
        echo "   📦 Dependencies Installation (Ubuntu/Debian):"
        echo "      📋 Commands:"
        echo "         sudo $PKG_UPDATE"
        echo "         sudo $PKG_INSTALL $DEPS"
        echo
        
        echo "   🔧 Source Installation (This Script):"
        echo "      ✅ Latest features with auto-config"
        echo "      ✅ Optimized for your system"
        echo "      ⚠️  Longer installation time (15-30 min)"
        echo "      📋 Command: sudo ./setup.sh"
        echo
    fi
    
    # Fedora
    if [[ $DISTRO_ID == "fedora" ]]; then
        echo "   📦 Dependencies Installation (Fedora):"
        echo "      📋 Commands:"
        echo "         sudo $PKG_UPDATE"
        echo "         sudo $PKG_INSTALL $DEPS"
        echo "         sudo dnf install -y epel-release  # If needed"
        echo
        
        echo "   🔧 Source Installation:"
        echo "      ✅ Best compatibility for Fedora"
        echo "      📋 Command: sudo ./setup.sh"
        echo
    fi
    
    # CentOS/RHEL
    if [[ $DISTRO_ID == "centos" ]] || [[ $DISTRO_ID == "rhel" ]]; then
        echo "   📦 Dependencies Installation (CentOS/RHEL):"
        echo "      ⚠️  Requires EPEL repository"
        echo "      📋 Commands:"
        echo "         sudo $PKG_INSTALL epel-release"
        echo "         sudo $PKG_UPDATE"
        echo "         sudo $PKG_INSTALL $DEPS"
        echo
        
        echo "   🔧 Source Installation:"
        echo "      ✅ Recommended for RHEL/CentOS"
        echo "      📋 Command: sudo ./setup.sh"
        echo
    fi
    
    # Arch Linux
    if [[ $DISTRO_ID == "arch" ]] || [[ $DISTRO_ID == "manjaro" ]]; then
        echo "   📦 Dependencies Installation (Arch Linux):"
        echo "      📋 Commands:"
        echo "         sudo $PKG_UPDATE"
        echo "         sudo $PKG_INSTALL $DEPS"
        echo "         # May need AUR packages for some dependencies"
        echo
        
        echo "   🔧 Source Installation:"
        echo "      ✅ Rolling release compatibility"
        echo "      📋 Command: sudo ./setup.sh"
        echo
    fi
    
    # openSUSE
    if [[ $DISTRO_ID == opensuse* ]] || [[ $DISTRO_ID == "sles" ]]; then
        echo "   📦 Dependencies Installation (openSUSE):"
        echo "      📋 Commands:"
        echo "         sudo $PKG_UPDATE"
        echo "         sudo $PKG_INSTALL $DEPS"
        echo
        
        echo "   🔧 Source Installation:"
        echo "      ✅ SUSE compatibility"
        echo "      📋 Command: sudo ./setup.sh"
        echo
    fi
    
    # Generic Linux
    if [[ $DISTRO_ID == "unknown" ]] || [[ -z $DEPS ]]; then
        echo "   🔧 Generic Linux Installation:"
        echo "      ⚠️  Manual dependency installation required"
        echo "      📚 See: https://github.com/TrunkRecorder/trunk-recorder/blob/master/docs/Install/INSTALL-LINUX.md"
        echo
    fi
fi

# Raspberry Pi specific
if [ "$IS_PI" = true ]; then
    echo "🥧 Raspberry Pi Specific:"
    
    # Detect Raspberry Pi OS vs Ubuntu on Pi
    if [[ $DISTRO_ID == "raspbian" ]] || [[ $OS == *"Raspberry Pi OS"* ]]; then
        echo "   🎓 Raspberry Pi OS Detected"
        echo "   📦 Pi OS Dependencies:"
        echo "      sudo apt update"
        echo "      sudo apt install -y build-essential cmake git"
        echo "      sudo apt install -y libboost-all-dev libcurl4-openssl-dev"
        echo "      sudo apt install -y libgmp-dev libhackrf-dev librtlsdr-dev"
        echo "      sudo apt install -y libsndfile1-dev libsoapysdr-dev libuhd-dev"
        echo "      sudo apt install -y libusb-1.0-0-dev pkg-config"
        echo "      sudo apt install -y qtbase5-dev qtmultimedia5-dev"
        echo "      sudo apt install -y rtl-sdr soapysdr-tools sox"
        echo "      sudo apt install -y gnuradio gnuradio-dev gr-osmosdr"
        echo "      sudo apt install -y liborc-0.4-dev libfftw3-dev libgsl-dev"
        echo "      sudo apt install -y libssl-dev fdkaac"
        echo
        
        echo "   ⚙️ Pi OS Specific Setup:"
        echo "      # Enable SPI and I2C (optional)"
        echo "      sudo raspi-config nonint do_spi 0"
        echo "      sudo raspi-config nonint do_i2c 0"
        echo "      # Increase GPU memory split"
        echo "      sudo raspi-config nonint do_memory_split 64"
        echo "      # Disable WiFi power management (if using WiFi)"
        echo "      echo 'iwconfig wlan0 power off' | sudo tee -a /etc/rc.local"
        echo
        
        echo "   🔥 Pi OS Performance Tuning:"
        echo "      # Add to /boot/config.txt:"
        echo "      echo 'arm_freq=1800' | sudo tee -a /boot/config.txt"
        echo "      echo 'over_voltage=6' | sudo tee -a /boot/config.txt"
        echo "      echo 'gpu_mem=64' | sudo tee -a /boot/config.txt"
        echo "      # Increase swap (for compilation)"
        echo "      sudo dphys-swapfile swapoff"
        echo "      sudo sed -i 's/CONF_SWAPSIZE=100/CONF_SWAPSIZE=2048/' /etc/dphys-swapfile"
        echo "      sudo dphys-swapfile setup && sudo dphys-swapfile swapon"
        echo
        
        echo "   📻 RTL-SDR Pi OS Setup:"
        echo "      # Blacklist DVB drivers"
        echo "      echo 'blacklist dvb_usb_rtl28xxu' | sudo tee -a /etc/modprobe.d/blacklist-rtl.conf"
        echo "      echo 'blacklist rtl2832' | sudo tee -a /etc/modprobe.d/blacklist-rtl.conf"
        echo "      echo 'blacklist rtl2830' | sudo tee -a /etc/modprobe.d/blacklist-rtl.conf"
        echo "      # Add udev rules"
        echo "      echo 'SUBSYSTEM==\"usb\", ATTRS{idVendor}==\"0bda\", ATTRS{idProduct}==\"2838\", GROUP=\"plugdev\", MODE=\"0666\"' | sudo tee /etc/udev/rules.d/20-rtlsdr.rules"
        echo "      sudo udevadm control --reload-rules"
        echo
        
    elif [[ $DISTRO_ID == "ubuntu" ]]; then
        echo "   🐧 Ubuntu on Raspberry Pi Detected"
        echo "   ℹ️ Use standard Ubuntu installation method above"
        echo
    fi
    
    # Memory-based recommendations
    if [ "$MEMORY_GB" -ge 4 ]; then
        echo "   ✅ Sufficient memory (${MEMORY_GB}GB) for source compilation"
        if [[ $DISTRO_ID == "raspbian" ]] || [[ $OS == *"Raspberry Pi OS"* ]]; then
            echo "   🎯 Recommended: Pi OS source installation"
            echo "   ⚠️  Compilation will take 45-90 minutes on Pi"
        else
            echo "   🎯 Recommended: Source installation with this script"
        fi
        echo "   📋 Command: sudo ./setup.sh"
    elif [ "$MEMORY_GB" -ge 2 ]; then
        echo "   ⚠️  Limited memory (${MEMORY_GB}GB) - compilation may be slow"
        echo "   🎯 Recommended: Docker installation for resource management"
        echo "   📝 Consider increasing swap space for compilation"
    else
        echo "   ❌ Low memory (${MEMORY_GB}GB) - compilation will likely fail"
        echo "   🎯 Strongly Recommended: Use pre-built Docker image"
        echo "   🛠️ Alternative: Cross-compile on more powerful system"
    fi
    
    echo "   🔌 Power Supply Requirements:"
    echo "      • Pi 4: 5V 3A minimum (official adapter recommended)"
    echo "      • Multiple RTL-SDR: May need powered USB hub"
    echo "      • Monitor power consumption during operation"
    echo
    
    echo "   🌡️ Thermal Management:"
    echo "      • Heatsink/fan recommended for continuous operation"
    echo "      • Monitor CPU temperature: vcgencmd measure_temp"
    echo "      • Consider case with active cooling"
    echo
    
    echo "   📚 Pi Guide: https://github.com/TrunkRecorder/trunk-recorder/blob/master/docs/Install/INSTALL-PI.md"
    echo
fi

# macOS specific
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🍎 macOS Installation:"
    echo "   🔧 Source Installation (Homebrew required):"
    echo "   📋 Commands:"
    echo "      brew install cmake boost curl gmp hackrf librtlsdr libsndfile"
    echo "      git clone https://github.com/robotastic/trunk-recorder.git"
    echo "      cd trunk-recorder && mkdir build && cd build"
    echo "      cmake .. && make"
    echo "   📚 macOS Guide: https://github.com/TrunkRecorder/trunk-recorder/blob/master/docs/Install/MAC.md"
    echo
fi

# Memory warnings
if [ "$MEMORY_MB" != "Unknown" ] && [ "$MEMORY_MB" -lt 2048 ]; then
    echo "⚠️  Memory Warning:"
    echo "   Your system has less than 2GB RAM"
    echo "   Source compilation may fail or be very slow"
    echo "   Consider using Docker or a pre-built package"
    echo
fi

# Ask user what they want to do
echo "🚀 What would you like to do?"
echo "1) Install from source using this script (Linux only)"
echo "2) Show Docker installation commands"
echo "3) Show manual installation links"
echo "4) Exit"
echo

while true; do
    read -p "Enter your choice (1-4): " choice
    case $choice in
        1)
            if [[ "$OSTYPE" == "linux-gnu"* ]]; then
                if [ "$EUID" -ne 0 ]; then
                    echo "Source installation requires root privileges."
                    echo "Please run: sudo $0"
                    exit 1
                fi
                
                # Install dependencies first if we know them
                get_dependencies
                if [[ -n $DEPS ]]; then
                    echo "Installing dependencies for $OS..."
                    echo "Running: $PKG_UPDATE"
                    eval "$PKG_UPDATE"
                    echo "Running: $PKG_INSTALL $DEPS"
                    eval "$PKG_INSTALL $DEPS"
                    echo "✓ Dependencies installed"
                    echo
                fi
                
                echo "Starting source installation..."
                echo "Please run: sudo ./setup.sh"
                echo "(This script only provides recommendations)"
            else
                echo "❌ Source installation script only supports Linux"
                echo "Please choose option 2 or 3 for your platform"
            fi
            ;;
        2)
            echo
            echo "🐳 Docker Installation & Setup:"
            echo
            
            # Check if Docker is already installed
            if [ "$DOCKER_AVAILABLE" = true ]; then
                echo "✅ Docker is already installed ($DOCKER_VERSION)"
            else
                echo "📦 Install Docker first:"
                case $DISTRO_ID in
                    ubuntu|debian)
                        echo "sudo apt update && sudo apt install -y docker.io"
                        echo "sudo systemctl start docker && sudo systemctl enable docker"
                        ;;
                    fedora)
                        echo "sudo dnf install -y docker"
                        echo "sudo systemctl start docker && sudo systemctl enable docker"
                        ;;
                    centos|rhel)
                        echo "sudo yum install -y docker"
                        echo "sudo systemctl start docker && sudo systemctl enable docker"
                        ;;
                    arch|manjaro)
                        echo "sudo pacman -S docker"
                        echo "sudo systemctl start docker && sudo systemctl enable docker"
                        ;;
                    opensuse*)
                        echo "sudo zypper install docker"
                        echo "sudo systemctl start docker && sudo systemctl enable docker"
                        ;;
                    macos)
                        echo "# Install Docker Desktop from: https://www.docker.com/products/docker-desktop"
                        ;;
                    *)
                        echo "# Install Docker for your distribution from: https://docs.docker.com/engine/install/"
                        ;;
                esac
                echo "sudo usermod -aG docker \$USER  # Add user to docker group"
                echo "# Log out and back in for group changes to take effect"
                echo
            fi
            
            echo "📁 Setup directories:"
            echo "mkdir -p ~/trunk-recorder/{config,recordings}"
            echo "cd ~/trunk-recorder"
            echo
            
            echo "📝 Create docker-compose.yml:"
            echo "cat > docker-compose.yml << 'COMPOSE_EOF'"
            echo "version: '3.8'"
            echo "services:"
            echo "  trunk-recorder:"
            echo "    image: trunkrecorder/trunk-recorder:latest"
            echo "    container_name: trunk-recorder"
            echo "    restart: unless-stopped"
            echo "    privileged: true  # Required for RTL-SDR access"
            echo "    volumes:"
            echo "      - ./config:/app/config"
            echo "      - ./recordings:/app/recordings"
            echo "      - /dev/bus/usb:/dev/bus/usb  # RTL-SDR USB access"
            echo "    environment:"
            echo "      - TZ=America/New_York  # Set your timezone"
            echo "    # Optional: expose web interface"
            echo "    # ports:"
            echo "    #   - \"3000:3000\""
            echo "COMPOSE_EOF"
            echo
            
            echo "⚙️ Create basic config.json:"
            echo "cat > config/config.json << 'CONFIG_EOF'"
            echo "{"
            echo "  \"ver\": 2,"
            echo "  \"sources\": ["
            echo "    {"
            echo "      \"center\": 851000000,"
            echo "      \"rate\": 2400000,"
            echo "      \"ppm\": 0,"
            echo "      \"gain\": 49,"
            echo "      \"digitalRecorders\": 5,"
            echo "      \"driver\": \"osmosdr\","
            echo "      \"device\": \"rtl=0\""
            echo "    }"
            echo "  ],"
            echo "  \"systems\": ["
            echo "    {"
            echo "      \"control_channels\": [851012500],"
            echo "      \"type\": \"p25\","
            echo "      \"shortName\": \"example\","
            echo "      \"talkgroupsFile\": \"/app/config/talkgroups.csv\""
            echo "    }"
            echo "  ],"
            echo "  \"captureDir\": \"/app/recordings\","
            echo "  \"logLevel\": \"info\""
            echo "}"
            echo "CONFIG_EOF"
            echo
            
            echo "🚀 Start with Docker Compose:"
            echo "docker-compose up -d"
            echo
            
            echo "🔍 Monitor logs:"
            echo "docker-compose logs -f trunk-recorder"
            echo
            
            echo "🛠️ Management commands:"
            echo "docker-compose stop     # Stop container"
            echo "docker-compose start    # Start container"
            echo "docker-compose restart  # Restart container"
            echo "docker-compose down     # Stop and remove container"
            echo "docker-compose pull && docker-compose up -d  # Update to latest image"
            echo
            
            echo "⚠️  Important Notes:"
            echo "   • Edit config/config.json with your system details"
            echo "   • Add talkgroups to config/talkgroups.csv"
            echo "   • RTL-SDR dongles must be connected before starting"
            echo "   • Container runs with privileged access for USB devices"
            echo "   • Recordings saved to ./recordings/ directory"
            echo
            
            echo "📚 Docker Guide: https://github.com/TrunkRecorder/trunk-recorder/blob/master/docs/Install/INSTALL-DOCKER.md"
            break
            ;;
        3)
            echo
            echo "📚 Manual Installation Guides:"
            echo
            echo "🐧 Linux: https://github.com/TrunkRecorder/trunk-recorder/blob/master/docs/Install/INSTALL-LINUX.md"
            echo "🍎 macOS: https://github.com/TrunkRecorder/trunk-recorder/blob/master/docs/Install/INSTALL-MAC.md"
            echo "🥧 Raspberry Pi: https://github.com/TrunkRecorder/trunk-recorder/blob/master/docs/Install/INSTALL-PI.md"
            echo "🐳 Docker: https://github.com/TrunkRecorder/trunk-recorder/blob/master/docs/Install/INSTALL-DOCKER.md"
            echo
            if [[ -n $DEPS ]]; then
                echo "📦 Dependencies for your system ($OS):"
                echo "   $PKG_UPDATE"
                echo "   $PKG_INSTALL $DEPS"
                echo
            fi
            echo "📖 Main Documentation: https://github.com/TrunkRecorder/trunk-recorder"
            break
            ;;
        4)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Please enter a valid choice (1-4)"
            ;;
    esac
done