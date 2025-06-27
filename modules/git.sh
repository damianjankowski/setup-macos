#!/bin/bash

# =============================================================================
# Git Configuration Module
# Simple Git setup with work/personal identities (simplified version)
# =============================================================================

# Git configuration files
readonly MAIN_GITCONFIG="$HOME/.gitconfig"
readonly PERSONAL_GITCONFIG="$HOME/.gitconfig-personal"
readonly WORK_GITCONFIG="$HOME/.gitconfig-work"

# =============================================================================
# Simple Git Setup Functions
# =============================================================================

# Setup Git identities using .env file (like legacy version)
setup_git_identities() {
    log_info "Setting up Git identities..."
    
    # Load environment variables if available
    if [[ -f ".env" ]]; then
        log_info "Loading .env variables..."
        load_env || {
            log_error ".env file found but failed to load"
            return 1
        }
    else
        log_error ".env file not found. Please create one with PERSONAL_NAME, PERSONAL_EMAIL, WORK_NAME, WORK_EMAIL"
        return 1
    fi
    
    # Check for required variables
    if [[ -z "${PERSONAL_NAME:-}" || -z "${PERSONAL_EMAIL:-}" || -z "${WORK_NAME:-}" || -z "${WORK_EMAIL:-}" ]]; then
        log_error "Missing required environment variables in .env file"
        log_info "Required: PERSONAL_NAME, PERSONAL_EMAIL, WORK_NAME, WORK_EMAIL"
        return 1
    fi

    
    # Backup existing configuration
    if [[ -f "$MAIN_GITCONFIG" ]]; then
        backup_file "$MAIN_GITCONFIG"
    fi
    
    # Create main gitconfig (work as default)
    log_info "Creating ~/.gitconfig"
    cat > "$MAIN_GITCONFIG" <<EOF
[user]
    name = $WORK_NAME
    email = $WORK_EMAIL

[credential]
    helper = osxkeychain

[init]
    defaultBranch = main

[pull]
    rebase = false

[push]
    default = simple

[core]
    autocrlf = input
    editor = nano

[color]
    ui = auto

[includeIf "gitdir:~/src/"]
    path = $PERSONAL_GITCONFIG

[includeIf "gitdir:~/repo/"]
    path = $WORK_GITCONFIG
EOF

    # Create personal gitconfig
    log_info "Creating ~/.gitconfig-personal"
    cat > "$PERSONAL_GITCONFIG" <<EOF
[user]
    name = $PERSONAL_NAME
    email = $PERSONAL_EMAIL

[credential]
    helper = osxkeychain
EOF

    # Create work gitconfig
    log_info "Creating ~/.gitconfig-work"
    cat > "$WORK_GITCONFIG" <<EOF
[user]
    name = $WORK_NAME
    email = $WORK_EMAIL

[credential]
    helper = osxkeychain
EOF

    # Create directories if they don't exist
    mkdir -p ~/src ~/repo
    
    log_success "Git identities configured successfully!"
    echo
    echo "Git identity mapping:"
    echo "Work repos → ~/repo/  (uses $WORK_EMAIL)"
    echo "Personal repos → ~/src/  (uses $PERSONAL_EMAIL)"
}

# Basic Git setup (install if needed)
setup_git() {
    log_info "Setting up Git..."
    
    # Check if Git is installed
    if ! command_exists git; then
        log_info "Git not found. Installing via Homebrew..."
        if is_brew_installed; then
            brew install git || {
                log_error "Failed to install Git"
                return 1
            }
        else
            log_error "Homebrew is required to install Git"
            return 1
        fi
    fi
    
    log_success "Git is available: $(git --version)"
}

# Show current Git configuration
show_git_status() {
    echo "Git Status:"
    echo "==========="
    
    if ! command_exists git; then
        echo "❌ Git is not installed"
        return 1
    fi
    
    echo "✅ Git version: $(git --version)"
    
    # Show current configuration
    local current_name=$(git config user.name 2>/dev/null)
    local current_email=$(git config user.email 2>/dev/null)
    
    if [[ -n "$current_name" && -n "$current_email" ]]; then
        echo "Current identity: $current_name <$current_email>"
    else
        echo "❌ Git identity not configured"
    fi
    
    # Check configuration files
    echo
    echo "Configuration files:"
    [[ -f "$MAIN_GITCONFIG" ]] && echo "  ✅ $MAIN_GITCONFIG" || echo "  ❌ $MAIN_GITCONFIG"
    [[ -f "$PERSONAL_GITCONFIG" ]] && echo "  ✅ $PERSONAL_GITCONFIG" || echo "  ❌ $PERSONAL_GITCONFIG"
    [[ -f "$WORK_GITCONFIG" ]] && echo "  ✅ $WORK_GITCONFIG" || echo "  ❌ $WORK_GITCONFIG"
}

# Simple Git menu
show_git_menu() {
    while true; do
        echo
        log_info "Git Setup"
        echo "========="
        
        # Show current status
        if command_exists git; then
            echo "✅ Git is installed: $(git --version)"
            local current_name=$(git config user.name 2>/dev/null)
            if [[ -n "$current_name" ]]; then
                echo "✅ Git is configured for: $current_name"
            else
                echo "⚠️  Git identity not configured"
            fi
        else
            echo "❌ Git is not installed"
        fi
        
        echo
        echo "1) Install/Setup Git"
        echo "2) Setup Git identities"
        echo "3) Show Git status"
        echo "0) Back to main menu"
        
        local choice=$(get_input "Enter your choice" "0")
        
        case "$choice" in
            "1") setup_git ;;
            "2") setup_git_identities ;;
            "3") show_git_status ;;
            "0") break ;;
            *) log_error "Invalid choice: $choice" ;;
        esac
        
        # Pause for user to read output
        if [[ "$choice" != "0" ]]; then
            echo
            read -p "Press Enter to continue..." -r
        fi
    done
} 