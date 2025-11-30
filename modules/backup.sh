#!/bin/bash

init_ide_backup_dir() {
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_dir=$(get_expanded_config "BACKUP_DIR")/configs/$timestamp
    mkdir -p "$backup_dir"
    echo "$backup_dir"
}

backup_pycharm_settings() {
    log_info "Backing up PyCharm settings..."
    
    local backup_dir="${1:-$(init_ide_backup_dir)}"
    local pycharm_backup_dir="$backup_dir/pycharm"
	local pycharm_config_dir=$(get_expanded_config "PYCHARM_CONFIG_DIR")
    
    
    if [[ ! -d "$pycharm_config_dir" ]]; then
        log_warn "PyCharm config directory not found: $pycharm_config_dir"
        return 1
    fi
    
    mkdir -p "$pycharm_backup_dir"
    
    local latest_pycharm_dir=$(find "$pycharm_config_dir" -name "PyCharm*" -not -name "*-backup*" -type d | sort -V | tail -1)
    
    if [[ -z "$latest_pycharm_dir" ]]; then
        log_warn "No PyCharm configuration found"
        return 1
    fi
    
    [[ -d "$latest_pycharm_dir/codestyles" ]] && cp -R "$latest_pycharm_dir/codestyles" "$pycharm_backup_dir/"
    [[ -d "$latest_pycharm_dir/keymaps" ]] && cp -R "$latest_pycharm_dir/keymaps" "$pycharm_backup_dir/"
    [[ -d "$latest_pycharm_dir/options" ]] && cp -R "$latest_pycharm_dir/options" "$pycharm_backup_dir/"
	[[ -d "$latest_pycharm_dir/tools" ]] && cp -R "$latest_pycharm_dir/tools" "$pycharm_backup_dir/"
	[[ -d "$latest_pycharm_dir/extensions" ]] && cp -R "$latest_pycharm_dir/extensions" "$pycharm_backup_dir/"
	# [[ -d "$latest_pycharm_dir/plugins" ]] && cp -R "$latest_pycharm_dir/plugins" "$pycharm_backup_dir/"
	[[ -d "$latest_pycharm_dir/modules" ]] && cp -R "$latest_pycharm_dir/modules" "$pycharm_backup_dir/"
    
    [[ -z "$1" ]] && log_info "PyCharm settings backed up to: ./configs/$(basename "$backup_dir")/pycharm"
    return 0
}


backup_vscode_settings() {
    log_info "Backing up VS Code settings..."
    
    local backup_dir="${1:-$(init_ide_backup_dir)}"
    local vscode_backup_dir="$backup_dir/vscode"
    local vscode_config_dir=$(get_expanded_config "VSCODE_CONFIG_DIR")

    if [[ ! -d "$vscode_config_dir" ]]; then
        log_warn "VS Code config directory not found: $vscode_config_dir"
        return 1
    fi
    
    mkdir -p "$vscode_backup_dir"
    
    [[ -f "$vscode_config_dir/settings.json" ]] && cp "$vscode_config_dir/settings.json" "$vscode_backup_dir/"
    [[ -f "$vscode_config_dir/keybindings.json" ]] && cp "$vscode_config_dir/keybindings.json" "$vscode_backup_dir/"
    [[ -f "$vscode_config_dir/tasks.json" ]] && cp "$vscode_config_dir/tasks.json" "$vscode_backup_dir/"
    [[ -f "$vscode_config_dir/launch.json" ]] && cp "$vscode_config_dir/launch.json" "$vscode_backup_dir/"
    
    [[ -d "$vscode_config_dir/snippets" ]] && cp -R "$vscode_config_dir/snippets" "$vscode_backup_dir/"
    
    require_tool code
    code --list-extensions > "$vscode_backup_dir/extensions.txt"
    
    [[ -z "$1" ]] && log_info "VS Code settings backed up to: ./configs/$(basename "$backup_dir")/vscode"
    return 0
}

