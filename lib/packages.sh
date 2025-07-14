#!/bin/bash

# Package management for macOS setup

# Package definitions
ESSENTIALS_PACKAGES=(
    "git:cli:Version control"
    "curl:cli:Data transfer tool"
    "wget:cli:File retriever"
    "dialog:cli:Dialog boxes"
)

DEVELOPMENT_PACKAGES=(
    "visual-studio-code:cask:VS Code editor"
    "neovim:cli:Modern Vim editor"
    "nvm:cli:Node.js version manager"
    "pyenv:cli:Python version manager"
    "pipx:cli:Python app installer"
    "postman:cask:API development"
    "fork:cask:Git client"
    "pre-commit:cli:Git hook manager"
    "git-delta:cli:Git diff viewer"
    "cursor:cask:AI code editor"
)

CLOUD_PACKAGES=(
    "awscli:cli:AWS CLI"
    "google-cloud-sdk:cask:Google Cloud SDK"
    "azure-cli:cli:Azure CLI"
    "kubernetes-cli:cli:kubectl"
    "helm:cli:Kubernetes package manager"
    "k9s:cli:Kubernetes cluster management"
    "terraform:cli:Infrastructure as code"
    "aws-vpn-client:cask:AWS VPN client"
)

CONTAINER_PACKAGES=(
    "docker:cask:Container platform"
    "ctop:cli:Container monitoring"
    "orbstack:cask:Docker alternative"
)

TERMINAL_PACKAGES=(
    "iterm2:cask:Terminal emulator"
    "kitty:cask:GPU terminal"
    "warp:cask:Modern terminal"
    "tmux:cli:Terminal multiplexer"
    "fzf:cli:Fuzzy finder"
    "htop:cli:Process viewer"
    "tldr:cli:Simplified man pages"
    "bat:cli:Cat with syntax highlighting"
    "eza:cli:Modern ls"
    "starship:cli:Shell prompt"
)

SYSTEM_PACKAGES=(
    "jq:cli:JSON processor"
    "yq:cli:YAML processor"
    "rectangle:cask:Window manager"
    "stats:cask:System monitor"
    "raycast:cask:Launcher"
    "lunar:cask:Brightness control"
    "karabiner-elements:cask:Keyboard customizer"
)

COMMUNICATION_PACKAGES=(
    "slack:cask:Team chat"
    "discord:cask:Voice chat"
    "spotify:cask:Music streaming"
    "obsidian:cask:Note taking"
)

init_packages() {
    log_debug "Packages module loaded"
}

# Get packages for category
get_packages() {
    local category="$1"
    local var_name="$(echo "$category" | tr '[:lower:]' '[:upper:]')_PACKAGES"
    
    # Use eval for bash 3.2 compatibility
    local packages=()
    eval "packages=(\"\${${var_name}[@]}\")"
    printf '%s\n' "${packages[@]}"
}

# Check if package is installed
is_installed() {
    local name="$1"
    local type="${2:-cli}"
    
    case "$type" in
        cask) brew list --cask "$name" >/dev/null 2>&1 ;;
        *) brew list "$name" >/dev/null 2>&1 ;;
    esac
}

# Install single package
install_package() {
    local name="$1"
    local type="$2"
    local desc="$3"
    
    if is_installed "$name" "$type"; then
        log_info "$name already installed"
        return 0
    fi
    
    log_info "Installing $name ($desc)"
    
    case "$type" in
        cask)
            if [[ "$name" == "stretchly" ]]; then
                brew install --cask --no-quarantine "$name"
            else
                brew install --cask "$name"
            fi
            ;;
        *)
            brew install "$name"
            ;;
    esac
    
    # Post-install configuration
    case "$name" in
        zsh-syntax-highlighting)
            echo "source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> ~/.zshrc
            ;;
        zsh-autosuggestions)
            echo "source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh" >> ~/.zshrc
            ;;
        docker)
            open -a Docker 2>/dev/null || true
            ;;
    esac
    
    log_success "Installed $name"
}

