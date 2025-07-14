#!/bin/bash

# macOS Setup Script
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION="2.0.0"

# Load dependencies
source "$SCRIPT_DIR/lib/utils.sh"
source "$SCRIPT_DIR/lib/packages.sh"

for module in "$SCRIPT_DIR/modules"/*.sh; do
    [[ -f "$module" ]] && source "$module"
done

# Load .env if available
load_env() {
    [[ -f ".env" ]] && source .env 2>/dev/null || true
}

show_help() {
    cat << EOF
macOS Setup v$VERSION

USAGE: $0 [OPTIONS] [COMMAND]

OPTIONS:
    -h, --help     Show this help
    -v, --version  Show version
    --debug        Enable debug output

COMMANDS:
    menu           Interactive menu (default)
    homebrew       Install Homebrew
    packages       Package management
    system         System configuration
    git            Git setup
    themes         Install themes
    backup         Backup configuration
    all            Install essentials

EXAMPLES:
    $0             # Interactive menu
    $0 homebrew    # Install Homebrew only
    $0 all         # Install essentials
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help) show_help; exit 0 ;;
            -v|--version) echo "macOS Setup v$VERSION"; exit 0 ;;
            --debug) DEBUG=1; shift ;;
            menu|homebrew|packages|system|git|themes|backup|all)
                COMMAND="$1"; shift ;;
            *) log_error "Unknown option: $1"; exit 1 ;;
        esac
    done
}

install_essentials() {
    log_info "Installing Essential Packages"
    echo "• git, curl, wget, jq, tree"
    
    if confirm "Install essentials?" "y"; then
        install_homebrew
        install_packages "${ESSENTIALS_PACKAGES[@]}"
        log_success "Essentials installed!"
        read -p "Press Enter to continue..."
    fi
}

show_main_menu() {
    while true; do
        clear
        echo "┌─────────────────────────────┐"
        echo "│     macOS Setup v$VERSION     │"
        echo "└─────────────────────────────┘"
        echo
        echo "System: macOS $(sw_vers -productVersion) ($(uname -m))"
        is_brew_installed && echo "Homebrew: ✅" || echo "Homebrew: ❌"
        echo
        echo "1) 🍺 Homebrew"
        echo "2) 📦 Packages"
        echo "3) 🛠️ System"
        echo "4) 🔧 Git"
        echo "5) 🎨 Themes"
        echo "6) 📦 Backup"
        echo "7) 🚀 Essentials"
        echo "0) Exit"
        
        read -p "Choice [0-7]: " choice
        
        case "$choice" in
            1) show_homebrew_menu ;;
            2) show_packages_menu ;;
            3) show_system_menu ;;
            4) show_git_menu ;;
            5) show_themes_menu ;;
            6) show_backup_menu ;;
            7) install_essentials ;;
            0) log_info "Goodbye!"; exit 0 ;;
            *) log_error "Invalid choice: $choice" ;;
        esac
    done
}

main() {
    parse_args "$@"
    init_utils
    init_packages
    load_env
    
    case "${COMMAND:-menu}" in
        menu) show_main_menu ;;
        homebrew) show_homebrew_menu ;;
        packages) show_packages_menu ;;
        system) show_system_menu ;;
        git) show_git_menu ;;
        themes) show_themes_menu ;;
        backup) show_backup_menu ;;
        all) install_essentials ;;
        *) log_error "Unknown command: $COMMAND"; exit 1 ;;
    esac
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && main "$@" 