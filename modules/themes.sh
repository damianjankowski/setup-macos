#!/bin/bash

# Download a URL to a destination path, creating parent directories as needed.
# Guards on wget availability and surfaces download failures to the caller.
download_to() {
    local dest="$1"
    local url="$2"

    if ! require_tool wget; then
        return 1
    fi

    mkdir -p "$(dirname "$dest")"
    if ! wget -q -O "$dest" "$url"; then
        log_error "Failed to download: $url"
        return 1
    fi
}

install_bat_themes() {
    log_info "Installing bat themes..."

    if ! require_tool bat; then
        return 1
    fi

    local bat_config_dir
    bat_config_dir=$(bat --config-dir 2>/dev/null)
    if [[ -z "$bat_config_dir" ]]; then
        log_error "bat config directory not found. Is bat installed?"
        return 1
    fi

    local base_url="https://github.com/catppuccin/bat/raw/main/themes"
    local theme
    for theme in "Catppuccin Latte" "Catppuccin Frappe" "Catppuccin Macchiato" "Catppuccin Mocha"; do
        download_to "$bat_config_dir/themes/${theme}.tmTheme" "$base_url/${theme// /%20}.tmTheme" || return 1
    done

    if bat cache --build; then
        log_info "Bat themes installed successfully!"
    else
        log_error "Failed to rebuild bat cache"
        return 1
    fi

    log_info "Catppuccin themes installed:"
    bat --list-themes | grep "Catppuccin" | sort
}

install_kitty_themes() {
    if ! require_tool kitty; then
        return 1
    fi

    local kitty_config_dir
    kitty_config_dir=$(get_expanded_config "KITTY_CONFIG_DIR")
    log_info "Installing kitty themes into $kitty_config_dir..."

    local base_url="https://github.com/catppuccin/kitty/raw/main/themes"
    local theme
    for theme in diff-frappe diff-latte diff-macchiato diff-mocha frappe latte macchiato mocha; do
        download_to "$kitty_config_dir/themes/${theme}.conf" "$base_url/${theme}.conf" || return 1
    done

    kitty +kitten themes --reload-in=all Catppuccin-Mocha

    if [[ -f "$kitty_config_dir/current-theme.conf" ]]; then
        log_info "Active kitty theme:"
        grep "Catppuccin" "$kitty_config_dir/current-theme.conf"
    fi
}

install_warp_themes() {
    local warp_config_dir
    warp_config_dir=$(get_expanded_config "WARP_THEMES_DIR")
    log_info "Installing warp themes into $warp_config_dir..."

    local base_url="https://github.com/catppuccin/warp/raw/main/themes"
    local theme
    for theme in catppuccin_latte catppuccin_frappe catppuccin_macchiato catppuccin_mocha; do
        download_to "$warp_config_dir/${theme}.yml" "$base_url/${theme}.yml" || return 1
    done

    if killall Warp 2>/dev/null; then
        log_info "Restarted Warp to load the new themes."
    fi

    log_info "Catppuccin themes installed:"
    ls -la "$warp_config_dir"
    log_info "Open Settings > Themes and select your flavor."
}

