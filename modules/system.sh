#!/bin/bash

# System configuration module

install_ohmyzsh() {
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        log_success "Oh My Zsh already installed"
        return 0
    fi
    
    log_info "Installing Oh My Zsh..."
    
    # Backup existing .zshrc
    [[ -f "$HOME/.zshrc" ]] && backup_file "$HOME/.zshrc"
    
    # Install Oh My Zsh
    local url="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
    
    export RUNZSH=no
    export KEEP_ZSHRC=yes
    
    if sh -c "$(curl -fsSL "$url")" 2>/dev/null; then
        log_success "Oh My Zsh installed"
    else
        log_error "Oh My Zsh installation failed"
        return 1
    fi
}

install_rosetta() {
    if ! is_apple_silicon; then
        log_info "Rosetta not needed on Intel Macs"
        return 0
    fi
    
    if [[ -e /usr/libexec/rosetta ]]; then
        log_success "Rosetta 2 already installed"
        return 0
    fi
    
    log_info "Installing Rosetta 2..."
    
    if /usr/sbin/softwareupdate --install-rosetta --agree-to-license; then
        log_success "Rosetta 2 installed"
    else
        log_error "Rosetta 2 installation failed"
        return 1
    fi
}

check_rosetta_status() {
    if ! is_apple_silicon; then
        echo "Rosetta: Not applicable (Intel Mac)"
        return 0
    fi
    
    if [[ -e /usr/libexec/rosetta ]]; then
        echo "Rosetta: ✅ Installed"
    else
        echo "Rosetta: ❌ Not installed"
    fi
}

configure_finder_settings() {
    log_info "Configuring Finder settings..."
    
    # Show hidden files
    defaults write com.apple.finder AppleShowAllFiles -bool true
    log_info "✅ Show hidden files"
    
    # Screenshot location to Desktop
    defaults write com.apple.screencapture location -string "${HOME}/Desktop"
    log_info "✅ Screenshots to Desktop"
    
    # Show status and path bars
    defaults write com.apple.finder ShowStatusBar -bool true
    defaults write com.apple.finder ShowPathbar -bool true
    log_info "✅ Show status and path bars"
    
    killall Finder 2>/dev/null || true
    
    log_success "macOS settings configured!"
    log_info "Finder restarted"
}

remap_keyboard() {
    log_info "Starting keyboard remapping..."
    
    local script_path="$(dirname "$(dirname "${BASH_SOURCE[0]}")")/remap_keyboard.sh"
    
    if [[ -f "$script_path" ]]; then
        chmod +x "$script_path"
        "$script_path"
    else
        log_error "Keyboard remapping script not found: $script_path"
        
        if confirm "Show basic remapping instructions?" "y"; then
            echo
            echo "Basic Key Remapping:"
            echo "1. System Preferences → Keyboard → Modifier Keys"
            echo "2. Swap Command and Control for external keyboards"
            echo "3. Or use Karabiner-Elements for advanced remapping"
        fi
    fi
}

configure_1password_ssh() {
    local ssh_dir="$HOME/.ssh"
    local ssh_config="$ssh_dir/config"

    [[ ! -d "$ssh_dir" ]] && { mkdir -p "$ssh_dir"; chmod 700 "$ssh_dir"; }
    [[ -f "$ssh_config" ]] && backup_file "$ssh_config"
    [[ ! -f "$ssh_config" ]] && { touch "$ssh_config"; chmod 600 "$ssh_config"; }

    local changes=false

    # General 1Password SSH agent
    if ! grep -q "Host \*" "$ssh_config" || ! grep -A 1 "Host \*" "$ssh_config" | grep -q "IdentityAgent.*1password"; then
        cat >> "$ssh_config" <<EOF

# 1Password SSH Agent
Host *
  IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
EOF
        log_info "Added 1Password SSH agent configuration"
        changes=true
    fi

    # GitHub SSH
    if ! grep -q "Host github.com" "$ssh_config"; then
        cat >> "$ssh_config" <<EOF

# GitHub SSH
Host github.com
  HostName github.com
  User git
  IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
EOF
        log_info "Added GitHub SSH configuration"
        changes=true
    fi

    # GitLab SSH
    if ! grep -q "Host gitlab.com" "$ssh_config"; then
        cat >> "$ssh_config" <<EOF

# GitLab SSH
Host gitlab.com
  HostName gitlab.com
  User git
  IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
EOF
        log_info "Added GitLab SSH configuration"
        changes=true
    fi

    if [[ "$changes" == true ]]; then
        log_success "1Password SSH agent configured in $ssh_config"
    else
        log_success "1Password SSH agent already configured"
    fi

    chmod 600 "$ssh_config"
}

show_system_menu() {
    while true; do
        echo
        log_info "System Configuration"
        
        echo "Current Status:"
        [[ -d "$HOME/.oh-my-zsh" ]] && echo "  ✅ Oh My Zsh" || echo "  ❌ Oh My Zsh"
        check_rosetta_status | sed 's/^/  /'
        
        echo
        echo "1) Install Oh My Zsh"
        echo "2) Install Rosetta 2 (Apple Silicon)"
        echo "3) Configure Finder settings"
        echo "4) Keyboard remapping"
        echo "5) Configure 1Password SSH"
        echo "0) Back"
        
        read -p "Choice [0-5]: " choice
        
        case "$choice" in
            1) install_ohmyzsh ;;
            2) install_rosetta ;;
            3) configure_finder_settings ;;
            4) remap_keyboard ;;
            5) configure_1password_ssh ;;
            0) break ;;
            *) log_error "Invalid choice" ;;
        esac
        
        [[ "$choice" != "0" ]] && { echo; read -p "Press Enter to continue..."; }
    done
} 