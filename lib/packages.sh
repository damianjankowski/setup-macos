#!/bin/bash

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
    "pyenv-virtualenv:cli:Python virtual environment manager"
    "dbeaver-community:cask:Database client"
)

JETBRAINS_PACKAGES=(
    "pycharm:cask:Python IDE"
    "pycharm-ce:cask:Python Community IDE"
    "intellij-idea:cask:Java IDE"
    "intellij-idea-ce:cask:Java Community Edition"
    "goland:cask:Go IDE"
    "rubymine:cask:Ruby IDE"
    "webstorm:cask:Web development"
    "datagrip:cask:Database IDE"
    "clion:cask:C/C++ IDE"
    "resharper:cask:C# IDE"
    "rustrover:cask:Rust IDE"
    "rider:cask:C# IDE"
)

CLOUD_PACKAGES=(
    "awscli:cli:AWS CLI"
    "google-cloud-sdk:cask:Google Cloud SDK"
    "gcloud-cli:cli:Google Cloud CLI"
    "azure-cli:cli:Azure CLI"
    "kubernetes-cli:cli:kubectl"
    "helm:cli:Kubernetes package manager"
    "k9s:cli:Kubernetes cluster management"
    "aws-vpn-client:cask:AWS VPN client"
    "argocd:cli:ArgoCD"
    "granted:cli:AWS IAM credentials"
    "lens:cask:Kubernetes IDE"
)

IAC_PACKAGES=(
    "terraformer:cli:Terraform state to code"
    "tfenv:cli:Terraform version manager"
    "terraform:cli:Infrastructure as code"
    "tflint:cli:Terraform linter"
    "infracost:cli:FinOps tool"
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
    "ghostty:cask:Terminal emulator"
)

TERMINAL_UTILS_PACKAGES=(
    "eza:cli:Modern ls"
    "bat:cli:Cat with syntax highlighting"
    "tldr:cli:Simplified man pages"
    "fzf:cli:Fuzzy finder"
    "htop:cli:Process viewer"
    "jq:cli:JSON processor"
    "yq:cli:YAML processor"
    "starship:cli:Cross-shell prompt"
    "powerlevel10k:cli:Powerlevel10k"
    "fd:cli:Fast file finder"
    "ripgrep:cli:Fast grep"
    "grep:cli:Grep"
    "zoxide:cli:Fast cd"
    "fish:cli:Fish shell"
    "kubecolor:cli:Kubernetes color output"
    "yazi:cli:File manager"
    "thefuck:cli:Command line tool to fix mistakes"
    "tree:cli:Tree view of directory structure"
    "fastfetch:cli:System information"
    "chezmoi:cli:Configuration management"
)

SYSTEM_PACKAGES=(
    "rectangle:cask:Window manager"
    "stats:cask:System monitor"
    "raycast:cask:Launcher"
    "lunar:cask:Brightness control"
    "karabiner-elements:cask:Keyboard customizer"
    "aerospace:cask:Window manager"
)

COMMUNICATION_PACKAGES=(
    "slack:cask:Team chat"
    "discord:cask:Voice chat"
    "spotify:cask:Music streaming"
)

AI_PACKAGES=(
    "ollama:cli:AI model runner"
    "lm-studio:cask:AI model runner"
    "claude-cli:cli:AI model runner"
    "claude:cask:AI"
    "chatgpt:cask:AI"
    "gemini-cli:cli:AI model runner"
)

TOOLS_PACKAGES=(
    "garmin-express:cask:Garmin Connect"
    "obsidian:cask:Note taking"
    "notion:cask:Note taking"
)

init_packages() {
    log_debug "Packages module loaded"
}

get_packages() {
    local category="$1"
    local var_name="$(echo "$category" | tr '[:lower:]' '[:upper:]')_PACKAGES"

    local packages=()
    eval "packages=(\"\${${var_name}[@]}\")"
    printf '%s\n' "${packages[@]}"
}

