#!/bin/bash

# =============================================================================
# Package Management System
# Real package installation with category-based organization
# =============================================================================

# Package database - defined directly in code, no external files
# Temporary files for processing
readonly TEMP_DIR="/tmp/macos-setup-$$"

# Initialize package management
init_packages() {
    mkdir -p "$TEMP_DIR"
    trap 'cleanup_packages' EXIT
}

# Cleanup temporary files
cleanup_packages() {
    rm -rf "$TEMP_DIR" 2>/dev/null || true
}

# =============================================================================
# Package Definitions (from legacy backup)
# =============================================================================

# Essential Tools
ESSENTIALS_PACKAGES=(
    "git:cli:Distributed version control system"
    "curl:cli:Command line tool for transferring data"
    "wget:cli:Internet file retriever"
    "jq:cli:Lightweight JSON processor"
    "tree:cli:Display directory tree structure"
)

# Development Tools
DEVELOPMENT_PACKAGES=(
    "visual-studio-code:cask:Code editor with extensive extensions"
    "neovim:cli:Modern Vim-based editor"
    "nvm:cli:Node.js version manager"
    "pyenv:cli:Python version manager"
    "pyenv-virtualenv:cli:Pyenv plugin for virtualenv"
    "pipx:cli:Install Python applications in isolated environments"
    "act:cli:Run GitHub Actions locally"
    "glab:cli:GitLab CLI tool"
    "postman:cask:API development environment"
    "fork:cask:Git client"
    "sourcetree:cask:Git GUI client"
)

# Cloud & Infrastructure
CLOUD_PACKAGES=(
    "awscli:cli:AWS Command Line Interface"
    "google-cloud-sdk:cask:Google Cloud Platform SDK"
    "azure-cli:cli:Microsoft Azure CLI"
    "granted:cli:AWS credential manager"
    "kubernetes-cli:cli:Kubernetes command-line tool"
    "helm:cli:Kubernetes package manager"
    "k9s:cli:Kubernetes cluster management"
    "minikube:cli:Local Kubernetes development"
    "skaffold:cli:Kubernetes development workflow"
    "argocd:cli:GitOps continuous delivery tool"
    "aws-vpn-client:cask:AWS VPN client"
    "lens:cask:Kubernetes IDE"
)

# Container Tools
CONTAINER_PACKAGES=(
    "docker:cask:Containerization platform"
    "ctop:cli:Container monitoring tool"
    "orbstack:cask:Docker alternative for macOS"
)

# Database Tools
DATABASE_PACKAGES=(
    "dbeaver-community:cask:Universal database tool"
)

# Terminal Enhancement
TERMINAL_PACKAGES=(
    "iterm2:cask:Advanced terminal emulator"
    "warp:cask:Modern terminal with AI features"
    "tmux:cli:Terminal multiplexer"
    "fzf:cli:Fuzzy finder for command line"
    "htop:cli:Interactive process viewer"
    "thefuck:cli:Command correction tool"
    "tldr:cli:Simplified man pages"
    "zsh-autosuggestions:cli:Fish-like autosuggestions for zsh"
    "zsh-syntax-highlighting:cli:Syntax highlighting for zsh"
)

# System Utilities
SYSTEM_PACKAGES=(
    "yq:cli:YAML processor"
    "watch:cli:Execute commands periodically"
    "kcat:cli:Kafka command line tool"
    "wakeonlan:cli:Wake on LAN tool"
    "stats:cask:System monitor in menu bar"
    "rectangle:cask:Window management utility"
    "hiddenbar:cask:Hide menu bar items"
    "karabiner-elements:cask:Keyboard customizer"
    "lunar:cask:Intelligent adaptive brightness"
    "raycast:cask:Productivity launcher"
    "stretchly:cask:Break reminder app"
)

# Communication & Productivity
COMMUNICATION_PACKAGES=(
    "slack:cask:Team communication platform"
    "discord:cask:Voice and text chat"
    "spotify:cask:Music streaming service"
    "calibre:cask:E-book management"
    "obsidian:cask:Knowledge management and note-taking"
)

