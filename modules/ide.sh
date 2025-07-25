#!/bin/bash

init_ide_backup_dir() {
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_dir="$BACKUP_DIR/$timestamp"
    mkdir -p "$backup_dir"
    echo "$backup_dir"
}

backup_vscode_settings() {
    log_info "Backing up VS Code settings..."
    
    local backup_dir="${1:-$(init_ide_backup_dir)}"
    local vscode_backup_dir="$backup_dir/vscode"
    
    if [[ ! -d "$VSCODE_CONFIG_DIR" ]]; then
        log_warn "VS Code config directory not found: $VSCODE_CONFIG_DIR"
        return 1
    fi
    
    mkdir -p "$vscode_backup_dir"
    
    [[ -f "$VSCODE_CONFIG_DIR/settings.json" ]] && cp "$VSCODE_CONFIG_DIR/settings.json" "$vscode_backup_dir/"
    [[ -f "$VSCODE_CONFIG_DIR/keybindings.json" ]] && cp "$VSCODE_CONFIG_DIR/keybindings.json" "$vscode_backup_dir/"
    [[ -f "$VSCODE_CONFIG_DIR/tasks.json" ]] && cp "$VSCODE_CONFIG_DIR/tasks.json" "$vscode_backup_dir/"
    [[ -f "$VSCODE_CONFIG_DIR/launch.json" ]] && cp "$VSCODE_CONFIG_DIR/launch.json" "$vscode_backup_dir/"
    
    [[ -d "$VSCODE_CONFIG_DIR/snippets" ]] && cp -R "$VSCODE_CONFIG_DIR/snippets" "$vscode_backup_dir/"
    
    if command_exists code; then
        code --list-extensions > "$vscode_backup_dir/extensions.txt" 2>/dev/null || true
    fi
    
    [[ -z "$1" ]] && log_success "VS Code settings backed up to: ./configs/$(basename "$backup_dir")/vscode"
    return 0
}

backup_vscode_themes() {
    log_info "Backing up VS Code themes and icons..."
    
    local backup_dir="${1:-$(init_ide_backup_dir)}"
    local vscode_backup_dir="$backup_dir/vscode"
    
    mkdir -p "$vscode_backup_dir"
    
    if [[ -d "$VSCODE_EXTENSIONS_DIR" ]]; then
        mkdir -p "$vscode_backup_dir/themes"
        find "$VSCODE_EXTENSIONS_DIR" -name "*.json" -path "*/themes/*" -exec cp {} "$vscode_backup_dir/themes/" \; 2>/dev/null || true
    fi
    
    [[ -z "$1" ]] && log_success "VS Code themes backed up to: ./configs/$(basename "$backup_dir")/vscode/themes"
    return 0
}

backup_cursor_settings() {
    log_info "Backing up Cursor AI settings..."
    
    local backup_dir="${1:-$(init_ide_backup_dir)}"
    local cursor_backup_dir="$backup_dir/cursor"
    
    if [[ ! -d "$CURSOR_CONFIG_DIR" ]]; then
        log_warn "Cursor AI config directory not found: $CURSOR_CONFIG_DIR"
        return 1
    fi
    
    mkdir -p "$cursor_backup_dir"
    
    [[ -f "$CURSOR_CONFIG_DIR/settings.json" ]] && cp "$CURSOR_CONFIG_DIR/settings.json" "$cursor_backup_dir/"
    [[ -f "$CURSOR_CONFIG_DIR/keybindings.json" ]] && cp "$CURSOR_CONFIG_DIR/keybindings.json" "$cursor_backup_dir/"
    [[ -f "$CURSOR_CONFIG_DIR/tasks.json" ]] && cp "$CURSOR_CONFIG_DIR/tasks.json" "$cursor_backup_dir/"
    [[ -f "$CURSOR_CONFIG_DIR/launch.json" ]] && cp "$CURSOR_CONFIG_DIR/launch.json" "$cursor_backup_dir/"
    
    [[ -d "$CURSOR_CONFIG_DIR/snippets" ]] && cp -R "$CURSOR_CONFIG_DIR/snippets" "$cursor_backup_dir/"
    
    if command_exists cursor; then
        cursor --list-extensions > "$cursor_backup_dir/extensions.txt" 2>/dev/null || true
    fi
    
    [[ -z "$1" ]] && log_success "Cursor AI settings backed up to: ./configs/$(basename "$backup_dir")/cursor"
    return 0
}

