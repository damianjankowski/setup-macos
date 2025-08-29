#!/bin/bash
export HOSTNAME="${HOSTNAME:-MBP-DAMIAN}"

export BACKUP_DIR="${BACKUP_DIR:-/Users/damijankowski/src/infrastructure/bare-metal/env-configuration-backups}"
export VSCODE_CONFIG_DIR="${VSCODE_CONFIG_DIR:-$HOME/Library/Application Support/Code/User}"
export VSCODE_EXTENSIONS_DIR="${VSCODE_EXTENSIONS_DIR:-$HOME/.vscode/extensions}"

export CURSOR_CONFIG_DIR="${CURSOR_CONFIG_DIR:-$HOME/Library/Application Support/Cursor/User}"
export CURSOR_EXTENSIONS_DIR="${CURSOR_EXTENSIONS_DIR:-$HOME/.cursor/extensions}"

export PYCHARM_CONFIG_DIR="${PYCHARM_CONFIG_DIR:-$HOME/Library/Application Support/JetBrains}"

export ZSHRC_PATH="${ZSHRC_PATH:-$HOME/.zshrc}"
export ZPROFILE_PATH="${ZPROFILE_PATH:-$HOME/.zprofile}"

export OH_MY_ZSH_DIR="${OH_MY_ZSH_DIR:-$HOME/.oh-my-zsh}"
export GITCONFIG_PATH="${GITCONFIG_PATH:-$HOME/.gitconfig}"
export PERSONAL_GITCONFIG_PATH="${PERSONAL_GITCONFIG_PATH:-$HOME/.gitconfig-personal}"
export WORK_GITCONFIG_PATH="${WORK_GITCONFIG_PATH:-$HOME/.gitconfig-work}"

export SSH_CONFIG_PATH="${SSH_CONFIG_PATH:-$HOME/.ssh/config}"
export SSH_DIR="${SSH_DIR:-$HOME/.ssh}"
export AEROSPACE_CONFIG_DIR="${AEROSPACE_CONFIG_DIR:-$HOME/.config/aerospace}"
export DELTA_CONFIG_DIR="${DELTA_CONFIG_DIR:-$HOME/.config/delta}"
export KITTY_CONFIG_DIR="${KITTY_CONFIG_DIR:-$HOME/.config/kitty}"
export WARP_THEMES_DIR="${WARP_THEMES_DIR:-$HOME/.warp/themes}"
export YAZI_CONFIG_DIR="${YAZI_CONFIG_DIR:-$HOME/.config/yazi}"
export STARSHIP_CONFIG_DIR="${STARSHIP_CONFIG_DIR:-$HOME/.config}"

validate_config_paths() {
    local errors=0

    if [[ -z "$HOME" ]]; then
        echo "ERROR: HOME environment variable is not set" >&2
        ((errors++))
    fi

    if [[ -z "$SCRIPT_DIR" ]]; then
        echo "ERROR: SCRIPT_DIR is not set" >&2
        ((errors++))
    fi
    
    return $errors
}

init_config_dirs() {
    local dirs=(
        "$BACKUP_DIR"
        "$(dirname "$BACKUP_DIR")"  # Parent directory
    )
    
    for dir in "${dirs[@]}"; do
        if [[ -n "$dir" && ! -d "$dir" ]]; then
            if ! mkdir -p "$dir" 2>/dev/null; then
                log_warn "Could not create directory: $dir"
                return 1
            fi
        fi
    done
    
    return 0
}

show_config() {
    cat << EOF
macOS Setup Configuration:

BACKUP:
  BACKUP_DIR: $BACKUP_DIR

IDE PATHS:
  VSCODE_CONFIG_DIR: $VSCODE_CONFIG_DIR
  VSCODE_EXTENSIONS_DIR: $VSCODE_EXTENSIONS_DIR
  CURSOR_CONFIG_DIR: $CURSOR_CONFIG_DIR
  CURSOR_EXTENSIONS_DIR: $CURSOR_EXTENSIONS_DIR
  PYCHARM_CONFIG_DIR: $PYCHARM_CONFIG_DIR

SHELL PATHS:
  ZSHRC_PATH: $ZSHRC_PATH
  ZPROFILE_PATH: $ZPROFILE_PATH
  OH_MY_ZSH_DIR: $OH_MY_ZSH_DIR

APPLICATION PATHS:
  KITTY_CONFIG_DIR: $KITTY_CONFIG_DIR
  WARP_THEMES_DIR: $WARP_THEMES_DIR
  YAZI_CONFIG_DIR: $YAZI_CONFIG_DIR
  STARSHIP_CONFIG_DIR: $STARSHIP_CONFIG_DIR
  AEROSPACE_CONFIG_DIR: $AEROSPACE_CONFIG_DIR
  DELTA_CONFIG_DIR: $DELTA_CONFIG_DIR

GIT PATHS:
  GITCONFIG_PATH: $GITCONFIG_PATH
  PERSONAL_GITCONFIG_PATH: $PERSONAL_GITCONFIG_PATH
  WORK_GITCONFIG_PATH: $WORK_GITCONFIG_PATH

SSH PATHS:
  SSH_CONFIG_PATH: $SSH_CONFIG_PATH
  SSH_DIR: $SSH_DIR
EOF
}

init_config() {
    validate_config_paths || {
        log_error "Configuration validation failed"
        return 1
    }
    
    init_config_dirs || {
        log_warn "Some directories could not be created"
    }
    
    log_debug "Configuration initialized"
}