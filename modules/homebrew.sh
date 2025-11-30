#!/bin/bash

install_homebrew() {
    log_info "Checking Homebrew installation status..."
    
    if require_tool brew; then
        log_info "Homebrew is already installed."
        return 0
    fi
    
    log_info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    if [ $? -eq 0 ]; then
        log_info "Homebrew installation completed successfully."
    else
        log_error "Homebrew installation failed."
        return 1
    fi

    
}

install_brew_packages() {
    log_info "Installing Homebrew packages..."
    if ! require_tool brew; then
        log_error "Homebrew is not installed. Please install Homebrew first."
        return 1
    fi
    if [[ $# -gt 0 ]]; then
        packages="$*"
    fi
    local total_packages=$(echo "$packages" | wc -w)
    local current_package=0
    
    log_info "Installing $total_packages packages: $packages"
    for package in $packages; do
        current_package=$((current_package + 1))
        log_info "[$current_package/$total_packages] Installing $package..."
        
        if brew install "$package"; then
            log_info "✓ $package installed successfully"
        else
            log_error "✗ Failed to install $package"
        fi
        progress_bar "$current_package" "$total_packages"
    done
    
    log_info "Homebrew packages installation completed!"

    wait_for_user
}

update_homebrew() {
    log_info "Updating Homebrew..."
    if require_tool brew; then
        brew update
        log_info "Homebrew update completed"
    else
        log_error "Homebrew is not installed"
        return 1
    fi
    
}

get_homebrew_status() {
    if require_tool brew; then
        log_info "Homebrew is installed."
        log_info "Homebrew version: $(brew --version)"
        log_info "Homebrew path: $(which brew)"
        log_info "Homebrew configuration:"
        brew config
        log_info "Homebrew packages:"
        brew list
        return 0
    else
        log_error "Homebrew is not installed."
        return 1
    fi

    
}
cleanup_homebrew() {
    log_info "Cleaning up Homebrew..."
    if require_tool brew; then
		ask_for_confirmation "Are you sure you want to cleanup Homebrew?"
        brew cleanup
        log_info "Homebrew cleanup completed"
    else
        log_error "Homebrew is not installed"
        return 1
    fi
}

show_installed() {
    brew list
    wait_for_user
}

update_all_cli() {
    local outdated_packages=$(brew outdated | wc -l)

    if [[ $outdated_packages -eq 0 ]]; then
        log_info "No CLI packages to update"
        return 0
    fi

    log_info "Found $outdated_packages CLI packages to update"

    if brew upgrade; then
        progress_bar $outdated_packages $outdated_packages  # 100%
        log_info "CLI packages update completed successfully"
    else
        log_error "Failed to update CLI packages"
        return 1
    fi
    cleanup_homebrew
    wait_for_user
}

update_all_cask() {
    local outdated_packages=$(brew outdated --cask | wc -l)

    if [[ $outdated_packages -eq 0 ]]; then
        log_info "No cask packages to update"
        return 0
    fi

    log_info "Found $outdated_packages cask packages to update"

    if brew upgrade --cask; then
        progress_bar $outdated_packages $outdated_packages  # 100%
        log_info "Cask packages update completed successfully"
    else
        log_error "Failed to update cask packages"
        return 1
    fi

    log_info "Homebrew cask update completed"
    
}

zap_uninstall_packages() {
    brew list
    packages=$(ask_for_input "Enter the packages to zap uninstall (separated by spaces)")
    ask_for_confirmation "Are you sure you want to zap uninstall packages?"
	local original_packages=$(brew list)
	if brew uninstall --zap $packages; then
		local current_packages=$(brew list)
		local removed_packages=""
		
		for package in $packages; do
			if ! echo "$current_packages" | grep -q "^${package}$"; then
				removed_packages="$removed_packages $package"
			fi
		done
		
		if [[ -n "$removed_packages" ]]; then
			log_info "Successfully zap uninstalled packages:$removed_packages"
		else
			log_warn "No packages were removed (they may not have been installed)"
		fi
	else
		log_error "Failed to zap uninstall packages"
		return 1
	fi
}

install_rosetta() {
    log_info "Installing Rosetta..."
    if /usr/sbin/pkgutil --pkg-info com.apple.pkg.RosettaUpdateAuto >/dev/null 2>&1; then
        log_info "Rosetta is already installed"; 
        return 0
    fi
    sudo softwareupdate --install-rosetta
    log_info "Rosetta installation completed"
}

show_homebrew_menu() {
    clear
    echo "┌─────────────────────────────┐"
    echo "│         Homebrew            │"
    echo "└─────────────────────────────┘"
    echo ""
    echo "1) Install Rosetta"
    echo "2) Install Homebrew"
    echo "3) Update Homebrew"
    echo "4) Package manager"
    echo "5) Check status"
    echo "0) Back"
    echo ""
}

handle_homebrew_menu() {
    while true; do
        show_homebrew_menu
        read -p "Choice [0-5]: " choice
        
        case $choice in
            1)
                install_rosetta
                wait_for_user
                ;;
            2)
                log_info "Installing Homebrew..."
                install_homebrew
                wait_for_user
                ;;
            3)
                update_homebrew
                wait_for_user
                ;;
            4)
                package_manager
                ;;
            5)
                get_homebrew_status
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

export -f install_homebrew update_homebrew get_homebrew_status show_homebrew_menu handle_homebrew_menu install_brew_packages cleanup_homebrew zap_uninstall_packages install_rosetta

