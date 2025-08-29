#!/bin/bash

install_bat_themes() {
    log_info "Installing Catppuccin themes for bat..."
    
    local bat_config_dir=$(bat --config-dir 2>/dev/null)
    if [[ -z "$bat_config_dir" ]]; then
        log_error "bat config directory not found. Is bat installed?"
        return 1
    fi
    
    mkdir -p "$bat_config_dir/themes"
    
    local base_url="https://github.com/catppuccin/bat/raw/main/themes"
    for theme in "Latte" "Frappe" "Macchiato" "Mocha"; do
        wget -P "$bat_config_dir/themes" "$base_url/Catppuccin%20$theme.tmTheme"
    done
    
    bat cache --build && log_success "Bat themes installed!" || log_error "Failed to rebuild bat cache"
}

install_kitty_themes() {
    log_info "Installing Catppuccin themes for kitty..."
    
    if ! command_exists git; then
        log_error "Git required"
        return 1
    fi
    
    local kitty_config_dir="$KITTY_CONFIG_DIR"
    local themes_dir="$kitty_config_dir/catppuccin"
    local config_file="$kitty_config_dir/kitty.conf"
    
    mkdir -p "$kitty_config_dir"

    if [[ -d "$themes_dir" ]]; then
        rm -rf "$themes_dir"
    fi
    
    git clone https://github.com/catppuccin/kitty.git "$themes_dir" || {
        log_error "Failed to clone kitty themes"
        return 1
    }
    
    [[ -f "$config_file" ]] && backup_file "$config_file" || touch "$config_file"
    
    if ! grep -q "mocha.conf" "$config_file"; then
        echo "" >> "$config_file"
        echo "# Catppuccin Mocha theme" >> "$config_file"
        echo "include $themes_dir/themes/mocha.conf" >> "$config_file"
        log_info "Added Mocha theme to kitty.conf"
    fi
    
    log_success "Kitty themes installed!"
    echo "Available: latte.conf, frappe.conf, macchiato.conf, mocha.conf"
}