is_installed() {
    local name="$1"
    local type="${2:-cli}"

    case "$type" in
        cask) brew list --cask "$name" >/dev/null 2>&1 ;;
        *) brew list "$name" >/dev/null 2>&1 ;;
    esac
}

parse_package() {
    local package="$1"
    local IFS=':'
    read -r name type desc <<< "$package"
    echo "$name" "$type" "$desc"
}

add_to_shell_config() {
    local line="$1"
    local config_file="${2:-$ZSHRC_PATH}"

    if [[ -f "$config_file" ]] && ! grep -Fxq "$line" "$config_file"; then
        echo "$line" >> "$config_file"
        log_info "Added to $(basename "$config_file"): $line"
    fi
}

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
    esac || {
        log_error "Failed to install $name"
        return 1
    }

    case "$name" in
        zsh-syntax-highlighting)
            add_to_shell_config "source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
            ;;
        zsh-autosuggestions)
            add_to_shell_config "source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
            ;;
        docker)
            open -a Docker 2>/dev/null || true
            ;;
    esac

    log_success "Installed $name"
}

install_packages() {
    local packages=("$@")
    local total=${#packages[@]}
    local failed=()

    [[ $total -eq 0 ]] && { log_warn "No packages specified"; return 0; }

    log_info "Installing $total packages..."

    for ((i=0; i<total; i++)); do
        local package="${packages[i]}"
        read -r name type desc <<< "$(parse_package "$package")"

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

select_packages() {
    local category="$1"
    local packages=()

    while IFS= read -r package; do
        [[ -n "$package" ]] && packages+=("$package")
    done < <(get_packages "$category")

    [[ ${#packages[@]} -eq 0 ]] && { log_error "No packages in category: $category"; return 1; }

    if ! command -v dialog >/dev/null; then
        log_info "Installing dialog..."
        brew install dialog || { log_error "Failed to install dialog"; return 1; }
    fi

    local dialog_args=(
        --title "$category Packages"
        --checklist "Select packages:"
        20 80 12
    )

    for package in "${packages[@]}"; do
        read -r name type desc <<< "$(parse_package "$package")"
        local label="$name ($type) - $desc"
        dialog_args+=("$name" "$label" OFF)
    done

    local selected
    if selected=$(dialog "${dialog_args[@]}" 3>&1 1>&2 2>&3); then
        if [[ -n "$selected" ]]; then
            local selected_packages=()
            selected=$(echo "$selected" | tr -d '"')
            for sel in $selected; do
                for package in "${packages[@]}"; do
                    read -r name _ _ <<< "$(parse_package "$package")"
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

show_packages_menu() {
    while true; do
        echo
        log_info "📦 Package Manager"
        echo "Development:"
        echo "  1) Essentials"
        echo "  2) Development Tools"
        echo "  3) JetBrains IDEs"
        echo "  4) AI Tools"
        echo
        echo "Infrastructure:"
        echo "  5) Cloud Tools"
        echo "  6) Infrastructure as Code"
        echo "  7) Container Tools"
        echo
        echo "Terminal & System:"
        echo "  8) Terminal Emulators"
        echo "  9) Terminal Utilities"
        echo " 10) System Tools"
        echo
        echo "Productivity:"
        echo " 11) Communication"
        echo " 12) General Tools"
        echo
        echo "Management:"
        echo " 13) Show installed"
        echo " 14) Update all"
        echo "  0) Back"

        read -p "Choice [0-14]: " choice

        case "$choice" in
            1) select_packages "essentials" ;;
            2) select_packages "development" ;;
            3) select_packages "jetbrains" ;;
            4) select_packages "ai" ;;
            5) select_packages "cloud" ;;
            6) select_packages "iac" ;;
            7) select_packages "container" ;;
            8) select_packages "terminal" ;;
            9) select_packages "terminal_utils" ;;
            10) select_packages "system" ;;
            11) select_packages "communication" ;;
            12) select_packages "tools" ;;
            13) brew list && brew list --cask ;;
            14) brew update && brew upgrade ;;
            0) return 0 ;;
            *) log_error "Invalid choice: $choice" ;;
        esac
    done
}