#!/bin/bash

install_ohmyzsh() {
    if [[ -d "$OH_MY_ZSH_DIR" ]]; then
        log_success "Oh My Zsh already installed"
        return 0
    fi
    
    log_info "Installing Oh My Zsh..."
    
    [[ -f "$ZSHRC_PATH" ]] && backup_file "$ZSHRC_PATH"
    
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

defaults_finder_show_hidden_files() { defaults write com.apple.finder AppleShowAllFiles -bool true; log_info "✅ Show hidden files"; }
defaults_finder_screenshot_type() { defaults write com.apple.screencapture type "jpg"; log_info "✅ Screenshot type set to jpg"; }
defaults_finder_screenshot_location() { defaults write com.apple.screencapture location -string "${HOME}/Desktop"; log_info "✅ Screenshots to Desktop"; }
defaults_finder_show_status_path_bars() { defaults write com.apple.finder ShowStatusBar -bool true; defaults write com.apple.finder ShowPathbar -bool true; log_info "✅ Show status and path bars"; }
defaults_finder_list_view() { defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"; log_info "✅ Use list view by default"; }
defaults_finder_folders_first() { defaults write com.apple.finder _FXSortFoldersFirst -bool true; log_info "✅ Keep folders on top when sorting by name"; }
defaults_finder_search_current() { defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"; log_info "✅ Search the current folder by default"; }
defaults_finder_disable_ext_warning() { defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false; log_info "✅ Disable the warning when changing a file extension"; }

configure_finder_settings_menu() {
    if ! command -v dialog &>/dev/null; then
        echo "\n'dialog' utility is required for this menu."
        echo "Install it with: brew install dialog"
        read -p "Press Enter to return..."
        return 1
    fi
    local tmpfile=$(mktemp)
    local options=( \
        1 "Show hidden files" off \
        2 "Set screenshot type to jpg" off \
        3 "Set screenshot location to Desktop" off \
        4 "Show status and path bars" off \
        5 "Use list view by default" off \
        6 "Keep folders on top when sorting by name" off \
        7 "Search the current folder by default" off \
        8 "Disable warning when changing a file extension" off \
    )
    dialog --clear \
        --backtitle "Finder Settings" \
        --title "Configure Finder Settings" \
        --checklist "Select Finder settings to enable:" 20 70 8 \
        "${options[@]}" 2> "$tmpfile"
    local exit_status=$?
    clear
    if [[ $exit_status -ne 0 ]]; then
        log_info "Cancelled Finder settings configuration."
        rm -f "$tmpfile"
        return 0
    fi
    local choices=$(<"$tmpfile")
    rm -f "$tmpfile"
    for choice in $choices; do
        case $choice in
            "1") defaults_finder_show_hidden_files ;;
            "2") defaults_finder_screenshot_type ;;
            "3") defaults_finder_screenshot_location ;;
            "4") defaults_finder_show_status_path_bars ;;
            "5") defaults_finder_list_view ;;
            "6") defaults_finder_folders_first ;;
            "7") defaults_finder_search_current ;;
            "8") defaults_finder_disable_ext_warning ;;
        esac
    done
    killall Finder 2>/dev/null || true
    log_success "Selected Finder settings configured!"
    log_info "Finder restarted"
}

remap_keyboard() {
    log_info "Starting keyboard remapping..."
    
    local script_path="$(dirname "${BASH_SOURCE[0]}")/remap_keyboard.sh"
    
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
    local ssh_dir="$SSH_DIR"
    local ssh_config="$ssh_dir/config"

    [[ ! -d "$ssh_dir" ]] && { mkdir -p "$ssh_dir"; chmod 700 "$ssh_dir"; }
    [[ -f "$ssh_config" ]] && backup_file "$ssh_config"
    [[ ! -f "$ssh_config" ]] && { touch "$ssh_config"; chmod 600 "$ssh_config"; }

    local changes=false

    # General 1Password SSH agent
    if ! grep -q "Host \*" "$ssh_config" || ! grep -A 1 "Host \*" "$ssh_config" | grep -q "IdentityAgent.*1password"; then
        cat >> "$ssh_config" <<EOF

Host *
  IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
EOF
        log_info "Added 1Password SSH agent configuration"
        changes=true
    fi

    # GitHub SSH
    if ! grep -q "Host github.com" "$ssh_config"; then
        cat >> "$ssh_config" <<EOF

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
        [[ -d "$OH_MY_ZSH_DIR" ]] && echo "  ✅ Oh My Zsh" || echo "  ❌ Oh My Zsh"
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
            3) configure_finder_settings_menu ;;
            4) remap_keyboard ;;
            5) configure_1password_ssh ;;
            0) break ;;
            *) log_error "Invalid choice" ;;
        esac
        
        [[ "$choice" != "0" ]] && { echo; read -p "Press Enter to continue..."; }
    done
} 