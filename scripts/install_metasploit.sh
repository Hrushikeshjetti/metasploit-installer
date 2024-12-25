#!/bin/bash

# Metasploit Framework Multi-OS Installer
# Enhanced version with robust error handling and security checks

# Logging function
log() {
    local log_level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    
    # Color codes
    local RED='\033[0;31m'
    local GREEN='\033[0;32m'
    local YELLOW='\033[0;33m'
    local NC='\033[0m' # No Color

    case "$log_level" in
        "INFO")
            echo -e "${GREEN}[INFO ${timestamp}]${NC} $message"
            ;;
        "WARN")
            echo -e "${YELLOW}[WARN ${timestamp}]${NC} $message" >&2
            ;;
        "ERROR")
            echo -e "${RED}[ERROR ${timestamp}]${NC} $message" >&2
            ;;
        *)
            echo -e "[${log_level} ${timestamp}] $message"
            ;;
    esac
}

# Security and Prerequisite Checks
pre_install_checks() {
    # Check for root/sudo access
    if [[ $EUID -ne 0 ]]; then
        log "ERROR" "This script must be run with sudo privileges"
        exit 1
    fi

    # Check internet connectivity
    if ! ping -c 3 8.8.8.8 &> /dev/null; then
        log "ERROR" "No internet connection detected. Please check your network."
        exit 1
    fi

    # Check available disk space
    local min_space_mb=2048
    local available_space
    available_space=$(df -m / | awk 'NR==2 {print $4}')
    
    if [[ $available_space -lt $min_space_mb ]]; then
        log "ERROR" "Insufficient disk space. Requires at least ${min_space_mb}MB"
        exit 1
    fi
}

# Enhanced OS Detection
detect_os() {
    local os_type=""
    local os_version=""

    # Detect OS using multiple methods
    if [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        source /etc/os-release
        os_type="${ID}"
        os_version="${VERSION_ID}"
    elif [[ "$(uname -s)" == "Darwin" ]]; then
        os_type="macos"
        os_version=$(sw_vers -productVersion)
    elif [[ "$(uname -o)" == "Android" ]]; then
        os_type="android"
        os_version=$(getprop ro.build.version.release)
    else
        log "ERROR" "Unsupported operating system"
        exit 1
    fi

    echo "${os_type}:${os_version}"
}

# Linux Installation (Enhanced)
install_linux() {
    local distro="$1"
    local version="$2"

    log "INFO" "Installing Metasploit Framework on Linux ${distro} ${version}"

    # Distro-specific package managers and dependencies
    case "$distro" in
        "ubuntu"|"debian")
            apt-get update
            apt-get install -y \
                curl \
                wget \
                gnupg \
                software-properties-common \
                apt-transport-https

            # Add Metasploit repository with error handling
            wget -q https://apt.metasploit.com/metasploit-framework.gpg.key -O- | apt-key add - || {
                log "ERROR" "Failed to add Metasploit GPG key"
                exit 1
            }
            
            add-apt-repository "deb https://apt.metasploit.com/ metasploit-framework main"
            apt-get update
            apt-get install -y metasploit-framework
            ;;
        "fedora"|"centos"|"rhel")
            dnf install -y epel-release
            dnf install -y metasploit-framework
            ;;
        *)
            log "ERROR" "Unsupported Linux distribution"
            exit 1
            ;;
    esac
}

# macOS Installation (Enhanced)
install_macos() {
    local version="$1"

    log "INFO" "Installing Metasploit Framework on macOS ${version}"

    # Check Homebrew installation
    if ! command -v brew &> /dev/null; then
        log "INFO" "Homebrew not found. Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    # Install dependencies and Metasploit
    brew update
    brew tap homebrew/cask
    brew install metasploit
}

# Android Installation (Enhanced)
install_android() {
    local version="$1"

    log "INFO" "Installing Metasploit Framework on Android ${version}"

    # Ensure Termux is available
    if ! command -v pkg &> /dev/null; then
        log "ERROR" "Termux not detected. Please install Termux from F-Droid or Google Play Store."
        exit 1
    fi

    # Update and install dependencies
    pkg update -y
    pkg upgrade -y
    pkg install -y \
        unstable-repo \
        ruby \
        wget \
        curl \
        git

    # Install Metasploit via gem with error handling
    gem install metasploit-framework || {
        log "ERROR" "Failed to install Metasploit Framework via gem"
        exit 1
    }
}

# Verify Installation
verify_installation() {
    if command -v msfconsole &> /dev/null; then
        log "INFO" "Metasploit Framework successfully installed"
        msfconsole --version
    else
        log "ERROR" "Installation verification failed"
        exit 1
    fi
}

# Main Execution
main() {
    # Ethical Use Warning
    log "WARN" "IMPORTANT: This tool is for AUTHORIZED security testing ONLY"
    log "WARN" "Unauthorized use is STRICTLY PROHIBITED"

    # Prerequisite checks
    pre_install_checks

    # Detect OS
    IFS=':' read -r os_type os_version <<< "$(detect_os)"

    # OS-specific installation
    case "$os_type" in
        "ubuntu"|"debian"|"fedora"|"centos"|"rhel")
            install_linux "$os_type" "$os_version"
            ;;
        "macos")
            install_macos "$os_version"
            ;;
        "android")
            install_android "$os_version"
            ;;
        *)
            log "ERROR" "Unsupported OS: ${os_type}"
            exit 1
            ;;
    esac

    # Final verification
    verify_installation

    log "INFO" "Metasploit Framework installation completed successfully"
}

# Run the main function
main