backup_cursor_themes() {
    log_info "Backing up Cursor AI themes and icons..."
    
    local backup_dir="${1:-$(init_ide_backup_dir)}"
    local cursor_backup_dir="$backup_dir/cursor"
    
    mkdir -p "$cursor_backup_dir"
    
    if [[ -d "$CURSOR_EXTENSIONS_DIR" ]]; then
        mkdir -p "$cursor_backup_dir/themes"
        find "$CURSOR_EXTENSIONS_DIR" -name "*.json" -path "*/themes/*" -exec cp {} "$cursor_backup_dir/themes/" \; 2>/dev/null || true
    fi
    
    [[ -z "$1" ]] && log_success "Cursor AI themes backed up to: ./configs/$(basename "$backup_dir")/cursor/themes"
    return 0
}

backup_pycharm_settings() {
    log_info "Backing up PyCharm settings..."
    
    local backup_dir="${1:-$(init_ide_backup_dir)}"
    local pycharm_backup_dir="$backup_dir/pycharm"
    
    if [[ ! -d "$PYCHARM_CONFIG_DIR" ]]; then
        log_warn "PyCharm config directory not found: $PYCHARM_CONFIG_DIR"
        return 1
    fi
    
    mkdir -p "$pycharm_backup_dir"
    
    local latest_pycharm_dir=$(find "$PYCHARM_CONFIG_DIR" -name "PyCharm*" -type d | sort -V | tail -1)
    
    if [[ -z "$latest_pycharm_dir" ]]; then
        log_warn "No PyCharm configuration found"
        return 1
    fi
    
    [[ -d "$latest_pycharm_dir/colors" ]] && cp -R "$latest_pycharm_dir/colors" "$pycharm_backup_dir/"
    [[ -d "$latest_pycharm_dir/keymaps" ]] && cp -R "$latest_pycharm_dir/keymaps" "$pycharm_backup_dir/"
    [[ -d "$latest_pycharm_dir/templates" ]] && cp -R "$latest_pycharm_dir/templates" "$pycharm_backup_dir/"
    [[ -d "$latest_pycharm_dir/fileTemplates" ]] && cp -R "$latest_pycharm_dir/fileTemplates" "$pycharm_backup_dir/"
    [[ -d "$latest_pycharm_dir/codestyles" ]] && cp -R "$latest_pycharm_dir/codestyles" "$pycharm_backup_dir/"
    [[ -d "$latest_pycharm_dir/inspection" ]] && cp -R "$latest_pycharm_dir/inspection" "$pycharm_backup_dir/"
    
    [[ -f "$latest_pycharm_dir/options/ide.general.xml" ]] && {
        mkdir -p "$pycharm_backup_dir/options"
        cp "$latest_pycharm_dir/options/"*.xml "$pycharm_backup_dir/options/" 2>/dev/null || true
    }
    
    [[ -z "$1" ]] && log_success "PyCharm settings backed up to: ./configs/$(basename "$backup_dir")/pycharm"
    return 0
}

restore_vscode_settings() {
    local source_dir="$1"
    
    if [[ ! -d "$source_dir" ]]; then
        log_error "Source directory not found: $source_dir"
        return 1
    fi
    
    log_info "Restoring VS Code settings from: $source_dir"
    
    mkdir -p "$VSCODE_CONFIG_DIR"
    
    [[ -f "$source_dir/settings.json" ]] && cp "$source_dir/settings.json" "$VSCODE_CONFIG_DIR/"
    [[ -f "$source_dir/keybindings.json" ]] && cp "$source_dir/keybindings.json" "$VSCODE_CONFIG_DIR/"
    [[ -f "$source_dir/tasks.json" ]] && cp "$source_dir/tasks.json" "$VSCODE_CONFIG_DIR/"
    [[ -f "$source_dir/launch.json" ]] && cp "$source_dir/launch.json" "$VSCODE_CONFIG_DIR/"
    
    [[ -d "$source_dir/snippets" ]] && cp -R "$source_dir/snippets" "$VSCODE_CONFIG_DIR/"
    
    if [[ -f "$source_dir/extensions.txt" ]] && command_exists code; then
        log_info "Installing VS Code extensions..."
        while IFS= read -r extension; do
            [[ -n "$extension" ]] && code --install-extension "$extension" --force 2>/dev/null || true
        done < "$source_dir/extensions.txt"
    fi
    
    log_success "VS Code settings restored successfully"
    return 0
}

