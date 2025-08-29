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

is_rosetta_installed() {
    pkgutil --pkg-info com.apple.pkg.RosettaUpdateAuto &>/dev/null
}

install_rosetta() {
    if ! is_apple_silicon; then
        log_info "Rosetta not needed on Intel Macs"
        return 0
    fi
    
    if is_rosetta_installed; then
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
    
    if is_rosetta_installed; then
        echo "Rosetta: ✅ Installed"
    else
        echo "Rosetta: ❌ Not installed"
    fi
}

# Finder settings configuration array
# Format: "id|type|domain|key|configure_value|default_value|configure_desc|default_desc"
declare -a FINDER_SETTINGS=(
	"1|bool|com.apple.finder|AppleShowAllFiles|true|false|Show hidden files|Hide hidden files"
	"2|string|com.apple.screencapture|type|jpg|png|Set screenshot type to jpg|Set screenshot type to png"
	"3|location|com.apple.screencapture|location|${HOME}/Desktop||Set screenshot location to Desktop|Reset screenshot location to default"
	"4|bool|com.apple.finder|ShowStatusBar|true|false|Show status bar|Hide status bar"
	"5|bool|com.apple.finder|ShowPathbar|true|false|Show path bar|Hide path bar"
	"6|string|com.apple.finder|FXPreferredViewStyle|Nlsv|icnv|Use list view by default|Use icon view by default"
	"7|bool|com.apple.finder|_FXSortFoldersFirst|true|false|Keep folders on top when sorting by name|Mix folders and files when sorting"
	"8|string|com.apple.finder|FXDefaultSearchScope|SCcf|SCev|Search the current folder by default|Search everywhere by default"
	"9|bool|com.apple.finder|FXEnableExtensionChangeWarning|false|true|Disable warning when changing a file extension|Enable warning when changing a file extension"
	"10|bool|NSGlobalDomain|AppleShowAllExtensions|true|false|Show all filename extensions|Hide all filename extensions"
)

apply_finder_setting() {
    local id="$1"
    local mode="$2"  # "configure" or "revert"
    
    for setting in "${FINDER_SETTINGS[@]}"; do
        IFS='|' read -r s_id s_type s_domain s_key s_config_val s_default_val s_config_desc s_default_desc <<< "$setting"
        
        if [[ "$s_id" == "$id" ]]; then
            local target_value target_desc emoji
            if [[ "$mode" == "configure" ]]; then
                target_value="$s_config_val"
                target_desc="$s_config_desc"
                emoji="✅"
            else
                target_value="$s_default_val"
                target_desc="$s_default_desc"
                emoji="🔄"
            fi
            
            case "$s_type" in
                "bool")
                    defaults write "$s_domain" "$s_key" -bool "$target_value"
                    log_info "$emoji $target_desc"
                    ;;
                "string")
                    if [[ "$mode" == "revert" && -z "$target_value" ]]; then
                        defaults delete "$s_domain" "$s_key" 2>/dev/null || true
                    else
                        defaults write "$s_domain" "$s_key" -string "$target_value"
                    fi
                    log_info "$emoji $target_desc"
                    ;;
                "location")
                    if [[ "$mode" == "configure" ]]; then
                        defaults write "$s_domain" "$s_key" -string "$target_value"
                    else
                        defaults delete "$s_domain" "$s_key" 2>/dev/null || true
                    fi
                    log_info "$emoji $target_desc"
                    ;;
            esac
            return 0
        fi
    done
    log_error "Setting with ID $id not found"
    return 1
}

configure_finder_settings_menu() {
    if ! command -v dialog &>/dev/null; then
        echo "\n'dialog' utility is required for this menu."
        echo "Install it with: brew install dialog"
        read -p "Press Enter to return..."
        return 1
    fi
    
    local options=()
    for setting in "${FINDER_SETTINGS[@]}"; do
        IFS='|' read -r s_id s_type s_domain s_key s_config_val s_default_val s_config_desc s_default_desc <<< "$setting"
        options+=("$s_id" "$s_config_desc" "off")
    done
    
    local tmpfile=$(mktemp)
    dialog --clear \
        --backtitle "Finder Settings" \
        --title "Configure Finder Settings" \
        --checklist "Select Finder settings to enable:" 20 70 9 \
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
    
    choices=${choices//\"/}
    
    for choice in $choices; do
        apply_finder_setting "$choice" "configure"
    done
    
    killall cfprefsd 2>/dev/null || true
    killall Finder 2>/dev/null || true
    killall SystemUIServer 2>/dev/null || true
    log_success "Selected Finder settings configured!"
    log_info "Finder and preferences services restarted"
}

revert_finder_settings_to_defaults() {
    log_info "Reverting ALL Finder settings to macOS defaults..."
    echo
    
    for setting in "${FINDER_SETTINGS[@]}"; do
        IFS='|' read -r s_id s_type s_domain s_key s_config_val s_default_val s_config_desc s_default_desc <<< "$setting"
        apply_finder_setting "$s_id" "revert"
    done
    
    echo
    log_info "Restarting Finder and related services..."
    killall cfprefsd 2>/dev/null || true
    killall Finder 2>/dev/null || true
    killall SystemUIServer 2>/dev/null || true
    sleep 1
    
    log_success "All Finder settings reverted to macOS defaults!"
    log_info "Finder and preferences services restarted"
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

configure_hostname() {
  local name="${HOSTNAME}"
  if [[ -z "$name" ]]; then
    log_error "HOSTNAME is not set"
    return 1
  fi
  sudo scutil --set HostName "$name"
  sudo scutil --set LocalHostName "$name"
  sudo scutil --set ComputerName "$name"
  dscacheutil -flushcache 2>/dev/null || true
  log_success "Hostname set to $name"
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
        echo "4) Revert Finder settings to defaults"
        echo "5) Keyboard remapping"
        echo "6) Configure 1Password SSH"
        echo "0) Back"
        
        read -p "Choice [0-6]: " choice
        
        case "$choice" in
            1) install_ohmyzsh ;;
            2) install_rosetta ;;
            3) configure_finder_settings_menu ;;
            4) revert_finder_settings_to_defaults ;;
            5) remap_keyboard ;;
            6) configure_1password_ssh ;;
            7) configure_hostname ;;
            0) break ;;
            *) log_error "Invalid choice" ;;
        esac
        
        [[ "$choice" != "0" ]] && { echo; read -p "Press Enter to continue..."; }
    done
} 