# Infrastructure as Code
IAC_PACKAGES=(
    "terraform:cli:Infrastructure as Code tool"
    "tfenv:cli:Terraform version manager"
    "tflint:cli:Terraform linter"
    "ansible:cli:Configuration management"
    "ansible-lint:cli:Ansible linter"
)

# AI Tools
AI_PACKAGES=(
    "lm-studio:cask:Local language model studio"
)

# =============================================================================
# Package Information Functions
# =============================================================================

# Get package categories
get_package_categories() {
    echo "$PACKAGE_CATEGORIES" | tr ' ' '\n' | sort
}

# Get category description
get_category_description() {
    local category="$1"
    case "$category" in
        "essentials") echo "Essential CLI tools and basics" ;;
        "development") echo "Development tools and IDEs" ;;
        "cloud") echo "Cloud and infrastructure tools" ;;
        "container") echo "Container and orchestration tools" ;;
        "database") echo "Database management tools" ;;
        "terminal") echo "Terminal and shell enhancements" ;;
        "system") echo "System utilities and productivity" ;;
        "communication") echo "Communication and collaboration" ;;
        "multimedia") echo "Media and entertainment" ;;
        "security") echo "Security and privacy tools" ;;
        *) echo "Unknown category" ;;
    esac
}

# Get packages for a category
get_packages_for_category() {
    local category="$1"
    # Convert to uppercase using tr (bash 3.2 compatible)
    local packages_var="$(echo "$category" | tr '[:lower:]' '[:upper:]')_PACKAGES"
    
    # Use eval for variable reference (bash 3.2 compatible)
    local packages=()
    eval "packages=(\"\${${packages_var}[@]}\")"
    
    for package_def in "${packages[@]}"; do
        # Split package definition: name:type:description
        local name=$(echo "$package_def" | cut -d: -f1)
        echo "$name"
    done
}

# Get package type (cli/cask)
get_package_type() {
    local package_name="$1"
    local category="$2"
    # Convert to uppercase using tr (bash 3.2 compatible)
    local packages_var="$(echo "$category" | tr '[:lower:]' '[:upper:]')_PACKAGES"
    
    # Use eval for variable reference (bash 3.2 compatible)
    local packages=()
    eval "packages=(\"\${${packages_var}[@]}\")"
    
    for package_def in "${packages[@]}"; do
        local name=$(echo "$package_def" | cut -d: -f1)
        local type=$(echo "$package_def" | cut -d: -f2)
        
        if [[ "$name" == "$package_name" ]]; then
            echo "$type"
            return
        fi
    done
    echo "cli"  # default
}

# Get package description
get_package_description() {
    local package_name="$1"
    local category="$2"
    # Convert to uppercase using tr (bash 3.2 compatible)
    local packages_var="$(echo "$category" | tr '[:lower:]' '[:upper:]')_PACKAGES"
    
    # Use eval for variable reference (bash 3.2 compatible)
    local packages=()
    eval "packages=(\"\${${packages_var}[@]}\")"
    
    for package_def in "${packages[@]}"; do
        local name=$(echo "$package_def" | cut -d: -f1)
        local desc=$(echo "$package_def" | cut -d: -f3-)
        
        if [[ "$name" == "$package_name" ]]; then
            echo "$desc"
            return
        fi
    done
    echo "No description available"
}

# Check if package is installed (simple version like old approach)
is_package_installed() {
    local package_name="$1"
    local package_type="${2:-cli}"
    
    case "$package_type" in
        "cask")
            brew list --cask "$package_name" >/dev/null 2>&1
            ;;
        "cli"|*)
            brew list "$package_name" >/dev/null 2>&1
            ;;
    esac
}

# =============================================================================
# Package Installation
# =============================================================================

