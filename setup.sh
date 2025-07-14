#!/bin/bash

# =============================================================================
# macOS Setup Script - Main Entry Point
# Modern, modular macOS development environment setup
# =============================================================================

# Script directory and paths
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LIB_DIR="$SCRIPT_DIR/lib"
readonly MODULES_DIR="$SCRIPT_DIR/modules"

# Global variables

# Simple .env loading function for git setup
load_env_file() {
    if [[ -f ".env" ]]; then
        set -o allexport
        source .env 2>/dev/null || true
        set +o allexport
        return 0
    fi
    return 1
}

# =============================================================================
# Load Dependencies
# =============================================================================

# Load utility functions first
if [[ -f "$LIB_DIR/utils.sh" ]]; then
    source "$LIB_DIR/utils.sh"
else
    echo "❌ Error: Required utility library not found: $LIB_DIR/utils.sh"
    exit 1
fi



# Load package management
if [[ -f "$LIB_DIR/packages.sh" ]]; then
    source "$LIB_DIR/packages.sh"
else
    log_error "Required package library not found: $LIB_DIR/packages.sh"
    exit 1
fi

# Load modules
for module in "$MODULES_DIR"/*.sh; do
    if [[ -f "$module" ]]; then
        source "$module"
        log_debug "Loaded module: $(basename "$module")"
    fi
done

# =============================================================================
# Script Information
# =============================================================================

SETUP_SCRIPT_VERSION="2.0.0"
SETUP_SCRIPT_NAME="macOS Setup"

# =============================================================================
# Help and Usage
# =============================================================================

show_help() {
    cat << EOF
$SETUP_SCRIPT_NAME v$SETUP_SCRIPT_VERSION
==============================

A modern, modular script for setting up a complete macOS development environment.

USAGE:
    $0 [OPTIONS] [COMMAND]

OPTIONS:
    -h, --help          Show this help message
    -v, --version       Show version information
    --debug             Enable debug output

COMMANDS:
    menu                Show interactive menu (default)
    homebrew            Install and configure Homebrew
    packages            Manage package installation
    system              Configure system settings
    git                 Setup Git configuration
    themes              Install Catppuccin themes for various applications
    backup              Export and backup configuration files
    all                 Install everything with recommended settings

EXAMPLES:
    $0                  # Start interactive menu
    $0 homebrew         # Install Homebrew only
    $0 packages         # Show package management menu
    $0 themes           # Show themes installation menu

FILES:
    .env               Environment variables (optional)

For more information, visit: https://github.com/damianjankowski/setup-macos
EOF
}

show_version() {
    echo "$SETUP_SCRIPT_NAME v$SETUP_SCRIPT_VERSION"
}

# =============================================================================
# Command Line Argument Parsing
# =============================================================================

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                show_version
                exit 0
                ;;
            --debug)
                DEBUG=1
                shift
                ;;
            menu|homebrew|packages|system|git|themes|backup|all)
                COMMAND="$1"
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
}

# =============================================================================
# Installation Commands
# =============================================================================

# Install essential packages (like backup approach)
install_essentials() {
    log_info "Installing Essential Packages"
    echo "============================="
    echo ""
    echo "This will install essential development tools:"
    echo "• git - Version control system"
    echo "• curl - Data transfer tool" 
    echo "• wget - File retriever"
    echo "• jq - JSON processor"
    echo "• tree - Directory structure display"
    echo ""
    
    if confirm "Install these essential packages?" "y"; then
        # Install Homebrew first if needed
        install_homebrew
        
        # Install essentials using the packages module
        source "$LIB_DIR/packages.sh"
        init_packages
        
        log_info "Installing essential packages..."
        install_packages "${ESSENTIALS_PACKAGES[@]}"
        
        log_success "Essential packages installed successfully!"
        
        # Wait for user to read the output
        echo
        read -p "Press Enter to continue..." -r
    else
        log_info "Essential package installation cancelled."
    fi
}





# =============================================================================
# System Status Report
# =============================================================================

# Show system status report
show_status_report() {
    clear
    log_info "System Status Report"
    echo "===================="
    echo ""
    
    # System Information
    echo "🖥️  System Information:"
    echo "   macOS: $(sw_vers -productVersion) ($(sw_vers -productName))"
    echo "   Architecture: $(uname -m)"
    echo "   Processor: $(sysctl -n machdep.cpu.brand_string)"
    echo "   Cores: $(sysctl -n hw.ncpu) CPU cores"
    echo "   Memory: $(echo "scale=1; $(sysctl -n hw.memsize) / 1073741824" | bc 2>/dev/null || echo "$(( $(sysctl -n hw.memsize) / 1073741824 ))")GB RAM"
    echo "   Uptime: $(uptime | sed 's/.*up //' | sed 's/, [0-9]* users.*//')"
    
    # Disk space
    local disk_info=$(df -h / | tail -1)
    local disk_used=$(echo "$disk_info" | awk '{print $3}')
    local disk_avail=$(echo "$disk_info" | awk '{print $4}')
    local disk_percent=$(echo "$disk_info" | awk '{print $5}')
    echo "   Disk Usage: $disk_used used, $disk_avail available ($disk_percent full)"
    

    echo ""
    
    # Homebrew Status
    echo "🍺 Homebrew Status:"
    if command -v brew &> /dev/null; then
        echo "   ✅ Installed at $(brew --prefix)"
        echo "   Version: $(brew --version | head -n1)"
        local formulae_count=$(brew list --formula 2>/dev/null | wc -l | tr -d ' ')
        local casks_count=$(brew list --cask 2>/dev/null | wc -l | tr -d ' ')
        echo "   Packages: $formulae_count formulae, $casks_count casks"
    else
        echo "   ❌ Not installed"
    fi
    echo ""
    
    # Shell Status  
    echo "🐚 Shell Status:"
    echo "   Current: $SHELL"
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        echo "   Oh My Zsh: ✅ Installed"
    else
        echo "   Oh My Zsh: ❌ Not installed"
    fi
    echo ""
    
    # Git Status
    echo "📝 Git Status:"
    if command -v git &> /dev/null; then
        echo "   ✅ $(git --version)"
        local git_user=$(git config user.name 2>/dev/null || echo "Not configured")
        local git_email=$(git config user.email 2>/dev/null || echo "Not configured")
        echo "   Identity: $git_user <$git_email>"
        
        if [[ -f "$HOME/.gitconfig-personal" ]] && [[ -f "$HOME/.gitconfig-work" ]]; then
            echo "   Multi-identity: ✅ Configured"
        else
            echo "   Multi-identity: ❌ Not configured"
        fi
    else
        echo "   ❌ Not installed"
    fi
    echo ""
    
    # Development Tools
    echo "🛠️  Development Tools:"
    check_tool_status "node" "node --version"
    check_tool_status "npm" "npm --version"
    check_tool_status "nvm" "nvm --version"
    check_tool_status "python3" "python3 --version"
    check_tool_status "pip3" "pip3 --version | head -n1"
    check_tool_status "pyenv" "pyenv --version"
    check_tool_status "docker" "docker --version"
    check_tool_status "docker-compose" "docker-compose --version"
    check_tool_status "kubectl" "kubectl version --client --short 2>/dev/null || echo 'installed'"
    check_tool_status "terraform" "terraform --version | head -n1"
    check_tool_status "aws" "aws --version"
    check_tool_status "gcloud" "gcloud --version | head -n1"
    echo ""
    
    # Network Information
    echo "🌐 Network Information:"
    local local_ip=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -n1)
    echo "   Local IP: ${local_ip:-Not available}"
    
    # Check if connected to internet
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        echo "   Internet: ✅ Connected"
    else
        echo "   Internet: ❌ Not connected"
    fi
    echo ""
    
    # Development Environment
    echo "🔨 Development Environment:"
    if xcode-select -p >/dev/null 2>&1; then
        echo "   ✅ Xcode Command Line Tools: Installed"
        local xcode_version=$(xcodebuild -version 2>/dev/null | head -n1)
        [[ -n "$xcode_version" ]] && echo "   Xcode Version: $xcode_version"
    else
        echo "   ❌ Xcode Command Line Tools: Not installed"
    fi
    
    # Check for common development directories
    [[ -d ~/src ]] && echo "   📁 ~/src: $(ls ~/src 2>/dev/null | wc -l | tr -d ' ') projects"
    [[ -d ~/repo ]] && echo "   📁 ~/repo: $(ls ~/repo 2>/dev/null | wc -l | tr -d ' ') projects"
    
    # Java version if available
    if command -v java >/dev/null 2>&1; then
        local java_version=$(java -version 2>&1 | head -n1 | grep -o '"[^"]*"' | tr -d '"' 2>/dev/null)
        if [[ -n "$java_version" && "$java_version" != *"operation couldn't be completed"* ]]; then
            echo "   ☕ Java: $java_version"
        fi
    fi
    echo ""

    # Environment Information
    echo "⚙️  Environment:"
    echo "   Setup version: $SETUP_SCRIPT_VERSION"
    [[ -n "${HOMEBREW_PREFIX:-}" ]] && echo "   HOMEBREW_PREFIX: $HOMEBREW_PREFIX"
    [[ -n "${EDITOR:-}" ]] && echo "   EDITOR: $EDITOR"
    echo ""
    
    read -p "Press Enter to continue..." -r
}

