#!/bin/bash

if [ -z "$BASH_VERSION" ]; then
  echo "This script must be run with bash, not sh or another shell." >&2
  exit 1
fi

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION="2.0.0"

source "$SCRIPT_DIR/lib/utils.sh"
source "$SCRIPT_DIR/lib/packages.sh"
source "$SCRIPT_DIR/config.sh"

for module in "$SCRIPT_DIR/modules"/*.sh; do
    module_name=$(basename "$module" .sh)
    fixed_module="$SCRIPT_DIR/modules/${module_name}.sh"
    
    if [[ -f "$fixed_module" ]]; then
        source "$fixed_module"
    elif [[ -f "$module" ]]; then
        source "$module"
    fi
done

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
    $0 homebrew    # Install Homebrew
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
    echo "• git, curl, wget, dialog"
    
    if confirm "Install essentials?" "y"; then
        if command_exists install_homebrew; then
            install_homebrew
        else
            log_info "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        
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
        echo "System: macOS $(get_macos_version) ($(uname -m))"
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
            1) 
                if command_exists show_homebrew_menu; then
                    show_homebrew_menu
                else
                    log_warn "Homebrew module not available"
                fi
                ;;
            2) show_packages_menu ;;
            3) 
                if command_exists show_system_menu; then
                    show_system_menu
                else
                    log_warn "System module not available"
                fi
                ;;
            4) 
                if command_exists show_git_menu; then
                    show_git_menu
                else
                    log_warn "Git module not available"
                fi
                ;;
            5) 
                if command_exists show_themes_menu; then
                    show_themes_menu
                else
                    log_warn "Themes module not available"
                fi
                ;;
            6) show_backup_menu ;;
            7) install_essentials ;;
            0) log_info "Goodbye!"; exit 0 ;;
            *) log_error "Invalid choice: $choice" ;;
        esac
    done
}

init_system() {
    log_debug "Initializing macOS Setup v$VERSION"
    
    init_utils
    
    init_packages
    
    init_config
    
    setup_cleanup
    
    log_debug "System initialization complete"
}

main() {
    parse_args "$@"
    load_env
    init_system
    
    case "${COMMAND:-menu}" in
        menu) show_main_menu ;;
        homebrew) 
            if command_exists show_homebrew_menu; then
                show_homebrew_menu
            else
                log_error "Homebrew module not available"
                exit 1
            fi
            ;;
        packages) show_packages_menu ;;
        system) 
            if command_exists show_system_menu; then
                show_system_menu
            else
                log_error "System module not available"
                exit 1
            fi
            ;;
        git) 
            if command_exists show_git_menu; then
                show_git_menu
            else
                log_error "Git module not available"
                exit 1
            fi
            ;;
        themes) 
            if command_exists show_themes_menu; then
                show_themes_menu
            else
                log_error "Themes module not available"
                exit 1
            fi
            ;;
        backup) show_backup_menu ;;
        all) install_essentials ;;
        *) log_error "Unknown command: $COMMAND"; exit 1 ;;
    esac
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && main "$@"