# Install a single package
install_package() {
    local package_name="$1"
    local package_type="$2"
    local description="$3"

    
    # Check if already installed
    if is_package_installed "$package_name" "$package_type"; then
        log_info "Package already installed: $package_name"
        return 0
    fi
    
    log_info "Installing $package_name ($package_type) - $description"
    
    # Install based on type
    case "$package_type" in
        "cask")
            # Special case for stretchly (needs --no-quarantine)
            if [[ "$package_name" == "stretchly" ]]; then
                brew install --cask --no-quarantine "$package_name" || {
                    log_error "Failed to install cask: $package_name"
                    return 1
                }
            else
                brew install --cask "$package_name" || {
                    log_error "Failed to install cask: $package_name"
                    return 1
                }
            fi
            ;;
        "cli"|*)
            brew install "$package_name" || {
                log_error "Failed to install formula: $package_name"
                return 1
            }
            ;;
    esac
    
    # Post-install configuration for special packages
    configure_package_post_install "$package_name"
    
    log_success "Successfully installed: $package_name"
}

# Post-install configuration
configure_package_post_install() {
    local package_name="$1"
    
    case "$package_name" in
        "zsh-syntax-highlighting")
            local shell_profile="$HOME/.zshrc"
            local source_line="source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
            if [[ -f "$shell_profile" ]] && ! grep -q "zsh-syntax-highlighting.zsh" "$shell_profile"; then
                echo "$source_line" >> "$shell_profile"
                log_info "Added zsh-syntax-highlighting to $shell_profile"
            fi
            ;;
        "zsh-autosuggestions")
            local shell_profile="$HOME/.zshrc"
            local source_line="source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
            if [[ -f "$shell_profile" ]] && ! grep -q "zsh-autosuggestions.zsh" "$shell_profile"; then
                echo "$source_line" >> "$shell_profile"
                log_info "Added zsh-autosuggestions to $shell_profile"
            fi
            ;;
        "docker")
            # Start Docker application
            open -a Docker 2>/dev/null || true
            log_info "Started Docker application"
            ;;
    esac
}

# Install packages from a list
install_packages() {
    local packages=("$@")
    local total=${#packages[@]}
    local current=0
    local failed=()
    
    if [[ $total -eq 0 ]]; then
        log_warn "No packages to install"
        return 0
    fi
    
    log_info "Installing $total packages..."
    
    for package_info in "${packages[@]}"; do
        ((current++))
        
        # Parse package info (name:type:description)
        local name=$(echo "$package_info" | cut -d: -f1)
        local type=$(echo "$package_info" | cut -d: -f2)
        local desc=$(echo "$package_info" | cut -d: -f3-)
        
        show_progress "$current" "$total" "Installing packages"
        
        if ! install_package "$name" "$type" "$desc"; then
            failed+=("$name")
        fi
        
        # Small delay to prevent overwhelming the system
        sleep 0.5
    done
    
    echo  # New line after progress bar
    
    if [[ ${#failed[@]} -gt 0 ]]; then
        log_error "Failed to install ${#failed[@]} packages:"
        for pkg in "${failed[@]}"; do
            log_error "  - $pkg"
        done
        return 1
    fi
    
    log_success "Successfully installed all $total packages!"
}

# =============================================================================
# Interactive Package Selection
# =============================================================================

# Show packages menu using dialog for fast selection
show_packages_menu() {
    while true; do
        echo ""
        log_info "📦 Homebrew Package Manager"
        echo ""
        echo "1) Essentials (Basic tools)"
        echo "2) Development (Development tools)"  
        echo "3) Cloud (AWS, GCP, Azure tools)"
        echo "4) Container (Docker, K8s tools)"
        echo "5) Database (Database tools)"
        echo "6) Terminal (Terminal utilities)"
        echo "7) System (System utilities)"
        echo "8) Communication (Chat, productivity)"
        echo "9) IaC (Terraform, Ansible)"
        echo "10) AI (AI/ML tools)"
        echo "0) Back to Main Menu"
        echo ""
        read -p "Enter your choice [0-10]: " choice

        case "$choice" in
            1) install_category_dialog "Essentials" "ESSENTIALS" ;;
            2) install_category_dialog "Development" "DEVELOPMENT" ;;
            3) install_category_dialog "Cloud" "CLOUD" ;;
            4) install_category_dialog "Container" "CONTAINER" ;;
            5) install_category_dialog "Database" "DATABASE" ;;
            6) install_category_dialog "Terminal" "TERMINAL" ;;
            7) install_category_dialog "System" "SYSTEM" ;;
            8) install_category_dialog "Communication" "COMMUNICATION" ;;
            9) install_category_dialog "IaC" "IAC" ;;
            10) install_category_dialog "AI" "AI" ;;
            0) return 0 ;;
            *) log_error "Invalid choice! Please select a valid option." ;;
        esac
    done
}