backup_cursor_settings() {
    log_info "Backing up Cursor AI settings..."
    
    local backup_dir="${1:-$(init_ide_backup_dir)}"
    local cursor_backup_dir="$backup_dir/cursor"
	local cursor_config_dir=$(get_expanded_config "CURSOR_CONFIG_DIR")
    
    if [[ ! -d "$cursor_config_dir" ]]; then
        log_warn "Cursor AI config directory not found: $cursor_config_dir"
        return 1
    fi
    
    mkdir -p "$cursor_backup_dir"
    
    [[ -f "$cursor_config_dir/settings.json" ]] && cp "$cursor_config_dir/settings.json" "$cursor_backup_dir/"
    [[ -f "$cursor_config_dir/keybindings.json" ]] && cp "$cursor_config_dir/keybindings.json" "$cursor_backup_dir/"
    [[ -f "$cursor_config_dir/tasks.json" ]] && cp "$cursor_config_dir/tasks.json" "$cursor_backup_dir/"
    [[ -f "$cursor_config_dir/launch.json" ]] && cp "$cursor_config_dir/launch.json" "$cursor_backup_dir/"
    
    [[ -d "$cursor_config_dir/snippets" ]] && cp -R "$cursor_config_dir/snippets" "$cursor_backup_dir/"
    
    require_tool cursor
    cursor --list-extensions > "$cursor_backup_dir/extensions.txt" 2>/dev/null || true
    
    [[ -z "$1" ]] && log_info "Cursor AI settings backed up to: ./configs/$(basename "$backup_dir")/cursor"
    return 0
}

choose_backup_dir() {
    local backup_dir=$(get_expanded_config "BACKUP_DIR")
    local backup_dir="$backup_dir/configs"
    ls -la "$backup_dir"
}

restore_vscode_settings() {
	choose_backup_dir
	backup_dir=$(ask_for_input "Enter the backup directory: ")
    local source_dir=$(get_expanded_config "BACKUP_DIR")/configs/$backup_dir/vscode
	local vscode_config_dir=$(get_expanded_config "VSCODE_CONFIG_DIR")
    
    if [[ ! -d "$source_dir" ]]; then
        log_error "Source directory not found: $source_dir"
        return 1
    fi
    
    log_info "Restoring VS Code settings from: $source_dir"
    
    mkdir -p "$vscode_config_dir"
    
    [[ -f "$source_dir/settings.json" ]] && cp "$source_dir/settings.json" "$vscode_config_dir/"
	[[ -f "$source_dir/keybindings.json" ]] && cp "$source_dir/keybindings.json" "$vscode_config_dir/"
    [[ -f "$source_dir/tasks.json" ]] && cp "$source_dir/tasks.json" "$vscode_config_dir/"
    [[ -f "$source_dir/launch.json" ]] && cp "$source_dir/launch.json" "$vscode_config_dir/"
    
    [[ -d "$source_dir/snippets" ]] && cp -R "$source_dir/snippets" "$vscode_config_dir/"
    
    if [[ -f "$source_dir/extensions.txt" ]] && require_tool code; then
		ask_for_confirmation "Do you want to install VS Code extensions?"
		if [[ $? -eq 0 ]]; then
			log_info "Installing VS Code extensions..."
			while IFS= read -r extension; do
				[[ -n "$extension" ]] && code --install-extension "$extension" --force 2>/dev/null || true
			done < "$source_dir/extensions.txt"
		fi
    fi
    
    log_info "VS Code settings restored successfully"
    return 0
}

restore_cursor_settings() {
	choose_backup_dir
	backup_dir=$(ask_for_input "Enter the backup directory: ")
    local source_dir=$(get_expanded_config "BACKUP_DIR")/configs/$backup_dir/cursor
	local cursor_config_dir=$(get_expanded_config "CURSOR_CONFIG_DIR")
    
    if [[ ! -d "$source_dir" ]]; then
        log_error "Source directory not found: $source_dir"
        return 1
    fi
    
    log_info "Restoring Cursor AI settings from: $source_dir"
    
    mkdir -p "$cursor_config_dir"
    
    [[ -f "$source_dir/settings.json" ]] && cp "$source_dir/settings.json" "$cursor_config_dir/"
    [[ -f "$source_dir/keybindings.json" ]] && cp "$source_dir/keybindings.json" "$cursor_config_dir/"
    [[ -f "$source_dir/tasks.json" ]] && cp "$source_dir/tasks.json" "$cursor_config_dir/"
    [[ -f "$source_dir/launch.json" ]] && cp "$source_dir/launch.json" "$cursor_config_dir/"
    
    [[ -d "$source_dir/snippets" ]] && cp -R "$source_dir/snippets" "$cursor_config_dir/"
    
    if [[ -f "$source_dir/extensions.txt" ]] && require_tool cursor; then
		ask_for_confirmation "Do you want to install Cursor AI extensions?"
		if [[ $? -eq 0 ]]; then
        	log_info "Installing Cursor AI extensions..."
        	while IFS= read -r extension; do
            	[[ -n "$extension" ]] && cursor --install-extension "$extension" --force 2>/dev/null || true
        	done < "$source_dir/extensions.txt"
		fi
    fi
    
    log_info "Cursor AI settings restored successfully"
    return 0
}