install_yazi_themes() {
    if ! require_tool git; then
        return 1
    fi

    local yazi_config_dir
    yazi_config_dir=$(get_expanded_config "YAZI_CONFIG_DIR")
    log_info "Installing yazi themes into $yazi_config_dir..."

    if [ -d "/tmp/yazi" ]; then
        rm -rf /tmp/yazi
    fi
    git clone https://github.com/catppuccin/yazi.git /tmp/yazi
    if [ ! -d "/tmp/yazi/themes" ]; then
        log_error "Themes directory not found in cloned repository"
        rm -rf /tmp/yazi
        return 1
    fi
    log_info "Available themes:"
    ls -la /tmp/yazi/themes/
    local themes=()
    for theme_dir in /tmp/yazi/themes/*/; do
        if [[ -d "$theme_dir" ]]; then
            local theme_name=$(basename "$theme_dir")
            themes+=("$theme_name")
        fi
    done

    if [[ ${#themes[@]} -eq 0 ]]; then
        log_error "No theme directories found"
        rm -rf /tmp/yazi
        return 1
    fi
    log_info "Found ${#themes[@]} theme categories:"
    for theme in "${themes[@]}"; do
        echo "  - $theme"
    done
    local input
    input=$(ask_for_input "Choose a theme category (latte/frappe/macchiato/mocha) [default: mocha]")
    input=${input:-mocha}
    if [[ " ${themes[*]} " != *" ${input} "* ]]; then
        log_error "Invalid theme category: $input"
        log_info "Using default: mocha"
        input="mocha"
    fi
    local selected_theme="catppuccin-${input}-blue"
    local theme_file="/tmp/yazi/themes/${input}/${selected_theme}.toml"

    log_info "Selected theme: $selected_theme"
    if [[ ! -f "$theme_file" ]]; then
        log_error "Theme file not found: $theme_file"
        log_info "Available themes in $input category:"
        ls -la "/tmp/yazi/themes/${input}/"
        rm -rf /tmp/yazi
        return 1
    fi
    mkdir -p "$yazi_config_dir"
    cp "$theme_file" "$yazi_config_dir/theme.toml"
    log_info "Installed theme: $selected_theme"
    rm -rf /tmp/yazi

    log_info "Yazi theme installation completed"
}

install_delta_themes() {
    if ! require_tool delta; then
        log_error "delta not found. Is delta installed?"
        return 1
    fi

    local delta_dir
    delta_dir=$(get_expanded_config "DELTA_CONFIG_DIR")
    local config_file="$delta_dir/catppuccin.gitconfig"

    download_to "$config_file" "https://raw.githubusercontent.com/catppuccin/delta/main/catppuccin.gitconfig" || return 1
    log_info "Downloaded Catppuccin delta theme to $config_file"
}

install_starship_themes() {
    log_info "Installing starship themes..."

    if ! require_tool starship; then
        return 1
    fi

    local starship_config_dir
    starship_config_dir=$(get_expanded_config "STARSHIP_CONFIG_DIR")
    mkdir -p "$starship_config_dir"

    if starship preset catppuccin-powerline -o "$starship_config_dir/starship.toml"; then
        log_info "Starship Catppuccin theme configured!"
        log_info "Theme saved to $starship_config_dir/starship.toml"
    else
        log_error "Failed to configure starship theme"
        return 1
    fi
}

install_tmux_themes() {
    log_info "Installing tmux themes..."

    if ! require_tool git; then
        return 1
    fi

    local tmux_config_dir
    tmux_config_dir=$(get_expanded_config "TMUX_CONFIG_DIR")
    local plugin_dir="$tmux_config_dir/plugins/catppuccin/tmux"

    # Pick the tmux config file tmux actually reads: prefer the XDG location,
    # then the legacy ~/.tmux.conf, otherwise create the XDG one.
    local tmux_conf
    if [[ -f "$tmux_config_dir/tmux.conf" ]]; then
        tmux_conf="$tmux_config_dir/tmux.conf"
    elif [[ -f "$HOME/.tmux.conf" ]]; then
        tmux_conf="$HOME/.tmux.conf"
    else
        mkdir -p "$tmux_config_dir"
        tmux_conf="$tmux_config_dir/tmux.conf"
    fi

    if [[ ! -d "$plugin_dir" ]]; then
        mkdir -p "$(dirname "$plugin_dir")"
        if ! git clone -b v2.1.3 https://github.com/catppuccin/tmux.git "$plugin_dir"; then
            log_error "Failed to clone catppuccin/tmux"
            return 1
        fi
    else
        log_info "catppuccin/tmux already present at $plugin_dir"
    fi

    local run_line="run $plugin_dir/catppuccin.tmux"
    if grep -qF "$run_line" "$tmux_conf" 2>/dev/null; then
        log_info "tmux config already references the catppuccin theme ($tmux_conf)"
    else
        echo "$run_line" >> "$tmux_conf"
        log_info "Catppuccin tmux theme added to $tmux_conf"
    fi

    log_info "Reload tmux with: tmux source $tmux_conf"
}

install_all_themes() {
    log_info "Installing all themes..."
    install_bat_themes
    install_kitty_themes
    install_warp_themes
    install_yazi_themes
    install_delta_themes
    install_starship_themes
    install_tmux_themes
    log_info "All themes installation completed!"
}

show_themes_menu() {
    clear
    echo "┌─────────────────────────────┐"
    echo "│         Themes Tools         │"
    echo "└─────────────────────────────┘"
    echo ""
    echo "1) bat themes"
    echo "2) kitty themes"
    echo "3) Warp themes"
    echo "4) Yazi themes"
    echo "5) delta theme"
    echo "6) starship theme"
    echo "7) tmux themes"
    echo "8) Install all"
    echo "0) Back"
    echo ""
}

handle_themes_menu() {
    while true; do
        show_themes_menu
        read -r -p "Choice [0-8]: " choice

        case $choice in
            1)
                install_bat_themes
                wait_for_user
                ;;
            2)
                install_kitty_themes
                wait_for_user
                ;;
            3)
                install_warp_themes
                wait_for_user
                ;;
            4)
                install_yazi_themes
                wait_for_user
                ;;
            5)
                install_delta_themes
                wait_for_user
                ;;
            6)
                install_starship_themes
                wait_for_user
                ;;
            7)
                install_tmux_themes
                wait_for_user
                ;;
            8)
                install_all_themes
                wait_for_user
                ;;
            0)
                return
                ;;
            *)
                echo "Invalid choice. Please try again."
                sleep 1
                ;;
        esac
    done
}
themes_tools() {
    handle_themes_menu
}

