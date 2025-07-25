#!/bin/bash

readonly FZF_GIT_DIR="$HOME/fzf-git.sh"

install_fzf_git() {
    log_info "Installing fzf-git.sh..."
    
    if ! command_exists git; then
        log_error "Git required"
        return 1
    fi
    
    if [[ -d "$FZF_GIT_DIR" ]]; then
        log_info "Updating existing installation..."
        cd "$FZF_GIT_DIR" && git pull origin main 2>/dev/null || {
            log_warn "Update failed, re-cloning..."
            rm -rf "$FZF_GIT_DIR"
        }
    fi
    
    if [[ ! -d "$FZF_GIT_DIR" ]]; then
        git clone https://github.com/junegunn/fzf-git.sh.git "$FZF_GIT_DIR" || {
            log_error "Failed to clone fzf-git.sh"
            return 1
        }
    fi
    
    log_success "fzf-git.sh installed at $FZF_GIT_DIR"
}

setup_git_identities() {
    log_info "Setting up Git identities..."
    
    if [[ ! -f ".env" ]]; then
        log_error ".env file not found"
        log_info "Required variables: PERSONAL_NAME, PERSONAL_EMAIL, WORK_NAME, WORK_EMAIL"
        return 1
    fi
    
    load_env || {
        log_error "Failed to load .env"
        return 1
    }
    
    if [[ -z "${PERSONAL_NAME:-}" || -z "${PERSONAL_EMAIL:-}" || -z "${WORK_NAME:-}" || -z "${WORK_EMAIL:-}" ]]; then
        log_error "Missing required environment variables"
        log_info "Required: PERSONAL_NAME, PERSONAL_EMAIL, WORK_NAME, WORK_EMAIL"
        return 1
    fi
    
    [[ -f "$GITCONFIG_PATH" ]] && backup_file "$GITCONFIG_PATH"
    
    log_info "Creating ~/.gitconfig"
    cat > "$GITCONFIG_PATH" <<EOF
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
    path = $PERSONAL_GITCONFIG_PATH

[includeIf "gitdir:~/repo/"]
    path = $WORK_GITCONFIG_PATH
EOF

    log_info "Creating ~/.gitconfig-personal"
    cat > "$PERSONAL_GITCONFIG_PATH" <<EOF
[user]
    name = $PERSONAL_NAME
    email = $PERSONAL_EMAIL

[credential]
    helper = osxkeychain
EOF

    log_info "Creating ~/.gitconfig-work"
    cat > "$WORK_GITCONFIG_PATH" <<EOF
[user]
    name = $WORK_NAME
    email = $WORK_EMAIL

[credential]
    helper = osxkeychain
EOF

    mkdir -p ~/src ~/repo
    
    log_success "Git identities configured!"
    echo "Work repos → ~/repo/ (uses $WORK_EMAIL)"
    echo "Personal repos → ~/src/ (uses $PERSONAL_EMAIL)"
}

setup_git() {
    log_info "Setting up Git..."
    
    if ! command_exists git; then
        log_info "Installing Git via Homebrew..."
        if is_brew_installed; then
            brew install git || {
                log_error "Failed to install Git"
                return 1
            }
        else
            log_error "Homebrew required to install Git"
            return 1
        fi
    fi
    
    log_success "Git available: $(git --version)"
}

show_git_status() {
    echo "Git Status"
    echo "=========="
    
    if ! command_exists git; then
        echo "❌ Git not installed"
        return 1
    fi
    
    echo "✅ Git version: $(git --version)"
    
    local current_name=$(git config user.name 2>/dev/null)
    local current_email=$(git config user.email 2>/dev/null)
    
    if [[ -n "$current_name" && -n "$current_email" ]]; then
        echo "Current identity: $current_name <$current_email>"
    else
        echo "❌ Git identity not configured"
    fi
    
    echo
    echo "Configuration files:"
    [[ -f "$GITCONFIG_PATH" ]] && echo "  ✅ ~/.gitconfig" || echo "  ❌ ~/.gitconfig"
    [[ -f "$PERSONAL_GITCONFIG_PATH" ]] && echo "  ✅ ~/.gitconfig-personal" || echo "  ❌ ~/.gitconfig-personal"
    [[ -f "$WORK_GITCONFIG_PATH" ]] && echo "  ✅ ~/.gitconfig-work" || echo "  ❌ ~/.gitconfig-work"
}

configure_git_delta() {
    if ! command_exists delta; then
        log_error "git-delta not installed. Install it first."
        return 1
    fi

    backup_file "$GITCONFIG_PATH"

    if ! grep -q '^\s*pager\s*=\s*delta' "$GITCONFIG_PATH"; then
        git config --global core.pager delta
        log_info "Set core.pager to delta"
    fi
    
    if ! grep -q '^\s*diffFilter\s*=\s*delta --color-only' "$GITCONFIG_PATH"; then
        git config --global interactive.diffFilter 'delta --color-only'
        log_info "Set interactive.diffFilter"
    fi

    if ! grep -q '^\[delta\]' "$GITCONFIG_PATH"; then
        cat >> "$GITCONFIG_PATH" <<EOF

[delta]
    navigate = true
    side-by-side = true
EOF
        log_info "Added [delta] section"
    else
        git config --global delta.navigate true
        git config --global delta.side-by-side true
    fi

    log_success "git-delta configured!"
}

show_git_menu() {
    while true; do
        echo
        log_info "Git Setup"
        
        if command_exists git; then
            echo "✅ Git installed: $(git --version)"
            local current_name=$(git config user.name 2>/dev/null)
            [[ -n "$current_name" ]] && echo "✅ Configured for: $current_name" || echo "⚠️  Not configured"
        else
            echo "❌ Git not installed"
        fi
        
        [[ -d "$FZF_GIT_DIR" ]] && echo "✅ fzf-git.sh installed" || echo "❌ fzf-git.sh not installed"
        
        echo
        echo "1) Install/Setup Git"
        echo "2) Setup Git identities"
        echo "3) Install fzf-git.sh"
        echo "4) Show Git status"
        echo "5) Configure git-delta"
        echo "0) Back"
        
        read -p "Choice [0-5]: " choice
        
        case "$choice" in
            1) setup_git ;;
            2) setup_git_identities ;;
            3) install_fzf_git ;;
            4) show_git_status ;;
            5) configure_git_delta ;;
            0) break ;;
            *) log_error "Invalid choice" ;;
        esac
        
        [[ "$choice" != "0" ]] && { echo; read -p "Press Enter to continue..."; }
    done
} 