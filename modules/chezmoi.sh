#!/bin/bash

chezmoi_add() {
	local path=$1
	if [[ -z "$path" ]]; then
		log_error "Path is required"
		return 1
	fi

    require_tool chezmoi

    log_info "Adding chezmoi configuration..."
    
    chezmoi add "$path"
}

chezmoi_apply() {
    log_info "Applying chezmoi configuration..."
    chezmoi apply
}

add_kitty_config() {
    chezmoi_add $(get_expanded_config "KITTY_CONFIG_DIR")
}

add_warp_config() {
    chezmoi_add $(get_expanded_config "WARP_THEMES_DIR")
}

add_yazi_config() {
    chezmoi_add $(get_expanded_config "YAZI_CONFIG_DIR")
}

add_delta_config() {
    chezmoi_add $(get_expanded_config "DELTA_CONFIG_DIR")
}

add_aerospace_config() {
    chezmoi_add $(get_expanded_config "AEROSPACE_CONFIG_DIR")
}

apply_kitty_config() {
    chezmoi_apply $(get_expanded_config "KITTY_CONFIG_DIR")
}

show_chezmoi_menu() {
    clear
    echo "┌─────────────────────────────┐"
    echo "│         Chezmoi Tools         │"
    echo "└─────────────────────────────┘"
    echo ""
    echo "1) Add kitty configuration"
    echo "2) Add warp configuration"
    echo "3) Add yazi configuration"
    echo "4) Add delta configuration"
    echo "5) Add aerospace configuration"
	echo ""
    echo "6) Apply chezmoi configuration"
    echo "0) Back"
    echo ""
}

handle_chezmoi_menu() {
    while true; do
        show_chezmoi_menu
        read -p "Choice [0-6]: " choice
        
        case $choice in
            1)
                add_kitty_config
                wait_for_user
                ;;
            2)
                add_warp_config
                wait_for_user
                ;;
            3)
                add_yazi_config
                wait_for_user
                ;;
            4)
                add_delta_config
                wait_for_user
                ;;
            5)
                add_aerospace_config
                wait_for_user
                ;;
            6)
                chezmoi_apply
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

chezmoi_tools() {
    handle_chezmoi_menu
}

export -f chezmoi_add chezmoi_apply add_kitty_config add_warp_config add_yazi_config add_delta_config add_aerospace_config apply_kitty_config show_chezmoi_menu handle_chezmoi_menu chezmoi_tools