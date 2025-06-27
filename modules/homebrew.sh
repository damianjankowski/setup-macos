#!/bin/bash

# =============================================================================
# Homebrew Management Module
# Installation, configuration, and management of Homebrew
# =============================================================================

# =============================================================================
# Homebrew Installation
# =============================================================================

# Install Homebrew if not already installed
install_homebrew() {
    if is_brew_installed; then
        log_success "Homebrew is already installed at $(brew --prefix)"
        return 0
    fi
    
    log_info "Installing Homebrew..."

    
    # Check system requirements
    check_homebrew_requirements || return 1
    
    # Download and install Homebrew
    local install_script_url="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
    
    if ! validate_url "$install_script_url"; then
        log_error "Invalid Homebrew installation URL"
        return 1
    fi
    
    log_info "Downloading Homebrew installation script..."
    if ! /bin/bash -c "$(curl -fsSL "$install_script_url")"; then
        log_error "Homebrew installation failed"
        return 1
    fi
    
    # Configure shell environment
    configure_homebrew_environment
    
    # Verify installation
    if is_brew_installed; then
        log_success "Homebrew installed successfully"
        post_homebrew_install
    else
        log_error "Homebrew installation verification failed"
        return 1
    fi
}

# Check Homebrew system requirements
check_homebrew_requirements() {
    log_info "Checking Homebrew requirements..."
    
    # Check macOS version
    local macos_version=$(get_macos_version)
    local major_version=$(echo "$macos_version" | cut -d. -f1)
    
    if [[ $major_version -lt 10 ]]; then
        log_error "Homebrew requires macOS 10.15 or later (found: $macos_version)"
        return 1
    fi
    
    # Check if Xcode Command Line Tools are installed
    if ! xcode-select -p >/dev/null 2>&1; then
        log_info "Installing Xcode Command Line Tools..."
        xcode-select --install
        
        log_info "Please complete the Xcode Command Line Tools installation and run this script again."
        log_info "Press any key when installation is complete..."
        read -n 1 -s
        
        # Verify installation
        if ! xcode-select -p >/dev/null 2>&1; then
            log_error "Xcode Command Line Tools installation failed or incomplete"
            return 1
        fi
    fi
    
    log_success "System requirements check passed"
    return 0
}

# Configure Homebrew environment in shell
configure_homebrew_environment() {
    log_info "Configuring Homebrew environment..."
    
    local brew_prefix=$(get_brew_prefix)
    local shell_profile="$HOME/.zprofile"
    
    # Create shell profile if it doesn't exist
    [[ ! -f "$shell_profile" ]] && touch "$shell_profile"
    
    # Add Homebrew to PATH if not already present
    local brew_env_line="eval \"\$($brew_prefix/bin/brew shellenv)\""
    
    if ! grep -q "brew shellenv" "$shell_profile"; then
        echo "" >> "$shell_profile"
        echo "# Homebrew environment configuration" >> "$shell_profile"
        echo "$brew_env_line" >> "$shell_profile"
        log_success "Added Homebrew environment to $shell_profile"
    fi
    
    # Source the environment for current session
    eval "$($brew_prefix/bin/brew shellenv)" 2>/dev/null || true
}

# Post-installation configuration
post_homebrew_install() {
    log_info "Performing post-installation configuration..."
    
    # Disable analytics by default
    brew analytics off
    log_info "Disabled Homebrew analytics"
    
    # Add useful taps
    add_homebrew_taps
    
    # Update package database
    log_info "Updating Homebrew package database..."
    brew update || log_warn "Failed to update Homebrew"
    
    # Install essential tools
    install_essential_tools
}

# Add commonly used Homebrew taps
add_homebrew_taps() {
    log_info "Adding useful Homebrew taps..."
    
    local taps=(
        "homebrew/cask-versions"
        "homebrew/cask-fonts"
        "hashicorp/tap"
    )
    
    for tap in "${taps[@]}"; do
        if ! brew tap | grep -q "^$tap\$"; then
            log_info "Adding tap: $tap"
            brew tap "$tap" || log_warn "Failed to add tap: $tap"
        else
            log_debug "Tap already added: $tap"
        fi
    done
}