# =============================================================================
# Main Menu System
# =============================================================================

show_main_menu() {
    while true; do
        clear
        echo "┌───────────────────────────────────┐"
        echo "          $SETUP_SCRIPT_NAME v$SETUP_SCRIPT_VERSION      "
        echo "└───────────────────────────────────┘"
        echo
        
        # Show system information
        echo "System Information:"
        echo "  macOS: $(get_macos_version)"
        echo "  Architecture: $(uname -m)"
        
        if is_brew_installed; then
            echo "  Homebrew: ✅ Installed"
        else
            echo "  Homebrew: ❌ Not installed"
        fi
        
        echo
        echo "Main Menu:"
        echo "=========="
        echo " 1) 🍺 Homebrew Management"
        echo " 2) 📦 Package Installation"
        echo " 3) 🛠️  System Configuration"
        echo " 4) 🔧 Git Configuration"
        echo " 5) 🎨 Themes Installation"
        echo " 6) 📦 Configuration Backup"
        echo " 7) 🚀 Install Essentials"
        echo " 8) 📊 System Status Report"
        echo " 0) 🚪 Exit"
        
        echo
        local choice=$(get_input "Enter your choice" "0")
        
        case "$choice" in
            "1") show_homebrew_menu ;;
            "2") show_packages_menu ;;
            "3") show_system_menu ;;
            "4") show_git_menu ;;
            "5") show_themes_menu ;;
            "6") show_backup_menu ;;
            "7") install_essentials ;;
            "8") show_status_report ;;
            "0") log_info "macOS Setup exiting!"; exit 0 ;;
            *) log_error "Invalid choice: $choice" ;;
        esac
    done
}