# Create dialog checklist for package selection (simple approach like backup)
install_category_dialog() {
    local category_name="$1"
    local category_var="$2"
    
    check_homebrew_installed || return 1
    
    # Get packages array using eval (bash 3.2 compatible)
    local packages=()
    eval "packages=(\"\${${category_var}_PACKAGES[@]}\")"
    
    if [[ ${#packages[@]} -eq 0 ]]; then
        log_error "No packages found in category: $category_name"
        return 1
    fi
    
    # Check if dialog is available
    if ! command -v dialog &> /dev/null; then
        log_info "Dialog not found. Installing..."
        brew install dialog || {
            log_error "Failed to install dialog. Using fallback method."
            install_category_simple "$category_name" "$category_var"
            return
        }
    fi
    
    # Create the dialog checklist like the old backup version
    local selected_items=$(create_dialog_checklist "$category_name" "$category_var" 20 80 12)
    
    if [[ "$selected_items" ]]; then
        log_info "Installing selected $category_name: $selected_items"
        
        for item in $selected_items; do
            # Remove quotes
            item=$(echo "$item" | tr -d '"')
            
            log_info "Installing $item..."
            
            # Get package type by searching through the category
            local package_type="cli"
            for package_def in "${packages[@]}"; do
                local name=$(echo "$package_def" | cut -d: -f1)
                local type=$(echo "$package_def" | cut -d: -f2)
                
                if [[ "$name" == "$item" ]]; then
                    package_type="$type"
                    break
                fi
            done
            
            # Install based on type (like old backup)
            if [[ "$package_type" == "cask" ]]; then
                # Special case for stretchly
                if [[ "$item" == "stretchly" ]]; then
                    brew update && brew install --cask --no-quarantine stretchly
                else
                    brew install --cask "$item"
                fi
            else
                brew install "$item"
                
                # Special handling for zsh plugins (like old backup)
                case "$item" in
                    "zsh-syntax-highlighting")
                        printf "\nsource $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> ~/.zshrc
                        log_info "Sourced zsh-syntax-highlighting"
                        ;;
                    "zsh-autosuggestions")
                        printf "\nsource $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh" >> ~/.zshrc
                        log_info "Sourced zsh-autosuggestions"
                        ;;
                esac
            fi
        done
    else
        log_info "No $category_name selected for installation."
    fi
}

# Create dialog checklist from category (exact copy from backup approach)
create_dialog_checklist() {
    local title="$1"
    local category_var="$2"
    local height="$3"
    local width="$4"
    local list_height="$5"
    
    # Get packages array
    local packages=()
    eval "packages=(\"\${${category_var}_PACKAGES[@]}\")"
    
    # Create the dialog command
    local dialog_cmd="dialog --title \"$title\" --checklist \"Use SPACE to select/deselect options. Confirm your choice by clicking ENTER.\" $height $width $list_height"
    
    # Add packages to dialog
    for package_def in "${packages[@]}"; do
        local name=$(echo "$package_def" | cut -d: -f1)
        local type=$(echo "$package_def" | cut -d: -f2)
        local desc=$(echo "$package_def" | cut -d: -f3-)
        
        if [[ "$type" == "cask" ]]; then
            dialog_cmd="$dialog_cmd \"$name\" \"$name (GUI)\" OFF"
        else
            dialog_cmd="$dialog_cmd \"$name\" \"$name (CLI)\" OFF"
        fi
    done
    
    # Execute the dialog command
    eval "$dialog_cmd 3>&1 1>&2 2>&3"
}

# Install all packages with dialog selection
install_all_packages_dialog() {
    check_homebrew_installed || return 1
    
    # Check if dialog is available
    if ! command -v dialog &> /dev/null; then
        log_info "Dialog not found. Installing..."
        brew install dialog || {
            log_error "Failed to install dialog."
            return 1
        }
    fi
    
    local temp_file=$(mktemp)
    local dialog_cmd="dialog --title \"Choose packages to install\" --checklist \"Use SPACE to select/deselect, ENTER to confirm, ESC to cancel\" 24 100 16"
    
    # Collect all packages from all categories
    local categories=("ESSENTIALS" "DEVELOPMENT" "CLOUD" "CONTAINER" "DATABASE" "TERMINAL" "SYSTEM" "COMMUNICATION" "IAC" "AI")
    
    for category in "${categories[@]}"; do
        # Get packages array using eval (bash 3.2 compatible)
        local packages=()
        eval "packages=(\"\${${category}_PACKAGES[@]}\")"
        
        # Get category display name
        local category_display=$(get_category_display_name "$category")
        
        for package_def in "${packages[@]}"; do
            local name=$(echo "$package_def" | cut -d: -f1)
            local type=$(echo "$package_def" | cut -d: -f2)
            local desc=$(echo "$package_def" | cut -d: -f3-)
            
            if [[ "$type" == "cask" ]]; then
                dialog_cmd="$dialog_cmd \"$name\" \"$category_display: $desc (GUI)\" OFF"
            else
                dialog_cmd="$dialog_cmd \"$name\" \"$category_display: $desc (CLI)\" OFF"
            fi
        done
    done
    
    # Execute dialog and capture selection
    local selected_items
    if selected_items=$(eval "$dialog_cmd 2>\"$temp_file\""); then
        selected_items=$(cat "$temp_file")
        rm -f "$temp_file"
        
        if [[ -n "$selected_items" ]]; then
            log_info "Installing selected packages..."
            install_selected_packages_mixed "$selected_items"
        else
            log_info "No packages selected."
        fi
    else
        rm -f "$temp_file"
        log_info "Installation cancelled."
    fi
    
    clear
}

# Helper function to get category display name
get_category_display_name() {
    case "$1" in
        "ESSENTIALS") echo "Essentials" ;;
        "DEVELOPMENT") echo "Development" ;;
        "CLOUD") echo "Cloud" ;;
        "CONTAINER") echo "Container" ;;
        "DATABASE") echo "Database" ;;
        "TERMINAL") echo "Terminal" ;;
        "SYSTEM") echo "System" ;;
        "COMMUNICATION") echo "Communication" ;;
        "IAC") echo "IaC" ;;
        "AI") echo "AI" ;;
        *) echo "Unknown" ;;
    esac
}