# Install essential tools after Homebrew installation
install_essential_tools() {
    log_info "Installing essential tools..."
    
    local essential_tools=(
        "git"
        "curl"
        "wget"
    )
    
    for tool in "${essential_tools[@]}"; do
        if ! brew list "$tool" >/dev/null 2>&1; then
            log_info "Installing essential tool: $tool"
            brew install "$tool" || log_warn "Failed to install: $tool"
        fi
    done
}

# =============================================================================
# Homebrew Management
# =============================================================================

# Update Homebrew and all packages
update_homebrew() {
    if ! is_brew_installed; then
        log_error "Homebrew is not installed"
        return 1
    fi

    
    log_info "Updating Homebrew..."
    
    # Update Homebrew itself
    if ! brew update; then
        log_error "Failed to update Homebrew"
        return 1
    fi
    
    # Show outdated packages
    local outdated=$(brew outdated)
    if [[ -n "$outdated" ]]; then
        log_info "Outdated packages:"
        echo "$outdated"
        
        if confirm "Upgrade outdated packages?" "y"; then
            brew upgrade || log_warn "Some packages failed to upgrade"
        fi
    else
        log_success "All packages are up to date"
    fi
    
    # Cleanup old versions
    if confirm "Clean up old package versions?" "y"; then
        brew cleanup || log_warn "Cleanup encountered some issues"
        log_success "Cleanup completed"
    fi
}

# Show Homebrew status and information
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
    echo "Repository: $(brew --repository)"
    echo
    
    echo "Installed packages:"
    echo "  Formulae: $(brew list --formula 2>/dev/null | wc -l | tr -d ' ')"
    echo "  Casks: $(brew list --cask 2>/dev/null | wc -l | tr -d ' ')"
    echo
    
    echo "Taps:"
    brew tap | sed 's/^/  /'
    echo
    
    # Check for issues
    echo "Health check:"
    if brew doctor --quiet >/dev/null 2>&1; then
        echo "  ✅ No issues detected"
    else
        echo "  ⚠️  Issues detected (run 'brew doctor' for details)"
    fi
}

# Uninstall Homebrew (with confirmation)
uninstall_homebrew() {
    if ! is_brew_installed; then
        log_warn "Homebrew is not installed"
        return 0
    fi
    
    echo "⚠️  This will completely remove Homebrew and all installed packages!"
    echo
    show_homebrew_status
    echo
    
    if ! confirm "Are you sure you want to uninstall Homebrew?" "n"; then
        log_info "Homebrew uninstallation cancelled"
        return 0
    fi
    
    if ! confirm "This action cannot be undone. Continue?" "n"; then
        log_info "Homebrew uninstallation cancelled"
        return 0
    fi
    
    log_info "Uninstalling Homebrew..."
    
    # Create backup of installed packages list
    local backup_dir="${HOME}/.macos-setup/backups"
    mkdir -p "$backup_dir"
    
    brew list --formula > "$backup_dir/homebrew-formulae-$(date +%Y%m%d).txt" 2>/dev/null || true
    brew list --cask > "$backup_dir/homebrew-casks-$(date +%Y%m%d).txt" 2>/dev/null || true
    log_info "Package lists backed up to: $backup_dir"
    
    # Download and run uninstall script
    local uninstall_script_url="https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh"
    
    if validate_url "$uninstall_script_url"; then
        /bin/bash -c "$(curl -fsSL "$uninstall_script_url")"
    else
        log_error "Invalid uninstall script URL"
        return 1
    fi
    
    # Clean up environment configuration
    local shell_profile="$HOME/.zprofile"
    if [[ -f "$shell_profile" ]]; then
        # Remove Homebrew environment lines
        sed -i.bak '/# Homebrew environment configuration/d' "$shell_profile" 2>/dev/null || true
        sed -i.bak '/brew shellenv/d' "$shell_profile" 2>/dev/null || true
        log_info "Removed Homebrew configuration from $shell_profile"
    fi
    
    log_success "Homebrew uninstalled successfully"
}

# =============================================================================
# Homebrew Troubleshooting
# =============================================================================