# Install multiple packages
install_packages() {
    local packages=("$@")
    local total=${#packages[@]}
    local failed=()
    
    [[ $total -eq 0 ]] && { log_warn "No packages specified"; return 0; }
    
    log_info "Installing $total packages..."
    
    for ((i=0; i<total; i++)); do
        local package="${packages[i]}"
        local name=$(echo "$package" | cut -d: -f1)
        local type=$(echo "$package" | cut -d: -f2)
        local desc=$(echo "$package" | cut -d: -f3)
        
        echo "[$((i+1))/$total] Installing $name..."
        
        if ! install_package "$name" "$type" "$desc"; then
            failed+=("$name")
        fi
    done
    
    if [[ ${#failed[@]} -gt 0 ]]; then
        log_error "Failed to install: ${failed[*]}"
        return 1
    fi
    
    log_success "All packages installed!"
}

# Interactive package selection
select_packages() {
    local category="$1"
    local packages=()
    
    # Read packages into array (bash 3.2 compatible)
    while IFS= read -r package; do
        [[ -n "$package" ]] && packages+=("$package")
    done < <(get_packages "$category")
    
    [[ ${#packages[@]} -eq 0 ]] && { log_error "No packages in category: $category"; return 1; }
    
    if ! command -v dialog >/dev/null; then
        log_info "Installing dialog..."
        brew install dialog || { log_error "Failed to install dialog"; return 1; }
    fi
    
    # Create dialog command
    local cmd="dialog --title \"$category Packages\" --checklist \"Select packages:\" 20 80 12"
    
    for package in "${packages[@]}"; do
        local name=$(echo "$package" | cut -d: -f1)
        local type=$(echo "$package" | cut -d: -f2)
        local desc=$(echo "$package" | cut -d: -f3)
        local label="$name ($type) - $desc"
        cmd+=" \"$name\" \"$label\" OFF"
    done
    
    local selected
    if selected=$(eval "$cmd" 3>&1 1>&2 2>&3); then
        if [[ -n "$selected" ]]; then
            local selected_packages=()
            for sel in $selected; do
                sel=$(echo "$sel" | tr -d '"')
                for package in "${packages[@]}"; do
                    local name=$(echo "$package" | cut -d: -f1)
                    [[ "$name" == "$sel" ]] && selected_packages+=("$package")
                done
            done
            install_packages "${selected_packages[@]}"
        else
            log_info "No packages selected"
        fi
    fi
    clear
}

# Package menu
show_packages_menu() {
    while true; do
        echo
        log_info "Package Manager"
        echo "1) Essentials"
        echo "2) Development" 
        echo "3) Cloud"
        echo "4) Container"
        echo "5) Terminal"
        echo "6) System"
        echo "7) Communication"
        echo "8) Show installed"
        echo "9) Update all"
        echo "0) Back"
        
        read -p "Choice [0-9]: " choice
        
        case "$choice" in
            1) select_packages "essentials" ;;
            2) select_packages "development" ;;
            3) select_packages "cloud" ;;
            4) select_packages "container" ;;
            5) select_packages "terminal" ;;
            6) select_packages "system" ;;
            7) select_packages "communication" ;;
            8) show_installed ;;
            9) update_packages ;;
            0) return ;;
            *) log_error "Invalid choice" ;;
        esac
    done
}

# Show installed packages
show_installed() {
    log_info "Installed Packages"
    echo "Formulae: $(brew list --formula 2>/dev/null | wc -l | tr -d ' ')"
    brew list --formula 2>/dev/null | column || echo "None"
    echo
    echo "Casks: $(brew list --cask 2>/dev/null | wc -l | tr -d ' ')"
    brew list --cask 2>/dev/null | column || echo "None"
    echo
    read -p "Press Enter to continue..."
}

# Update packages
update_packages() {
    log_info "Updating packages..."
    brew update && brew upgrade
    log_success "Update complete"
    read -p "Press Enter to continue..."
}

