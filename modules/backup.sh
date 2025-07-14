#!/bin/bash

# =============================================================================
# Backup & Export Module
# Export and backup configuration files and directories
# =============================================================================

# Backup directory
readonly BACKUP_BASE_DIR="$SCRIPT_DIR/configs"

# =============================================================================
# Backup Functions
# =============================================================================

# Initialize backup directory
init_backup_dir() {
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_dir="$BACKUP_BASE_DIR/$timestamp"
    
    mkdir -p "$backup_dir"
    echo "$backup_dir"
}

# Export SSH config
export_ssh_config() {
    log_info "Exporting SSH configuration..."
    
    local ssh_config="$HOME/.ssh/config"
    local backup_dir="${1:-$(init_backup_dir)}"
    
    if [[ ! -f "$ssh_config" ]]; then
        log_warn "SSH config file not found: $ssh_config"
        return 1
    fi
    
    local export_path="$backup_dir/ssh_config"
    
    cp "$ssh_config" "$export_path" || {
        log_error "Failed to export SSH config"
        return 1
    }
    
    if [[ -z "$1" ]]; then
        log_success "SSH config exported to: ./configs/$(basename "$backup_dir")/ssh_config"
    fi
    return 0
}

# Export .zshrc
export_zshrc() {
    log_info "Exporting .zshrc configuration..."
    
    local zshrc="$HOME/.zshrc"
    local backup_dir="${1:-$(init_backup_dir)}"
    
    if [[ ! -f "$zshrc" ]]; then
        log_warn ".zshrc file not found: $zshrc"
        log_info "Checking for alternative zsh configs..."
        if [[ -f "$HOME/.zprofile" ]]; then
            log_info "Found .zprofile instead"
        fi
        if [[ -f "$HOME/.zshenv" ]]; then
            log_info "Found .zshenv instead"
        fi
        return 1
    fi
    
    if [[ ! -r "$zshrc" ]]; then
        log_error ".zshrc file exists but is not readable: $zshrc"
        return 1
    fi
    
    if [[ ! -d "$backup_dir" ]]; then
        log_error "Failed to create backup directory: $backup_dir"
        return 1
    fi
    
    local export_path="$backup_dir/zshrc"
    
    cp "$zshrc" "$export_path" || {
        log_error "Failed to export .zshrc (copy command failed)"
        log_error "Source: $zshrc"
        log_error "Target: $export_path"
        return 1
    }
    
    if [[ -z "$1" ]]; then
        log_success ".zshrc exported to: ./configs/$(basename "$backup_dir")/zshrc"
    fi
    return 0
}

# Export Aerospace configuration
export_aerospace_config() {
    log_info "Exporting Aerospace configuration..."
    
    local aerospace_dir="$HOME/.config/aerospace"
    local backup_dir="${1:-$(init_backup_dir)}"
    
    if [[ ! -d "$aerospace_dir" ]]; then
        log_warn "Aerospace config directory not found: $aerospace_dir"
        return 1
    fi
    
    local export_path="$backup_dir/aerospace"
    
    cp -r "$aerospace_dir" "$export_path" || {
        log_error "Failed to export Aerospace config"
        return 1
    }
    
    if [[ -z "$1" ]]; then
        log_success "Aerospace config exported to: ./configs/$(basename "$backup_dir")/aerospace"
    fi
    return 0
}

# Export Kitty configuration (kitty.conf only)
export_kitty_config() {
    log_info "Exporting Kitty configuration..."
    
    local kitty_conf="$HOME/.config/kitty/kitty.conf"
    local backup_dir="${1:-$(init_backup_dir)}"
    
    if [[ ! -f "$kitty_conf" ]]; then
        log_warn "Kitty config file not found: $kitty_conf"
        return 1
    fi
    
    local export_path="$backup_dir/kitty.conf"
    
    cp "$kitty_conf" "$export_path" || {
        log_error "Failed to export Kitty config"
        return 1
    }
    
    if [[ -z "$1" ]]; then
        log_success "Kitty config exported to: ./configs/$(basename "$backup_dir")/kitty.conf"
    fi
    return 0
}

