#!/bin/bash

install_bat_themes() {
    log_info "Installing bat themes..."

	local bat_config_dir=$(bat --config-dir 2>/dev/null)
    if [[ -z "$bat_config_dir" ]]; then
        log_error "bat config directory not found. Is bat installed?"
        return 1
    fi

	local base_url="https://github.com/catppuccin/bat/raw/main/themes"

	wget -O "$(bat --config-dir)/themes/Catppuccin Latte.tmTheme" https://github.com/catppuccin/bat/raw/main/themes/Catppuccin%20Latte.tmTheme
	wget -O "$(bat --config-dir)/themes/Catppuccin Frappe.tmTheme" https://github.com/catppuccin/bat/raw/main/themes/Catppuccin%20Frappe.tmTheme
	wget -O "$(bat --config-dir)/themes/Catppuccin Macchiato.tmTheme" https://github.com/catppuccin/bat/raw/main/themes/Catppuccin%20Macchiato.tmTheme
	wget -O "$(bat --config-dir)/themes/Catppuccin Mocha.tmTheme" https://github.com/catppuccin/bat/raw/main/themes/Catppuccin%20Mocha.tmTheme

	bat cache --build && log_info "Bat themes installed successfully!" || log_error "Failed to rebuild bat cache"

	log_info "Catppuccin themes installed:"
	bat --list-themes | grep "Catppuccin" | sort
}

install_kitty_themes() {
	local kitty_config_dir=$(get_expanded_config "KITTY_CONFIG_DIR")
    log_info "Installing kitty themes into $kitty_config_dir..."

	if [ ! -d "$kitty_config_dir/themes" ]; then
		mkdir -p "$kitty_config_dir/themes"
	fi

	wget -O "$kitty_config_dir/themes/diff-frappe.conf" https://github.com/catppuccin/kitty/raw/main/themes/diff-frappe.conf
	wget -O "$kitty_config_dir/themes/diff-latte.conf" https://github.com/catppuccin/kitty/raw/main/themes/diff-latte.conf
	wget -O "$kitty_config_dir/themes/diff-macchiato.conf" https://github.com/catppuccin/kitty/raw/main/themes/diff-macchiato.conf
	wget -O "$kitty_config_dir/themes/diff-mocha.conf" https://github.com/catppuccin/kitty/raw/main/themes/diff-mocha.conf
	wget -O "$kitty_config_dir/themes/frappe.conf" https://github.com/catppuccin/kitty/raw/main/themes/frappe.conf
	wget -O "$kitty_config_dir/themes/latte.conf" https://github.com/catppuccin/kitty/raw/main/themes/latte.conf
	wget -O "$kitty_config_dir/themes/macchiato.conf" https://github.com/catppuccin/kitty/raw/main/themes/macchiato.conf
	wget -O "$kitty_config_dir/themes/mocha.conf" https://github.com/catppuccin/kitty/raw/main/themes/mocha.conf

	kitty +kitten themes --reload-in=all Catppuccin-Mocha 
	log_info "Catppuccin themes installed:"
	cat $kitty_config_dir/current-theme.conf | grep "Catppuccin"
}

install_warp_themes() {
	local warp_config_dir=$(get_expanded_config "WARP_THEMES_DIR")
    log_info "Installing warp themes into $warp_config_dir..."

	wget -O "$warp_config_dir/catppuccin_latte.yml" https://github.com/catppuccin/warp/raw/main/themes/catppuccin_latte.yml
	wget -O "$warp_config_dir/catppuccin_frappe.yml" https://github.com/catppuccin/warp/raw/main/themes/catppuccin_frappe.yml
	wget -O "$warp_config_dir/catppuccin_macchiato.yml" https://github.com/catppuccin/warp/raw/main/themes/catppuccin_macchiato.yml
	wget -O "$warp_config_dir/catppuccin_mocha.yml" https://github.com/catppuccin/warp/raw/main/themes/catppuccin_mocha.yml
	killall Warp
	log_info "Catppuccin themes installed:"
	ls -la $warp_config_dir
	log_info "Open Settings > Themes and select your flavor."
}

install_yazi_themes() {
	local yazi_config_dir=$(get_expanded_config "YAZI_CONFIG_DIR")
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
	ask_for_input "Choose a theme category (latte/frappe/macchiato/mocha) [default: mocha]: " input
	input=${input:-mocha}
	if [[ ! " ${themes[@]} " =~ " ${input} " ]]; then
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
	cp "$theme_file" "$yazi_config_dir/theme.toml"
	log_info "Installed theme: $selected_theme"
	rm -rf /tmp/yazi
	
	log_info "Yazi theme installation completed"
}

install_delta_themes() {
    if require_tool delta; then
        log_error "delta not found. Is delta installed?"
        return 1
    fi
    
    local delta_dir=$(get_expanded_config "DELTA_CONFIG_DIR")
    local config_file="$delta_dir/catppuccin.gitconfig"
    
    mkdir -p "$delta_dir"
    
    wget -O "$config_file" https://raw.githubusercontent.com/catppuccin/delta/main/catppuccin.gitconfig
    log_info "Downloaded Catppuccin delta theme"
}

install_starship_themes() {
	log_info "Installing starship themes..."

	local starship_config_dir=$(get_expanded_config "STARSHIP_CONFIG_DIR")
	mkdir -p $starship_config_dir

	starship preset catppuccin-powerline -o $starship_config_dir/starship.toml && {
        log_info "Starship Catppuccin theme configured!"
        log_info "Theme saved to $starship_config_dir/starship.toml"
    } || {
        log_error "Failed to configure starship theme"
        return 1
    }
}

install_tmux_themes() {
	log_info "Installing tmux themes..."

	local tmux_plugins_dir="$HOME/.config/tmux/plugins/catppuccin"
	
	if ! [[ -d "$tmux_plugins_dir" ]]; then
		mkdir -p "$tmux_plugins_dir"
	fi
		
	if ! [[ -d "$tmux_plugins_dir/tmux" ]]; then
		git clone -b v2.1.3 https://github.com/catppuccin/tmux.git "$tmux_plugins_dir/tmux"
	fi
	
	{
		log_info "Catppuccin tmux theme installed successfully!"
		echo "run ~/.config/tmux/plugins/catppuccin/tmux/catppuccin.tmux" >> "$HOME/.tmux.conf"
		log_info "Configuration added to ~/.tmux.conf"
		log_info "Reload tmux with: tmux source ~/.tmux.conf"
	} || log_error "Failed to install tmux themes"
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
        read -p "Choice [0-8]: " choice
        
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

export -f install_bat_themes install_kitty_themes install_warp_themes install_yazi_themes install_delta_themes install_starship_themes install_tmux_themes install_all_themes show_themes_menu handle_themes_menu themes_tools