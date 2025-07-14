#!/bin/bash

# Homebrew management module

install_homebrew() {
    if is_brew_installed; then
        log_success "Homebrew already installed at $(brew --prefix)"
        return 0
    fi
    
    log_info "Installing Homebrew..."
    
    # Check Xcode CLI tools
    if ! xcode-select -p >/dev/null 2>&1; then
        log_info "Installing Xcode Command Line Tools..."
        xcode-select --install
        log_info "Complete installation and run script again"
        read -p "Press Enter when done..."
        
        if ! xcode-select -p >/dev/null 2>&1; then
            log_error "Xcode CLI tools required"
            return 1
        fi
    fi
    
    # Install Homebrew
    local url="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
    if ! /bin/bash -c "$(curl -fsSL "$url")"; then
        log_error "Homebrew installation failed"
        return 1
    fi
    
    # Configure environment
    local brew_prefix=$(get_brew_prefix)
    local shell_profile="$HOME/.zprofile"
    
    [[ ! -f "$shell_profile" ]] && touch "$shell_profile"
    
    if ! grep -q "brew shellenv" "$shell_profile"; then
        echo "" >> "$shell_profile"
        echo "# Homebrew"
        echo "eval \"\$($brew_prefix/bin/brew shellenv)\"" >> "$shell_profile"
        log_info "Added Homebrew to $shell_profile"
    fi
    
    eval "$($brew_prefix/bin/brew shellenv)" 2>/dev/null || true
    
    # Post-install setup
    brew analytics off
    brew update
    
    # Add useful taps
    for tap in "homebrew/cask-versions" "homebrew/cask-fonts" "hashicorp/tap"; do
        if ! brew tap | grep -q "^$tap\$"; then
            brew tap "$tap" || log_warn "Failed to add tap: $tap"
        fi
    done
    
    # Install essentials
    for tool in git curl wget; do
        if ! brew list "$tool" >/dev/null 2>&1; then
            brew install "$tool" || log_warn "Failed to install: $tool"
        fi
    done
    
    log_success "Homebrew installed successfully"
}

update_homebrew() {
    if ! is_brew_installed; then
        log_error "Homebrew not installed"
        return 1
    fi
    
    log_info "Updating Homebrew..."
    
    if ! brew update; then
        log_error "Failed to update Homebrew"
        return 1
    fi
    
    local outdated=$(brew outdated)
    if [[ -n "$outdated" ]]; then
        log_info "Outdated packages:"
        echo "$outdated"
        
        if confirm "Upgrade outdated packages?" "y"; then
            brew upgrade || log_warn "Some packages failed to upgrade"
        fi
    else
        log_success "All packages up to date"
    fi
    
    if confirm "Clean up old versions?" "y"; then
        brew cleanup || log_warn "Cleanup issues"
        log_success "Cleanup completed"
    fi
}

show_homebrew_status() {
    echo "Homebrew Status"
    echo "==============="
    
    if ! is_brew_installed; then
        echo "Status: Not installed"
        return 0
    fi
    
    echo "Status: Installed"
    echo "Version: $(brew --version | head -1)"
    echo "Prefix: $(brew --prefix)"
    echo
    echo "Packages:"
    echo "  Formulae: $(brew list --formula 2>/dev/null | wc -l | tr -d ' ')"
    echo "  Casks: $(brew list --cask 2>/dev/null | wc -l | tr -d ' ')"
    echo
    echo "Taps:"
    brew tap | sed 's/^/  /'
    echo
    
    if brew doctor --quiet >/dev/null 2>&1; then
        echo "Health: ✅ No issues"
    else
        echo "Health: ⚠️  Issues detected (run 'brew doctor')"
    fi
}

