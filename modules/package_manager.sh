#!/bin/bash

show_package_manager_menu() {
    clear
    echo "┌─────────────────────────────┐"
    echo "│       Package Manager       │"
    echo "└─────────────────────────────┘"
    echo ""
    echo "Development"
    echo "1) Essentials"
    echo "2) Development Tools"
    echo "3) JetBrains IDEs"
    echo "4) AI Tools"
    echo ""
    echo "Infrastructure"
    echo "5) Cloud Tools"
    echo "6) Infrastructure as Code"
    echo "7) Container Tools"
    echo ""
    echo "Terminal & System"
    echo "8) Terminal Emulators"
    echo "9) Terminal Utilities"
    echo "10) System Tools"
    echo ""
    echo "Productivity"
    echo "11) Communication"
    echo "12) General Tools"
    echo ""
    echo "Management"
    echo "13) Show installed"
    echo "14) Update all cli"
	echo "15) Update all cask"
    echo "16) Zap uninstall packages"
    echo "17) Cleanup"
    echo ""
    echo "0) Back"
    echo ""
}
handle_package_manager_menu() {
    while true; do
        show_package_manager_menu
        read -p "Choice [0-17]: " choice
        
        case $choice in
		1)  # Essentials
			select_packages_from_catalog "essentials" "./catalog.yaml"
			;;
		2)  # Development Tools
			select_packages_from_catalog "development" "./catalog.yaml"
			;;
		3)  # JetBrains IDEs
			select_packages_from_catalog "jetbrains" "./catalog.yaml"
			;;
		4)  # AI Tools
			select_packages_from_catalog "ai" "./catalog.yaml"
			;;
		5)  # Cloud Tools
			select_packages_from_catalog "cloud" "./catalog.yaml"
			;;
		6)  # Infrastructure as Code
			select_packages_from_catalog "iac" "./catalog.yaml"
			;;
		7)  # Container Tools
			select_packages_from_catalog "container" "./catalog.yaml"
			;;
		8)  # Terminal Emulators
			select_packages_from_catalog "terminal" "./catalog.yaml"
			;;
		9)  # Terminal Utilities
			select_packages_from_catalog "terminal-utils" "./catalog.yaml"
			;;
		10) # System Tools
			select_packages_from_catalog "system" "./catalog.yaml"
			;;
		11) # Communication
			select_packages_from_catalog "communication" "./catalog.yaml"
			;;
		12) # General Tools
			select_packages_from_catalog "tools" "./catalog.yaml"
			;;
		13)
			show_installed
			;;
		14)
			update_all_cli
			wait_for_user
			;;
		15)
			update_all_cask
			wait_for_user
			;;
		16)
			zap_uninstall_packages
			wait_for_user
			;;
		17)
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

export -f package_manager cleanup_homebrew zap_uninstall_packages show_package_manager_menu handle_package_manager_menu