restore_pycharm_settings() {
	choose_backup_dir
	backup_dir=$(ask_for_input "Enter the backup directory: ")
    local source_dir=$(get_expanded_config "BACKUP_DIR")/configs/$backup_dir/pycharm
	local pycharm_config_dir=$(get_expanded_config "PYCHARM_CONFIG_DIR")
    

	if [[ ! -d "$source_dir" ]]; then
        log_error "Source directory not found: $source_dir"
        return 1
    fi
    
    log_info "Restoring PyCharm settings from: $source_dir"

	local latest_pycharm_dir=$(find "$pycharm_config_dir" -name "PyCharm*" -not -name "*-backup*" -type d | sort -V | tail -1)
    
    mkdir -p "$pycharm_config_dir"
    
    [[ -d "$source_dir/codestyles" ]] && cp -R "$source_dir/codestyles" "$latest_pycharm_dir/"
    [[ -d "$source_dir/keymaps" ]] && cp -R "$source_dir/keymaps" "$latest_pycharm_dir/"
    [[ -d "$source_dir/options" ]] && cp -R "$source_dir/options" "$latest_pycharm_dir/"
    [[ -d "$source_dir/tools" ]] && cp -R "$source_dir/tools" "$latest_pycharm_dir/"
    [[ -d "$source_dir/extensions" ]] && cp -R "$source_dir/extensions" "$latest_pycharm_dir/"
    [[ -d "$source_dir/plugins" ]] && cp -R "$source_dir/plugins" "$latest_pycharm_dir/"
    [[ -d "$source_dir/modules" ]] && cp -R "$source_dir/modules" "$latest_pycharm_dir/"

	log_info "PyCharm settings restored successfully"
    return 0
}

backup_all_settings() {
	backup_pycharm_settings
	backup_vscode_settings
	backup_cursor_settings
}

restore_all_settings() {
	restore_pycharm_settings
	restore_vscode_settings
	restore_cursor_settings
}

show_backup_menu() {
    clear
    echo "┌─────────────────────────────┐"
    echo "│         Backup Tools         │"
    echo "└─────────────────────────────┘"
    echo ""
    echo "1) Backup pycharm configuration"
    echo "2) Backup vscode configuration"
    echo "3) Backup cursor configuration"
    echo ""
	echo "4) Restore pycharm configuration"
	echo "5) Restore vscode configuration"
	echo "6) Restore cursor configuration"
	echo "7) Backup all configurations"
	echo "8) Restore all configurations"
    echo "0) Back"
    echo ""
}

handle_backup_menu() {
    while true; do
        show_backup_menu
        read -p "Choice [0-8]: " choice
        
        case $choice in
            1)
                backup_pycharm_settings
                wait_for_user
                ;;
            2)
                backup_vscode_settings
                wait_for_user
                ;;
            3)
                backup_cursor_settings
                wait_for_user
                ;;
            4)
                restore_pycharm_settings
                wait_for_user
                ;;
            5)
                restore_vscode_settings
                wait_for_user
                ;;
            6)
                restore_cursor_settings
                wait_for_user
                ;;
			7)
				backup_all_settings
				wait_for_user
				;;
			8)
				restore_all_settings
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

backup_tools() {
    handle_backup_menu
}

export -f backup_pycharm_settings backup_vscode_settings backup_cursor_settings restore_pycharm_settings restore_vscode_settings restore_cursor_settings backup_all_settings restore_all_settings choose_backup_dir show_backup_menu handle_backup_menu backup_tools
	