restore_cursor_settings() {
    local source_dir="$1"
    
    if [[ ! -d "$source_dir" ]]; then
        log_error "Source directory not found: $source_dir"
        return 1
    fi
    
    log_info "Restoring Cursor AI settings from: $source_dir"
    
    mkdir -p "$CURSOR_CONFIG_DIR"
    
    [[ -f "$source_dir/settings.json" ]] && cp "$source_dir/settings.json" "$CURSOR_CONFIG_DIR/"
    [[ -f "$source_dir/keybindings.json" ]] && cp "$source_dir/keybindings.json" "$CURSOR_CONFIG_DIR/"
    [[ -f "$source_dir/tasks.json" ]] && cp "$source_dir/tasks.json" "$CURSOR_CONFIG_DIR/"
    [[ -f "$source_dir/launch.json" ]] && cp "$source_dir/launch.json" "$CURSOR_CONFIG_DIR/"
    
    [[ -d "$source_dir/snippets" ]] && cp -R "$source_dir/snippets" "$CURSOR_CONFIG_DIR/"
    
    if [[ -f "$source_dir/extensions.txt" ]] && command_exists cursor; then
        log_info "Installing Cursor AI extensions..."
        while IFS= read -r extension; do
            [[ -n "$extension" ]] && cursor --install-extension "$extension" --force 2>/dev/null || true
        done < "$source_dir/extensions.txt"
    fi
    
    log_success "Cursor AI settings restored successfully"
    return 0
}

restore_pycharm_settings() {
    local source_dir="$1"
    
    if [[ ! -d "$source_dir" ]]; then
        log_error "Source directory not found: $source_dir"
        return 1
    fi
    
    log_info "Restoring PyCharm settings from: $source_dir"
    
    local latest_pycharm_dir=$(find "$PYCHARM_CONFIG_DIR" -name "PyCharm*" -type d | sort -V | tail -1)
    
    if [[ -z "$latest_pycharm_dir" ]]; then
        log_warn "No PyCharm installation found. Please install PyCharm first."
        return 1
    fi
    
    [[ -d "$source_dir/colors" ]] && cp -R "$source_dir/colors" "$latest_pycharm_dir/"
    [[ -d "$source_dir/keymaps" ]] && cp -R "$source_dir/keymaps" "$latest_pycharm_dir/"
    [[ -d "$source_dir/templates" ]] && cp -R "$source_dir/templates" "$latest_pycharm_dir/"
    [[ -d "$source_dir/fileTemplates" ]] && cp -R "$source_dir/fileTemplates" "$latest_pycharm_dir/"
    [[ -d "$source_dir/codestyles" ]] && cp -R "$source_dir/codestyles" "$latest_pycharm_dir/"
    [[ -d "$source_dir/inspection" ]] && cp -R "$source_dir/inspection" "$latest_pycharm_dir/"
    
    [[ -d "$source_dir/options" ]] && {
        mkdir -p "$latest_pycharm_dir/options"
        cp "$source_dir/options/"*.xml "$latest_pycharm_dir/options/" 2>/dev/null || true
    }
    
    log_success "PyCharm settings restored successfully"
    return 0
}

import_vscode_to_cursor() {
    local source_dir="$1"
    
    if [[ ! -d "$source_dir" ]]; then
        log_error "VS Code backup directory not found: $source_dir"
        return 1
    fi
    
    log_info "Importing VS Code settings to Cursor AI..."
    
    mkdir -p "$CURSOR_CONFIG_DIR"
    
    [[ -f "$source_dir/settings.json" ]] && cp "$source_dir/settings.json" "$CURSOR_CONFIG_DIR/"
    [[ -f "$source_dir/keybindings.json" ]] && cp "$source_dir/keybindings.json" "$CURSOR_CONFIG_DIR/"
    [[ -f "$source_dir/tasks.json" ]] && cp "$source_dir/tasks.json" "$CURSOR_CONFIG_DIR/"
    [[ -f "$source_dir/launch.json" ]] && cp "$source_dir/launch.json" "$CURSOR_CONFIG_DIR/"
    
    [[ -d "$source_dir/snippets" ]] && cp -R "$source_dir/snippets" "$CURSOR_CONFIG_DIR/"
    
    if [[ -f "$source_dir/extensions.txt" ]] && command_exists cursor; then
        log_info "Installing VS Code extensions in Cursor AI..."
        while IFS= read -r extension; do
            [[ -n "$extension" ]] && cursor --install-extension "$extension" --force 2>/dev/null || true
        done < "$source_dir/extensions.txt"
    fi
    
    log_success "VS Code settings imported to Cursor AI successfully"
    return 0
}

