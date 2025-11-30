#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/lib/logging.sh"
source "$SCRIPT_DIR/lib/utils.sh"
source "$SCRIPT_DIR/lib/parser.sh"

source "$SCRIPT_DIR/modules/homebrew.sh"
source "$SCRIPT_DIR/modules/system.sh"
source "$SCRIPT_DIR/modules/package_manager.sh"
source "$SCRIPT_DIR/modules/catalog_dialog.sh"
source "$SCRIPT_DIR/modules/git.sh"
source "$SCRIPT_DIR/modules/themes.sh"
source "$SCRIPT_DIR/modules/chezmoi.sh"
source "$SCRIPT_DIR/modules/backup.sh"
source "$SCRIPT_DIR/modules/aws.sh"
source "$SCRIPT_DIR/modules/system_info.sh"
source "$SCRIPT_DIR/modules/finder.sh"

get_system_info() {
    local os_version=$(sw_vers -productVersion 2>/dev/null || echo "Unknown")
    local arch=$(uname -m)
    echo "macOS $os_version ($arch)"
}

show_main_menu() {
    clear
    echo "┌─────────────────────────────┐"
    echo "│     macOS Setup v2.1.0     │"
    echo "└─────────────────────────────┘"
    echo ""
    echo "System: $(get_system_info)"
    echo ""
    echo "1) 🚀 Essentials"
    echo "2) 🍺 Homebrew"
    echo "3) 🛠️ System"
    echo "4) 🔧 Git"
    echo "5) 🔖 Chezmoi"
    echo "6) 🎨 Themes"
    echo "7) 📦 Backup"
    echo "8) 🔑 AWS"
    echo ""
    echo "9) 🔍 System information"
    echo ""
    echo "0) Exit"
    echo ""
}

main_menu() {
    parse_config
    parse_env
    while true; do
        show_main_menu
        read -p "Choice [0-13]: " choice
        
        case $choice in
            1) install_essentials
                ;;
            2)
                handle_homebrew_menu
                ;;
            3)
                handle_system_menu
                ;;
            4)
                handle_git_menu
                ;;
            5)
                handle_chezmoi_menu
                
                ;;
            6)
                handle_themes_menu
                
                ;;
            7)
                handle_backup_menu
                
                ;;
            8)
                handle_aws_menu
                ;;
            9)
                handle_system_info_menu
                ;;
            0)
                log_info "Exiting macOS Setup..."
                exit 0
                ;;
            *)
                echo "Invalid choice. Please try again."
                sleep 1
                ;;
        esac
    done
}

install_essentials() {
    log_info "Installing essential packages..."
    
    if ! require_tool brew; then
        log_error "Homebrew is not installed. Please install Homebrew first."
        return 1
    fi
    
    local essential_packages="git curl wget dialog htop yq"
    
    log_info "Installing packages: $essential_packages"

    if brew install $essential_packages; then
        log_info "Essential packages installed successfully!"
    else
        log_error "Failed to install some essential packages"
        return 1
    fi

    wait_for_user
}

main() {
    log_info "Starting macOS Setup v2.1.0"
    main_menu
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
