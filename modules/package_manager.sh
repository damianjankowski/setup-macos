#!/bin/bash

show_package_manager_menu() {
    clear
    echo "┌─────────────────────────────┐"
    echo "│       Package Manager       │"
    echo "└─────────────────────────────┘"
    echo ""
	echo "1) Install all"
	echo ""
    echo "Development"
    echo "2) Essentials"
    echo "3) Development Tools"
    echo "4) JetBrains IDEs"
    echo "5) AI Tools"
    echo ""
    echo "Infrastructure"
    echo "6) Cloud Tools"
    echo "7) Infrastructure as Code"
    echo "8) Container Tools"
    echo "9) Krew Plugins"
    echo ""
    echo "Terminal & System"
    echo "10) Terminal Emulators"
    echo "11) Terminal Utilities"
    echo "12) System Tools"
    echo ""
    echo "Productivity"
    echo "13) Communication"
    echo "14) General Tools"
    echo ""
    echo "Management"
    echo "15) Show installed"
    echo "16) Update all cli"
	echo "17) Update all cask"
    echo "18) Zap uninstall packages"
    echo "19) Cleanup"
    echo ""
    echo "0) Back"
    echo ""
}

handle_package_manager_menu() {
    while true; do
        show_package_manager_menu
        read -p "Choice [0-19]: " choice

        case $choice in
		1)  # Install all
			select_packages_from_catalog "all" "$SCRIPT_DIR/catalog.yaml"
			;;
		2)  # Essentials
			select_packages_from_catalog "essentials" "$SCRIPT_DIR/catalog.yaml"
			;;
		3)  # Development Tools
			select_packages_from_catalog "development" "$SCRIPT_DIR/catalog.yaml"
			;;
		4)  # JetBrains IDEs
			select_packages_from_catalog "jetbrains" "$SCRIPT_DIR/catalog.yaml"
			;;
		5)  # AI Tools
			select_packages_from_catalog "ai" "$SCRIPT_DIR/catalog.yaml"
			;;
		6)  # Cloud Tools
			select_packages_from_catalog "cloud" "$SCRIPT_DIR/catalog.yaml"
			;;
		7)  # Infrastructure as Code
			select_packages_from_catalog "iac" "$SCRIPT_DIR/catalog.yaml"
			;;
		8)  # Container Tools
			select_packages_from_catalog "container" "$SCRIPT_DIR/catalog.yaml"
			;;
		9)  # Krew Plugins
			install_krew_plugins
			;;
		10) # Terminal Emulators
			select_packages_from_catalog "terminal" "$SCRIPT_DIR/catalog.yaml"
			;;
		11) # Terminal Utilities
			select_packages_from_catalog "terminal-utils" "$SCRIPT_DIR/catalog.yaml"
			;;
		12) # System Tools
			select_packages_from_catalog "system" "$SCRIPT_DIR/catalog.yaml"
			;;
		13) # Communication
			select_packages_from_catalog "communication" "$SCRIPT_DIR/catalog.yaml"
			;;
		14) # General Tools
			select_packages_from_catalog "tools" "$SCRIPT_DIR/catalog.yaml"
			;;
		15)
			show_installed
			;;
		16)
			update_all_cli
			wait_for_user
			;;
		17)
			update_all_cask
			wait_for_user
			;;
		18)
			zap_uninstall_packages
			wait_for_user
			;;
		19)
			cleanup_homebrew
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

package_manager() {
    handle_package_manager_menu
}

install_packages() {
    local packages="$*"
    local total_packages=$(echo "$packages" | wc -w)
    local current_package=0
    
    log_info "Installing $total_packages packages..."
    
    for package in $packages; do
        current_package=$((current_package + 1))
        
        if [[ "$package" == krew:* ]]; then
            local real_package="${package#krew:}"
            log_info "[$current_package/$total_packages] Installing $real_package (krew)..."
            install_krew_plugin "$real_package"
        elif [[ "$package" == pipx:* ]]; then
            local real_package="${package#pipx:}"
            log_info "[$current_package/$total_packages] Installing $real_package (pipx)..."
            install_pipx_package "$real_package"
        else
            log_info "[$current_package/$total_packages] Installing $package (brew)..."
            if brew install "$package"; then
                log_info "✓ $package installed successfully"
            else
                log_error "✗ Failed to install $package"
            fi
        fi
    done
    
    wait_for_user
}

export -f package_manager cleanup_homebrew zap_uninstall_packages show_package_manager_menu handle_package_manager_menu install_packages