#!/bin/bash

# Configuration backup module

BACKUP_DIR="$SCRIPT_DIR/configs"

init_backup_dir() {
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_dir="$BACKUP_DIR/$timestamp"
    mkdir -p "$backup_dir"
    echo "$backup_dir"
}

export_ssh_config() {
    log_info "Exporting SSH config..."
    
    local ssh_config="$HOME/.ssh/config"
    local backup_dir="${1:-$(init_backup_dir)}"
    
    if [[ ! -f "$ssh_config" ]]; then
        log_warn "SSH config not found"
        return 1
    fi
    
    cp "$ssh_config" "$backup_dir/ssh_config" && {
        [[ -z "$1" ]] && log_success "SSH config exported to: ./configs/$(basename "$backup_dir")/ssh_config"
        return 0
    } || {
        log_error "Failed to export SSH config"
        return 1
    }
}

export_zshrc() {
    log_info "Exporting .zshrc..."
    
    local zshrc="$HOME/.zshrc"
    local backup_dir="${1:-$(init_backup_dir)}"
    
    if [[ ! -f "$zshrc" ]]; then
        log_warn ".zshrc not found"
        return 1
    fi
    
    cp "$zshrc" "$backup_dir/zshrc" && {
        [[ -z "$1" ]] && log_success ".zshrc exported to: ./configs/$(basename "$backup_dir")/zshrc"
        return 0
    } || {
        log_error "Failed to export .zshrc"
        return 1
    }
}

export_aerospace_config() {
    log_info "Exporting Aerospace config..."
    
    local aerospace_dir="$HOME/.config/aerospace"
    local backup_dir="${1:-$(init_backup_dir)}"
    
    if [[ ! -d "$aerospace_dir" ]]; then
        log_warn "Aerospace config not found"
        return 1
    fi
    
    cp -r "$aerospace_dir" "$backup_dir/aerospace" && {
        [[ -z "$1" ]] && log_success "Aerospace config exported to: ./configs/$(basename "$backup_dir")/aerospace"
        return 0
    } || {
        log_error "Failed to export Aerospace config"
        return 1
    }
}

export_kitty_config() {
    log_info "Exporting Kitty config..."
    
    local kitty_conf="$HOME/.config/kitty/kitty.conf"
    local backup_dir="${1:-$(init_backup_dir)}"
    
    if [[ ! -f "$kitty_conf" ]]; then
        log_warn "Kitty config not found"
        return 1
    fi
    
    cp "$kitty_conf" "$backup_dir/kitty.conf" && {
        [[ -z "$1" ]] && log_success "Kitty config exported to: ./configs/$(basename "$backup_dir")/kitty.conf"
        return 0
    } || {
        log_error "Failed to export Kitty config"
        return 1
    }
}

export_yazi_config() {
    log_info "Exporting Yazi config..."
    
    local yazi_dir="$HOME/.config/yazi"
    local backup_dir="${1:-$(init_backup_dir)}"
    
    if [[ ! -d "$yazi_dir" ]]; then
        log_warn "Yazi config not found"
        return 1
    fi
    
    cp -r "$yazi_dir" "$backup_dir/yazi" && {
        [[ -z "$1" ]] && log_success "Yazi config exported to: ./configs/$(basename "$backup_dir")/yazi"
        return 0
    } || {
        log_error "Failed to export Yazi config"
        return 1
    }
}

export_starship_config() {
    log_info "Exporting Starship config..."
    
    local backup_dir="${1:-$(init_backup_dir)}"
    local found_files=0
    
    mkdir -p "$backup_dir/starship"
    
    shopt -s nullglob  
    local starship_files=()
    starship_files+=("$HOME"/.config/starship*.toml)
    starship_files+=("$HOME"/.config/starship*.yaml)
    starship_files+=("$HOME"/.config/starship*.yml)
    shopt -u nullglob  
    
    for file in "${starship_files[@]}"; do
        if [[ -f "$file" ]]; then
            local filename=$(basename "$file")
            cp "$file" "$backup_dir/starship/$filename" && ((found_files++))
        fi
    done
    
    if [[ $found_files -eq 0 ]]; then
        log_warn "No Starship config files found"
        return 1
    fi
    
    [[ -z "$1" ]] && log_success "Starship config exported to: ./configs/$(basename "$backup_dir")/starship ($found_files files)"
    return 0
}

export_all_configs() {
    log_info "Exporting all configurations..."
    
    local backup_dir=$(init_backup_dir)
    
    echo "Creating backup in: ./configs/$(basename "$backup_dir")"
    echo
    
    local exported=0
    local total=6
    local results=()
    
    if export_ssh_config "$backup_dir"; then
        results+=("✅ SSH config")
        ((exported++))
    else
        results+=("❌ SSH config")
    fi
    
    if export_zshrc "$backup_dir"; then
        results+=("✅ .zshrc")
        ((exported++))
    else
        results+=("❌ .zshrc")
    fi
    
    if export_aerospace_config "$backup_dir"; then
        results+=("✅ Aerospace")
        ((exported++))
    else
        results+=("❌ Aerospace")
    fi
    
    if export_kitty_config "$backup_dir"; then
        results+=("✅ Kitty")
        ((exported++))
    else
        results+=("❌ Kitty")
    fi
    
    if export_yazi_config "$backup_dir"; then
        results+=("✅ Yazi")
        ((exported++))
    else
        results+=("❌ Yazi")
    fi
    
    if export_starship_config "$backup_dir"; then
        results+=("✅ Starship")
        ((exported++))
    else
        results+=("❌ Starship")
    fi
    
    echo
    echo "Backup Summary:"
    for result in "${results[@]}"; do
        echo "  $result"
    done
    echo
    log_success "Exported $exported/$total configurations"
    log_info "Location: ./configs/$(basename "$backup_dir")"
}

show_backup_menu() {
    while true; do
        echo
        log_info "📦 Configuration Backup"
        
        echo "1) SSH config"
        echo "2) .zshrc"
        echo "3) Aerospace config"
        echo "4) Kitty config"
        echo "5) Yazi config"
        echo "6) Starship config"
        echo "7) Export all"
        echo "0) Back"
        
        read -p "Choice [0-7]: " choice
        
        case "$choice" in
            1) export_ssh_config ;;
            2) export_zshrc ;;
            3) export_aerospace_config ;;
            4) export_kitty_config ;;
            5) export_yazi_config ;;
            6) export_starship_config ;;
            7) export_all_configs ;;
            0) break ;;
            *) log_error "Invalid choice" ;;
        esac
        
        [[ "$choice" != "0" ]] && { echo; read -p "Press Enter to continue..."; }
    done
} 