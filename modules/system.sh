#!/bin/bash

# =============================================================================
# System Configuration Module
# Oh My Zsh, Rosetta, and system-level configurations
# =============================================================================

# =============================================================================
# Oh My Zsh
# =============================================================================

# Install Oh My Zsh
install_ohmyzsh() {
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        log_success "Oh My Zsh is already installed"
        return 0
    fi
    
    log_info "Installing Oh My Zsh..."

    
    # Backup existing .zshrc if it exists
    if [[ -f "$HOME/.zshrc" ]]; then
        backup_file "$HOME/.zshrc"
    fi
    
    # Download and install Oh My Zsh
    local install_url="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
    
    if ! validate_url "$install_url"; then
        log_error "Invalid Oh My Zsh installation URL"
        return 1
    fi
    
    # Install without switching shell automatically
    export RUNZSH=no
    export KEEP_ZSHRC=yes
    
    if sh -c "$(curl -fsSL "$install_url")" 2>/dev/null; then
        log_success "Oh My Zsh installed successfully"
        configure_ohmyzsh
    else
        log_error "Oh My Zsh installation failed"
        return 1
    fi
}

# =============================================================================
# Rosetta Installation (Apple Silicon Macs)
# =============================================================================

# Install Rosetta 2 for Apple Silicon Macs
install_rosetta() {
    # Only relevant for Apple Silicon Macs
    if ! is_apple_silicon; then
        log_info "Rosetta is not needed on Intel Macs"
        return 0
    fi
    
    # Check if Rosetta is already installed
    if [[ -e /usr/libexec/rosetta ]]; then
        log_success "Rosetta 2 is already installed"
        return 0
    fi
    
    log_info "Installing Rosetta 2 for Apple Silicon compatibility..."

    
    # Install Rosetta 2
    if /usr/sbin/softwareupdate --install-rosetta --agree-to-license; then
        log_success "Rosetta 2 installed successfully"
    else
        log_error "Rosetta 2 installation failed"
        return 1
    fi
}

# Check Rosetta status
check_rosetta_status() {
    if ! is_apple_silicon; then
        echo "Rosetta Status: Not applicable (Intel Mac)"
        return 0
    fi
    
    echo "Rosetta Status:"
    if [[ -e /usr/libexec/rosetta ]]; then
        echo "  ✅ Installed"
        
        # Check if any Intel processes are running
        local intel_processes=$(ps aux | grep -c "i386\|x86_64" | grep -v grep || echo "0")
        echo "  Intel processes running: $intel_processes"
    else
        echo "  ❌ Not installed"
    fi
}



# =============================================================================
# System Configuration Menu
# =============================================================================

show_system_menu() {
    while true; do
        echo
        log_info "System Configuration"
        echo "===================="
        
        echo "Current Status:"
        if [[ -d "$HOME/.oh-my-zsh" ]]; then
            echo "  ✅ Oh My Zsh installed"
        else
            echo "  ❌ Oh My Zsh not installed"
        fi
        
        check_rosetta_status | sed 's/^/  /'
        
        echo
        echo "1) Install Oh My Zsh"
        echo "2) Install Rosetta 2 (Apple Silicon)"
        echo "3) Configure Finder Settings"
        echo "4) Keyboard Remapping"
        echo "0) Back to main menu"
        
        local choice=$(get_input "Enter your choice" "0")
        
        case "$choice" in
            "1") install_ohmyzsh ;;
            "2") install_rosetta ;;
            "3") configure_finder_settings ;;
            "4") remap_keyboard ;;
            "0") break ;;
            *) log_error "Invalid choice: $choice" ;;
        esac
        
        if [[ "$choice" != "0" ]]; then
            echo
            read -p "Press Enter to continue..." -r
        fi
    done
}

# =============================================================================
# Finder Configuration
# =============================================================================

configure_finder_settings() {
    log_info "Configuring Finder settings..."
    
    # 1. Show hidden files in Finder
    defaults write com.apple.finder AppleShowAllFiles -bool true
    log_info "✅ Show hidden files in Finder"
    
    # 2. Set screenshot location to Desktop
    defaults write com.apple.screencapture location -string "${HOME}/Desktop"
    log_info "✅ Save screenshots to Desktop"
    
    # 3. Show status bar and path bar in Finder
    defaults write com.apple.finder ShowStatusBar -bool true
    defaults write com.apple.finder ShowPathbar -bool true
    log_info "✅ Show status bar and path bar in Finder"
    
    killall Finder 2>/dev/null || true
    
    log_success "macOS settings configured successfully!"
    log_info "Finder has been restarted to apply changes"
}

# =============================================================================
# Keyboard Remapping
# =============================================================================

remap_keyboard() {
    log_info "Starting keyboard remapping tool..."
    
    local current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local script_dir="$(dirname "$current_dir")"
    local script_path="$script_dir/remap_keyboard.sh"
    
    if [[ -f "$script_path" ]]; then
        chmod +x "$script_path"
        "$script_path"
    else
        log_error "Keyboard remapping script not found: $script_path"
        log_info "Please ensure remap_keyboard.sh is in the same directory as setup.sh"
        
        if confirm "Would you like basic CMD/CTRL swap instructions instead?" "y"; then
            echo ""
            echo "Basic Key Remapping Instructions:"
            echo "================================="
            echo "1. Go to System Preferences → Keyboard → Modifier Keys"
            echo "2. Swap Command and Control keys for external keyboards"
            echo "3. Or use Karabiner-Elements for advanced remapping"
            echo ""
        fi
    fi
} 