# Install selected packages from dialog
install_selected_packages() {
    local selected="$1"
    local category_var="$2"
    
    # Convert selected items (space-separated, quoted) to array
    local packages_to_install=()
    eval "packages_to_install=($selected)"
    
    if [[ ${#packages_to_install[@]} -eq 0 ]]; then
        log_info "No packages to install."
        return
    fi
    
    log_info "Installing ${#packages_to_install[@]} packages..."
    
    for package_name in "${packages_to_install[@]}"; do
        # Remove quotes
        package_name=$(echo "$package_name" | tr -d '"')
        
        # Get package type from category
        local package_type=$(get_package_type "$package_name" "$(echo "$category_var" | tr '[:upper:]' '[:lower:]')")
        
        install_package "$package_name" "$package_type"
    done
    
    log_success "Package installation completed!"
    read -p "Press any key to continue..."
}

# Install selected packages from mixed categories
install_selected_packages_mixed() {
    local selected="$1"
    
    # Convert selected items to array
    local packages_to_install=()
    eval "packages_to_install=($selected)"
    
    if [[ ${#packages_to_install[@]} -eq 0 ]]; then
        log_info "No packages to install."
        return
    fi
    
    log_info "Installing ${#packages_to_install[@]} packages..."
    
    for package_name in "${packages_to_install[@]}"; do
        # Remove quotes
        package_name=$(echo "$package_name" | tr -d '"')
        
        # Find package type by searching all categories
        local package_type="cli"
        local categories=("essentials" "development" "cloud" "container" "database" "terminal" "system" "communication" "iac" "ai")
        
        for category in "${categories[@]}"; do
            local found_type=$(get_package_type "$package_name" "$category")
            if [[ "$found_type" != "cli" ]] || package_exists_in_category "$package_name" "$category"; then
                package_type="$found_type"
                break
            fi
        done
        
        install_package "$package_name" "$package_type"
    done
    
    log_success "Package installation completed!"
    read -p "Press any key to continue..."
}

# Check if package exists in category
package_exists_in_category() {
    local package_name="$1"
    local category="$2"
    local packages_var="$(echo "$category" | tr '[:lower:]' '[:upper:]')_PACKAGES"
    
    # Use eval for variable reference (bash 3.2 compatible)
    local packages=()
    eval "packages=(\"\${${packages_var}[@]}\")"
    
    for package_def in "${packages[@]}"; do
        local name=$(echo "$package_def" | cut -d: -f1)
        if [[ "$name" == "$package_name" ]]; then
            return 0
        fi
    done
    return 1
}

# Simple fallback for when dialog is not available
install_category_simple() {
    local category_name="$1" 
    local category_var="$2"
    
    echo ""
    log_info "📦 $category_name Packages"
    echo ""
    
    # Use eval for variable reference (bash 3.2 compatible)
    local packages=()
    eval "packages=(\"\${${category_var}_PACKAGES[@]}\")"
    
    echo "Available packages:"
    local i=1
    for package_def in "${packages[@]}"; do
        local name=$(echo "$package_def" | cut -d: -f1)
        local type=$(echo "$package_def" | cut -d: -f2)
        local desc=$(echo "$package_def" | cut -d: -f3-)
        
        if [[ "$type" == "cask" ]]; then
            echo "$i) $name (GUI) - $desc"
        else
            echo "$i) $name (CLI) - $desc"
        fi
        ((i++))
    done
    
    echo ""
    echo "Enter package numbers (space-separated), 'a' for all, or '0' to go back:"
    read -p "> " choice
    
    # Process choice
    case "$choice" in
        "a"|"A")
            log_info "Installing all packages..."
            for package_def in "${packages[@]}"; do
                local name=$(echo "$package_def" | cut -d: -f1)
                local type=$(echo "$package_def" | cut -d: -f2)
                install_package "$name" "$type"
            done
            ;;
        "0")
            return 0
            ;;
        *)
            # Parse numbers and install selected packages
            local selected=()
            for num in $choice; do
                if [[ "$num" =~ ^[0-9]+$ ]] && [[ $num -ge 1 ]] && [[ $num -le ${#packages[@]} ]]; then
                    local package_def="${packages[$((num-1))]}"
                    local name=$(echo "$package_def" | cut -d: -f1)
                    local type=$(echo "$package_def" | cut -d: -f2)
                    install_package "$name" "$type"
                fi
            done
            ;;
    esac
}

# =============================================================================
# Package Management Operations
# =============================================================================

# Show installed packages
show_installed_packages() {
    log_info "Installed Packages"
    echo "=================="
    
    echo "Homebrew Formulae:"
    brew list --formula 2>/dev/null | column -c 80 || echo "  None installed"
    
    echo
    echo "Homebrew Casks:"
    brew list --cask 2>/dev/null | column -c 80 || echo "  None installed"
    
    echo
    read -p "Press Enter to continue..." -r
}

# Update all packages
update_packages() {
    
    log_info "Updating Homebrew and all packages..."
    
    brew update || log_error "Failed to update Homebrew"
    brew upgrade || log_error "Failed to upgrade packages"
    brew cleanup || log_warn "Failed to cleanup old packages"
    
    log_success "Package update completed"
    
    echo
    read -p "Press Enter to continue..." -r
}

# Install recommended packages (essentials)
install_recommended_packages() {
    log_info "Installing recommended essential packages..."
    
    if confirm "Install essential development tools (git, curl, wget, jq, tree)?" "y"; then
        install_packages "${ESSENTIALS_PACKAGES[@]}"
    fi
}

# =============================================================================
# Helper Functions
# =============================================================================

# Check if Homebrew is installed
check_homebrew_installed() {
    if ! command -v brew &> /dev/null; then
        log_error "Homebrew is not installed. Please install Homebrew first."
        return 1
    fi
    return 0
}