# Fix common Homebrew issues
fix_homebrew_issues() {
    if ! is_brew_installed; then
        log_error "Homebrew is not installed"
        return 1
    fi
    
    log_info "Diagnosing and fixing Homebrew issues..."
    
    # Run brew doctor
    log_info "Running Homebrew doctor..."
    if brew doctor; then
        log_success "No issues found"
    else
        log_warn "Issues detected. See output above for recommendations."
    fi
    
    # Fix permissions
    if confirm "Fix Homebrew permissions?" "y"; then
        fix_homebrew_permissions
    fi
    
    # Update and upgrade
    if confirm "Update and upgrade all packages?" "y"; then
        update_homebrew
    fi
}

# Fix Homebrew permissions
fix_homebrew_permissions() {
    log_info "Fixing Homebrew permissions..."
    
    local brew_prefix=$(brew --prefix)
    
    # Fix ownership
    sudo chown -R "$(whoami)" "$brew_prefix"
    
    # Fix permissions on common directories
    local dirs=(
        "$brew_prefix/bin"
        "$brew_prefix/etc"
        "$brew_prefix/include"
        "$brew_prefix/lib"
        "$brew_prefix/sbin"
        "$brew_prefix/share"
        "$brew_prefix/var"
    )
    
    for dir in "${dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            chmod 755 "$dir"
        fi
    done
    
    log_success "Homebrew permissions fixed"
}

# =============================================================================
# Homebrew Menu System
# =============================================================================

# Show Homebrew management menu
show_homebrew_menu() {
    while true; do
        echo
        log_info "Homebrew Management"
        echo "==================="
        
        if is_brew_installed; then
            echo "✅ Homebrew is installed"
        else
            echo "❌ Homebrew is not installed"
        fi
        
        echo
        echo "1) Install Homebrew"
        echo "2) Update Homebrew & packages"
        echo "3) Show status & information"
        echo "4) Fix common issues"
        echo "5) Manage taps"
        echo "6) Cleanup old packages"
        echo "7) Uninstall Homebrew"
        echo "0) Back to main menu"
        
        local choice=$(get_input "Enter your choice" "0")
        
        case "$choice" in
            "1") install_homebrew ;;
            "2") update_homebrew ;;
            "3") show_homebrew_status ;;
            "4") fix_homebrew_issues ;;
            "5") manage_homebrew_taps ;;
            "6") cleanup_homebrew ;;
            "7") uninstall_homebrew ;;
            "0") break ;;
            *) log_error "Invalid choice: $choice" ;;
        esac
        
        # Pause for user to read output
        if [[ "$choice" != "0" ]]; then
            echo
            read -p "Press Enter to continue..." -r
        fi
    done
}

# Manage Homebrew taps
manage_homebrew_taps() {
    if ! is_brew_installed; then
        log_error "Homebrew is not installed"
        return 1
    fi
    
    while true; do
        echo
        log_info "Homebrew Taps Management"
        echo "======================="
        
        echo "Current taps:"
        brew tap | sed 's/^/  /' || echo "  None"
        
        echo
        echo "1) Add a tap"
        echo "2) Remove a tap"
        echo "3) Add common taps"
        echo "0) Back"
        
        local choice=$(get_input "Enter your choice" "0")
        
        case "$choice" in
            "1")
                local tap=$(get_input "Enter tap name (e.g., user/repo)")
                if [[ -n "$tap" ]]; then
                    brew tap "$tap" && log_success "Added tap: $tap"
                fi
                ;;
            "2")
                local tap=$(get_input "Enter tap name to remove")
                if [[ -n "$tap" ]]; then
                    brew untap "$tap" && log_success "Removed tap: $tap"
                fi
                ;;
            "3")
                add_homebrew_taps
                ;;
            "0") break ;;
            *) log_error "Invalid choice: $choice" ;;
        esac
    done
}

# Cleanup Homebrew
cleanup_homebrew() {
    if ! is_brew_installed; then
        log_error "Homebrew is not installed"
        return 1
    fi
    
    log_info "Cleaning up Homebrew..."

    
    # Show what will be cleaned
    echo "Files that will be removed:"
    echo "  (Use 'brew cleanup --dry-run' to preview)"
    
    if confirm "Proceed with cleanup?" "y"; then
        brew cleanup && log_success "Cleanup completed"
    fi
} 