install_warp_themes() {
    log_info "Installing Catppuccin themes for Warp..."
    
    if ! command_exists git; then
        log_error "Git required"
        return 1
    fi
    
    local warp_dir="$WARP_THEMES_DIR"
    local temp_dir="/tmp/catppuccin-warp-$$"
    
    mkdir -p "$warp_dir"
    
    git clone https://github.com/catppuccin/warp.git "$temp_dir" || {
        log_error "Failed to clone warp themes"
        return 1
    }
    
    if [[ -d "$temp_dir/themes" ]]; then
        cp "$temp_dir/themes"/* "$warp_dir/" 2>/dev/null || {
            log_error "No theme files found"
            rm -rf "$temp_dir"
            return 1
        }
        
        log_success "Warp themes installed!"
        echo "Restart Warp and go to Settings > Themes to select"
    else
        log_error "Themes directory not found"
    fi
    
    rm -rf "$temp_dir"
}

install_yazi_themes() {
    log_info "Installing Catppuccin themes for Yazi..."
    
    if ! command_exists git; then
        log_error "Git required"
        return 1
    fi
    
    local yazi_config_dir="$YAZI_CONFIG_DIR"
    local temp_dir="/tmp/catppuccin-yazi-$$"
    
    mkdir -p "$yazi_config_dir"
    
    git clone https://github.com/catppuccin/yazi.git "$temp_dir" || {
        log_error "Failed to clone yazi themes"
        return 1
    }
    
    if [[ ! -d "$temp_dir/themes" ]]; then
        log_error "Themes directory not found"
        rm -rf "$temp_dir"
        return 1
    fi
    
    local themes=()
    while IFS= read -r -d '' theme_file; do
        local theme_name=$(basename "$theme_file" .toml)
        themes+=("$theme_name")
    done < <(find "$temp_dir/themes" -name "*.toml" -print0 | sort -z)
    
    if [[ ${#themes[@]} -eq 0 ]]; then
        log_error "No theme files found"
        rm -rf "$temp_dir"
        return 1
    fi
    
    echo "Available themes:"
    for i in "${!themes[@]}"; do
        echo "$((i+1))) ${themes[i]}"
    done
    
    read -p "Select theme [1-${#themes[@]}] (default: mocha): " choice
    
    local selected_theme
    if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le "${#themes[@]}" ]]; then
        selected_theme="${themes[$((choice-1))]}"
    else
        selected_theme="${themes[0]}"
        for theme in "${themes[@]}"; do
            [[ "$theme" == *"mocha"* ]] && selected_theme="$theme" && break
        done
    fi
    
    local theme_file=$(find "$temp_dir/themes" -name "${selected_theme}.toml" | head -1)
    if [[ -z "$theme_file" ]]; then
        theme_file=$(find "$temp_dir/themes" -name "*${selected_theme}*" | head -1)
    fi
    
    if [[ -f "$theme_file" ]]; then
        local target="$yazi_config_dir/theme.toml"
        [[ -f "$target" ]] && backup_file "$target"
        cp "$theme_file" "$target"
        log_success "Installed $selected_theme theme"
    else
        log_error "Theme file not found: $selected_theme"
    fi
    
    rm -rf "$temp_dir"
}

configure_delta_theme() {
    if ! command_exists delta; then
        log_error "git-delta not installed"
        return 1
    fi
    
    if ! command_exists wget; then
        log_error "wget required"
        return 1
    fi
    
    local delta_dir="$DELTA_CONFIG_DIR"
    local config_file="$delta_dir/catppuccin.gitconfig"
    
    mkdir -p "$delta_dir"
    
    wget -O "$config_file" https://raw.githubusercontent.com/catppuccin/delta/main/catppuccin.gitconfig
    log_success "Downloaded Catppuccin delta theme"

    local gitconfig="$GITCONFIG_PATH"
    backup_file "$gitconfig"

    sed -i.bak '/catppuccin.gitconfig/d' "$gitconfig"
    
    printf "\n[include]\n    path = %s\n" "$config_file" >> "$gitconfig"
    
    git config --global core.pager delta
    git config --global interactive.diffFilter 'delta --color-only'
    git config --global delta.features catppuccin-mocha
    git config --global delta.side-by-side true
    git config --global delta.navigate true

    log_success "Catppuccin delta theme configured!"
}

configure_starship_theme() {
    if ! command_exists starship; then
        log_error "starship not installed"
        return 1
    fi
    
    log_info "Configuring Starship Catppuccin theme..."
    
    local starship_config_dir="$STARSHIP_CONFIG_DIR"
    mkdir -p "$starship_config_dir"
    
    starship preset catppuccin-powerline -o ~/.config/starship.toml && {
        log_success "Starship Catppuccin theme configured!"
        log_info "Theme saved to ~/.config/starship.toml"
    } || {
        log_error "Failed to configure starship theme"
        return 1
    }
}

install_all_themes() {
    log_info "Installing all Catppuccin themes..."
    
    install_bat_themes
    echo
    install_kitty_themes
    echo
    install_warp_themes
    echo
    install_yazi_themes
    echo
    configure_delta_theme
    echo
    configure_starship_theme
    
    log_success "All themes installed!"
}

show_themes_menu() {
    while true; do
        echo
        log_info "🎨 Catppuccin Themes"
        
        echo "1) bat themes"
        echo "2) kitty themes"
        echo "3) Warp themes"
        echo "4) Yazi themes"
        echo "5) delta theme"
        echo "6) starship theme"
        echo "7) Install all"
        echo "0) Back"
        
        read -p "Choice [0-7]: " choice
        
        case "$choice" in
            1) install_bat_themes ;;
            2) install_kitty_themes ;;
            3) install_warp_themes ;;
            4) install_yazi_themes ;;
            5) configure_delta_theme ;;
            6) configure_starship_theme ;;
            7) install_all_themes ;;
            0) break ;;
            *) log_error "Invalid choice" ;;
        esac
        
        [[ "$choice" != "0" ]] && { echo; read -p "Press Enter to continue..."; }
    done
} 