uninstall_homebrew() {
    if ! is_brew_installed; then
        log_warn "Homebrew not installed"
        return 0
    fi
    
    echo "⚠️  This will remove Homebrew and all packages!"
    show_homebrew_status
    echo
    
    if ! confirm "Uninstall Homebrew?" "n"; then
        log_info "Cancelled"
        return 0
    fi
    
    if ! confirm "This cannot be undone. Continue?" "n"; then
        log_info "Cancelled"
        return 0
    fi
    
    log_info "Uninstalling Homebrew..."
    
    # Backup package lists
    local backup_dir="${HOME}/.macos-setup/backups"
    mkdir -p "$backup_dir"
    
    brew list --formula > "$backup_dir/homebrew-formulae-$(date +%Y%m%d).txt" 2>/dev/null || true
    brew list --cask > "$backup_dir/homebrew-casks-$(date +%Y%m%d).txt" 2>/dev/null || true
    log_info "Package lists backed up to: $backup_dir"
    
    # Uninstall
    local url="https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh"
    /bin/bash -c "$(curl -fsSL "$url")"
    
    # Clean up shell profile
    local shell_profile="$HOME/.zprofile"
    if [[ -f "$shell_profile" ]]; then
        sed -i.bak '/# Homebrew/d' "$shell_profile" 2>/dev/null || true
        sed -i.bak '/brew shellenv/d' "$shell_profile" 2>/dev/null || true
        log_info "Removed from $shell_profile"
    fi
    
    log_success "Homebrew uninstalled"
}

fix_homebrew() {
    if ! is_brew_installed; then
        log_error "Homebrew not installed"
        return 1
    fi
    
    log_info "Fixing Homebrew issues..."
    
    if brew doctor; then
        log_success "No issues found"
    else
        log_warn "Issues found (see above)"
    fi
    
    if confirm "Fix permissions?" "y"; then
        local brew_prefix=$(brew --prefix)
        sudo chown -R "$(whoami)" "$brew_prefix"
        
        for dir in bin etc include lib sbin share var; do
            [[ -d "$brew_prefix/$dir" ]] && chmod 755 "$brew_prefix/$dir"
        done
        
        log_success "Permissions fixed"
    fi
    
    if confirm "Update and upgrade?" "y"; then
        update_homebrew
    fi
}

cleanup_homebrew() {
    if ! is_brew_installed; then
        log_error "Homebrew not installed"
        return 1
    fi
    
    log_info "Cleaning up Homebrew..."
    
    if confirm "Remove old versions?" "y"; then
        brew cleanup && log_success "Cleanup completed"
    fi
}

manage_taps() {
    if ! is_brew_installed; then
        log_error "Homebrew not installed"
        return 1
    fi
    
    while true; do
        echo
        log_info "Homebrew Taps"
        echo "Current taps:"
        brew tap | sed 's/^/  /' || echo "  None"
        echo
        echo "1) Add tap"
        echo "2) Remove tap"
        echo "3) Add common taps"
        echo "0) Back"
        
        read -p "Choice [0-3]: " choice
        
        case "$choice" in
            1)
                read -p "Tap name (e.g., user/repo): " tap
                [[ -n "$tap" ]] && brew tap "$tap" && log_success "Added: $tap"
                ;;
            2)
                read -p "Tap name to remove: " tap
                [[ -n "$tap" ]] && brew untap "$tap" && log_success "Removed: $tap"
                ;;
            3)
                for tap in "homebrew/cask-versions" "homebrew/cask-fonts" "hashicorp/tap"; do
                    if ! brew tap | grep -q "^$tap\$"; then
                        brew tap "$tap" && log_success "Added: $tap"
                    fi
                done
                ;;
            0) break ;;
            *) log_error "Invalid choice" ;;
        esac
    done
}

show_homebrew_menu() {
    while true; do
        echo
        log_info "Homebrew Management"
        
        if is_brew_installed; then
            echo "✅ Homebrew installed"
        else
            echo "❌ Homebrew not installed"
        fi
        
        echo
        echo "1) Install Homebrew"
        echo "2) Update & upgrade"
        echo "3) Show status"
        echo "4) Fix issues"
        echo "5) Manage taps"
        echo "6) Cleanup"
        echo "7) Uninstall"
        echo "0) Back"
        
        read -p "Choice [0-7]: " choice
        
        case "$choice" in
            1) install_homebrew ;;
            2) update_homebrew ;;
            3) show_homebrew_status ;;
            4) fix_homebrew ;;
            5) manage_taps ;;
            6) cleanup_homebrew ;;
            7) uninstall_homebrew ;;
            0) break ;;
            *) log_error "Invalid choice: $choice" ;;
        esac
        
        [[ "$choice" != "0" ]] && { echo; read -p "Press Enter to continue..."; }
    done
} 