# Export Yazi configuration
export_yazi_config() {
    log_info "Exporting Yazi configuration..."
    
    local yazi_dir="$HOME/.config/yazi"
    local backup_dir="${1:-$(init_backup_dir)}"
    
    if [[ ! -d "$yazi_dir" ]]; then
        log_warn "Yazi config directory not found: $yazi_dir"
        return 1
    fi
    
    local export_path="$backup_dir/yazi"
    
    cp -r "$yazi_dir" "$export_path" || {
        log_error "Failed to export Yazi config"
        return 1
    }
    
    if [[ -z "$1" ]]; then
        log_success "Yazi config exported to: ./configs/$(basename "$backup_dir")/yazi"
    fi
    return 0
}

# Export all configurations
export_all_configs() {
    log_info "Exporting all configurations..."
    
    local backup_dir=$(init_backup_dir)
    
    # Verify backup directory was created correctly
    if [[ ! -d "$backup_dir" ]]; then
        log_error "CRITICAL: Backup directory was not created: $backup_dir"
        return 1
    fi
    
    # Verify we're not backing up to a dangerous location
    if [[ "$backup_dir" == "$HOME" ]] || [[ "$backup_dir" == "$HOME/.ssh" ]] || [[ "$backup_dir" == "$HOME/.config" ]]; then
        log_error "CRITICAL: Backup directory is in a dangerous location: $backup_dir"
        return 1
    fi
    
    echo "Creating unified backup in: ./configs/$(basename "$backup_dir")"
    echo
    
    # Track results
    local export_count=0
    local total_count=5
    local results=()
    
    # Export SSH config
    if export_ssh_config "$backup_dir"; then
        results+=("✅ SSH config")
        ((export_count++))
    else
        results+=("❌ SSH config (failed)")
    fi
    
    # Export .zshrc
    if export_zshrc "$backup_dir"; then
        results+=("✅ .zshrc")
        ((export_count++))
    else
        results+=("❌ zshrc (failed)")
    fi
    
    # Export Aerospace config
    if export_aerospace_config "$backup_dir"; then
        results+=("✅ Aerospace config")
        ((export_count++))
    else
        results+=("❌ Aerospace config (failed)")
    fi
    
    # Export Kitty config
    if export_kitty_config "$backup_dir"; then
        results+=("✅ Kitty config")
        ((export_count++))
    else
        results+=("❌ Kitty config (failed)")
    fi
    
    # Export Yazi config
    if export_yazi_config "$backup_dir"; then
        results+=("✅ Yazi config")
        ((export_count++))
    else
        results+=("❌ Yazi config (failed)")
    fi
    
    # Display summary
    echo
    echo "📋 Backup Summary:"
    echo "=================="
    for result in "${results[@]}"; do
        echo "  $result"
    done
    echo
    log_success "Backup completed: $export_count/$total_count configurations exported"
    log_info "Backup location: ./configs/$(basename "$backup_dir")"
}

# =============================================================================
# Backup Menu
# =============================================================================

show_backup_menu() {
    while true; do
        echo
        log_info "📦 Configuration Backup & Export"
        echo "=================================="
        echo
        echo "1) Export SSH config (~/.ssh/config)"
        echo "2) Export .zshrc configuration" 
        echo "3) Export Aerospace config (~/.config/aerospace)"
        echo "4) Export Kitty config (~/.config/kitty/kitty.conf)"
        echo "5) Export Yazi config (~/.config/yazi)"
        echo "9) Export all"
        
        local choice=$(get_input "Enter your choice" "0")
        
        case "$choice" in
            "1") export_ssh_config ;;
            "2") export_zshrc ;;
            "3") export_aerospace_config ;;
            "4") export_kitty_config ;;
            "5") export_yazi_config ;;
            "9") export_all_configs ;;
            *) log_error "Invalid choice: $choice" ;;
        esac
        
        if [[ "$choice" != "0" ]]; then
            echo
            read -p "Press Enter to continue..." -r
        fi
    done
} 