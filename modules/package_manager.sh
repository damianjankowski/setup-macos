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
    echo "6) AI Add-ons"
    echo ""
    echo "Infrastructure"
    echo "7) Cloud Tools"
    echo "8) Infrastructure as Code"
    echo "9) Container Tools"
    echo "10) Krew Plugins"
    echo ""
    echo "Terminal & System"
    echo "11) Terminal Emulators"
    echo "12) Terminal Utilities"
    echo "13) System Tools"
    echo ""
    echo "Productivity"
    echo "14) Communication"
    echo "15) General Tools"
    echo ""
    echo "Management"
    echo "16) Show installed"
    echo "17) Update all cli"
	echo "18) Update all cask"
    echo "19) Zap uninstall packages"
    echo "20) Cleanup"
    echo ""
    echo "0) Back"
    echo ""
}

handle_package_manager_menu() {
    while true; do
        show_package_manager_menu
        read -r -p "Choice [0-20]: " choice

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
		6)  # AI Add-ons
			select_packages_from_catalog "ai-addons" "$SCRIPT_DIR/catalog.yaml"
			;;
		7)  # Cloud Tools
			select_packages_from_catalog "cloud" "$SCRIPT_DIR/catalog.yaml"
			;;
		8)  # Infrastructure as Code
			select_packages_from_catalog "iac" "$SCRIPT_DIR/catalog.yaml"
			;;
		9)  # Container Tools
			select_packages_from_catalog "container" "$SCRIPT_DIR/catalog.yaml"
			;;
		10) # Krew Plugins
			install_krew_plugins
			;;
		11) # Terminal Emulators
			select_packages_from_catalog "terminal" "$SCRIPT_DIR/catalog.yaml"
			;;
		12) # Terminal Utilities
			select_packages_from_catalog "terminal-utils" "$SCRIPT_DIR/catalog.yaml"
			;;
		13) # System Tools
			select_packages_from_catalog "system" "$SCRIPT_DIR/catalog.yaml"
			;;
		14) # Communication
			select_packages_from_catalog "communication" "$SCRIPT_DIR/catalog.yaml"
			;;
		15) # General Tools
			select_packages_from_catalog "tools" "$SCRIPT_DIR/catalog.yaml"
			;;
		16)
			show_installed
			;;
		17)
			update_all_cli
			wait_for_user
			;;
		18)
			update_all_cask
			wait_for_user
			;;
		19)
			zap_uninstall_packages
			wait_for_user
			;;
		20)
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
        elif [[ "$package" == curl:* ]]; then
            local real_package="${package#curl:}"
            log_info "[$current_package/$total_packages] Installing $real_package (curl script)..."
            local cmd
            cmd=$(yq -o=json "$SCRIPT_DIR/catalog.yaml" | jq -r --arg id "$real_package" '
                .categories[]?.packages[]? | select(.id == $id and .type == "curl") | .cmd
            ' | head -n1)
            if [[ -z "$cmd" || "$cmd" == "null" ]]; then
                log_error "✗ No cmd defined for $real_package in catalog.yaml"
            elif bash -c "$cmd"; then
                log_info "✓ $real_package installed successfully"
            else
                log_error "✗ Failed to install $real_package"
            fi
        elif [[ "$package" == cask:* ]]; then
            local real_package="${package#cask:}"
            log_info "[$current_package/$total_packages] Installing $real_package (cask)..."
            if brew install --cask "$real_package"; then
                log_info "✓ $real_package installed successfully"
            else
                log_error "✗ Failed to install $real_package"
            fi
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