import_cursor_to_vscode() {
    local source_dir="$1"
    
    if [[ ! -d "$source_dir" ]]; then
        log_error "Cursor AI backup directory not found: $source_dir"
        return 1
    fi
    
    log_info "Importing Cursor AI settings to VS Code..."
    
    mkdir -p "$VSCODE_CONFIG_DIR"
    
    [[ -f "$source_dir/settings.json" ]] && cp "$source_dir/settings.json" "$VSCODE_CONFIG_DIR/"
    [[ -f "$source_dir/keybindings.json" ]] && cp "$source_dir/keybindings.json" "$VSCODE_CONFIG_DIR/"
    [[ -f "$source_dir/tasks.json" ]] && cp "$source_dir/tasks.json" "$VSCODE_CONFIG_DIR/"
    [[ -f "$source_dir/launch.json" ]] && cp "$source_dir/launch.json" "$VSCODE_CONFIG_DIR/"
    
    [[ -d "$source_dir/snippets" ]] && cp -R "$source_dir/snippets" "$VSCODE_CONFIG_DIR/"
    
    if [[ -f "$source_dir/extensions.txt" ]] && command_exists code; then
        log_info "Installing Cursor AI extensions in VS Code..."
        while IFS= read -r extension; do
            [[ -n "$extension" ]] && code --install-extension "$extension" --force 2>/dev/null || true
        done < "$source_dir/extensions.txt"
    fi
    
    log_success "Cursor AI settings imported to VS Code successfully"
    return 0
}

backup_all_ide_settings() {
    log_info "Starting comprehensive IDE backup..."
    
    local backup_dir=$(init_ide_backup_dir)
    
    backup_vscode_settings "$backup_dir"
    backup_vscode_themes "$backup_dir"
    
    backup_cursor_settings "$backup_dir"
    backup_cursor_themes "$backup_dir"
    
    backup_pycharm_settings "$backup_dir"
    
    log_success "All IDE settings backed up to: ./configs/$(basename "$backup_dir")"
    return 0
}

show_ide_backup_menu() {
    echo "IDE Backup & Restore Menu"
    echo "========================="
    echo "1) Backup VS Code settings"
    echo "2) Backup Cursor AI settings"
    echo "3) Backup PyCharm settings"
    echo "4) Backup all IDE settings"
    echo
    echo "5) Restore VS Code settings"
    echo "6) Restore Cursor AI settings" 
    echo "7) Restore PyCharm settings"
    echo
    echo "8) Import VS Code settings to Cursor AI"
    echo "9) Import Cursor AI settings to VS Code"
    echo
    echo "0) Back to main menu"
}

handle_ide_backup_choice() {
    local choice="$1"
    
    case "$choice" in
        1) backup_vscode_settings && backup_vscode_themes ;;
        2) backup_cursor_settings && backup_cursor_themes ;;
        3) backup_pycharm_settings ;;
        4) backup_all_ide_settings ;;
        5) 
            echo "Available backups:"
            ls -la "$BACKUP_DIR" 2>/dev/null || echo "No backups found"
            read -p "Enter backup directory name: " backup_name
            [[ -n "$backup_name" ]] && restore_vscode_settings "$BACKUP_DIR/$backup_name/vscode"
            ;;
        6) 
            echo "Available backups:"
            ls -la "$BACKUP_DIR" 2>/dev/null || echo "No backups found"
            read -p "Enter backup directory name: " backup_name
            [[ -n "$backup_name" ]] && restore_cursor_settings "$BACKUP_DIR/$backup_name/cursor"
            ;;
        7) 
            echo "Available backups:"
            ls -la "$BACKUP_DIR" 2>/dev/null || echo "No backups found"
            read -p "Enter backup directory name: " backup_name
            [[ -n "$backup_name" ]] && restore_pycharm_settings "$BACKUP_DIR/$backup_name/pycharm"
            ;;
        8) 
            echo "Available backups:"
            ls -la "$BACKUP_DIR" 2>/dev/null || echo "No backups found"
            read -p "Enter backup directory name: " backup_name
            [[ -n "$backup_name" ]] && import_vscode_to_cursor "$BACKUP_DIR/$backup_name/vscode"
            ;;
        9) 
            echo "Available backups:"
            ls -la "$BACKUP_DIR" 2>/dev/null || echo "No backups found"
            read -p "Enter backup directory name: " backup_name
            [[ -n "$backup_name" ]] && import_cursor_to_vscode "$BACKUP_DIR/$backup_name/cursor"
            ;;
        0) return 0 ;;
        *) log_error "Invalid choice" ;;
    esac
}

ide_backup_menu() {
    while true; do
        show_ide_backup_menu
        read -p "Choose an option: " choice
        handle_ide_backup_choice "$choice"
        [[ "$choice" == "0" ]] && break
        echo
    done
} 