# Helper function to check tool status
check_tool_status() {
    local tool="$1"
    local version_cmd="$2"
    
    # Special handling for nvm (it's a shell function, not a binary)
    if [[ "$tool" == "nvm" ]]; then
        # Try multiple ways to detect nvm
        if command -v nvm &> /dev/null; then
            local nvm_version=$(nvm --version 2>/dev/null || echo "installed")
            echo "   ✅ $tool: $nvm_version"
        elif [[ -n "${NVM_DIR:-}" ]] && [[ -s "$NVM_DIR/nvm.sh" ]]; then
            local nvm_version=$(source "$NVM_DIR/nvm.sh" && nvm --version 2>/dev/null || echo "installed")
            echo "   ✅ $tool: $nvm_version"
        elif [[ -f "$HOME/.nvm/nvm.sh" ]]; then
            local nvm_version=$(source "$HOME/.nvm/nvm.sh" && nvm --version 2>/dev/null || echo "installed")
            echo "   ✅ $tool: $nvm_version"
        else
            echo "   ❌ $tool: Not installed"
        fi
        return
    fi
    
    # Special handling for node and npm (might be managed by nvm)
    if [[ "$tool" == "node" || "$tool" == "npm" ]]; then
        # First try standard detection
        if command -v "$tool" &> /dev/null; then
            local version_output=$(eval "$version_cmd" 2>/dev/null)
            if [[ -n "$version_output" ]]; then
                echo "   ✅ $tool: $version_output"
                return
            fi
        fi
        
        # If not found, try through nvm
        if command -v nvm &> /dev/null; then
            local version_output=$(eval "$version_cmd" 2>/dev/null)
            if [[ -n "$version_output" ]]; then
                echo "   ✅ $tool: $version_output (via nvm)"
                return
            fi
        elif [[ -n "${NVM_DIR:-}" ]] && [[ -s "$NVM_DIR/nvm.sh" ]]; then
            local version_output=$(source "$NVM_DIR/nvm.sh" && eval "$version_cmd" 2>/dev/null)
            if [[ -n "$version_output" ]]; then
                echo "   ✅ $tool: $version_output (via nvm)"
                return
            fi
        elif [[ -f "$HOME/.nvm/nvm.sh" ]]; then
            local version_output=$(source "$HOME/.nvm/nvm.sh" && eval "$version_cmd" 2>/dev/null)
            if [[ -n "$version_output" ]]; then
                echo "   ✅ $tool: $version_output (via nvm)"
                return
            fi
        fi
        
        echo "   ❌ $tool: Not installed"
        return
    fi
    
    # For other tools, check if command exists
    if command -v "$tool" &> /dev/null; then
        local version_output=$(eval "$version_cmd" 2>/dev/null)
        if [[ -n "$version_output" ]]; then
            echo "   ✅ $tool: $version_output"
        else
            echo "   ✅ $tool: installed"
        fi
    else
        echo "   ❌ $tool: Not installed"
    fi
}

# =============================================================================
# Initialization and Main
# =============================================================================

# Initialize the application
initialize() {
    # Enable strict mode for better error handling if needed
    
    # Initialize utilities and packages
    init_utils
    init_packages
    
    # Load environment variables if available (for git setup)
    load_env_file
    
    log_debug "Application initialized successfully"
}

# Main function
main() {
    # Parse command line arguments
    parse_arguments "$@"
    
    # Initialize application
    initialize
    
    # Execute command or show menu
    case "${COMMAND:-menu}" in
        "menu")
            show_main_menu
            ;;
        "homebrew")
            show_homebrew_menu
            ;;
        "packages")
            show_packages_menu
            ;;
        "system")
            show_system_menu
            ;;
        "git")
            show_git_menu
            ;;
        "themes")
            show_themes_menu
            ;;
        "backup")
            show_backup_menu
            ;;
        "all")
            install_essentials
            ;;
        *)
            log_error "Unknown command: ${COMMAND}"
            show_help
            exit 1
            ;;
    esac
}

# =============================================================================
# Script Entry Point
# =============================================================================

# Only run main if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 