#!/bin/bash

_CONFIG_DATA=""

# Deterministic standard paths. config.json (if present) overrides any of these.
# Implemented as a function for bash 3.2 compatibility (macOS default shell lacks declare -A).
_get_config_default() {
    local key="$1"
    case "$key" in
        VSCODE_CONFIG_DIR)      echo "$HOME/Library/Application Support/Code/User" ;;
        ANTIGRAVITY_CONFIG_DIR) echo "$HOME/Library/Application Support/Antigravity/User" ;;
        CURSOR_CONFIG_DIR)      echo "$HOME/Library/Application Support/Cursor/User" ;;
        PYCHARM_CONFIG_DIR)     echo "$HOME/Library/Application Support/JetBrains" ;;
        GITCONFIG_PATH)         echo "$HOME/.gitconfig" ;;
        AEROSPACE_CONFIG_DIR)   echo "$HOME/.config/aerospace" ;;
        DELTA_CONFIG_DIR)       echo "$HOME/.config/delta" ;;
        DELTA_THEME_PATH)       echo "$HOME/.config/delta/catppuccin.gitconfig" ;;
        KITTY_CONFIG_DIR)       echo "$HOME/.config/kitty" ;;
        WARP_THEMES_DIR)        echo "$HOME/.warp/themes" ;;
        YAZI_CONFIG_DIR)        echo "$HOME/.config/yazi" ;;
        STARSHIP_CONFIG_DIR)    echo "$HOME/.config" ;;
        TMUX_CONFIG_DIR)        echo "$HOME/.config/tmux" ;;
        *)                      return 1 ;;
    esac
}

parse_config() {
    local config_file="$1"
    if [[ -z "$config_file" ]]; then
        config_file="${SCRIPT_DIR:-.}/config.json"
    fi

    if [[ ! -f "$config_file" ]]; then
        log_warn "Config file not found ($config_file) — using built-in path defaults"
        return 0
    fi
    if ! command -v jq >/dev/null 2>&1; then
        log_error "jq is required but not installed"
        return 1
    fi
    if ! _CONFIG_DATA=$(jq '.' "$config_file" 2>/dev/null) || [[ -z "$_CONFIG_DATA" ]]; then
        log_error "Failed to parse config file: $config_file"
        return 1
    fi

    log_info "Configuration loaded from: $config_file"
    return 0
}

get_config_value() {
    local key_name="$1"

    if [[ -z "$key_name" ]]; then
        log_error "Key name is required"
        return 1
    fi

    local value=""
    if [[ -n "$_CONFIG_DATA" ]]; then
        value=$(echo "$_CONFIG_DATA" | jq -r --arg k "$key_name" '.[$k] // empty')
    fi

    if [[ -z "$value" ]]; then
        value=$(_get_config_default "$key_name") || true
    fi

    if [[ -z "$value" ]]; then
        log_error "Key not found: $key_name"
        return 1
    fi

    echo "$value"
}

parse_env() {
    local env_file="$1"
    if [[ -z "$env_file" ]]; then
        env_file="${SCRIPT_DIR:-.}/.env"
    fi

    if [[ ! -f "$env_file" ]]; then
        log_warn ".env file not found ($env_file) — features requiring personal config (git identity, hostname) will be unavailable"
        return 0
    fi
    set -a
    # shellcheck source=/dev/null  # env file path is resolved at runtime
    source "$env_file"
    set +a
    log_info "Environment variables loaded from: $env_file"
    return 0
}

get_env_value() {
    local var_name="$1"

    if [[ -z "$var_name" ]]; then
        log_error "Variable name is required"
        return 1
    fi
    local value="${!var_name}"

    if [[ -z "$value" ]]; then
        log_error "Environment variable not found: $var_name"
        return 1
    fi

    echo "$value"
}

expand_value() {
    local value="$1"
    value="${value//\$HOME/$HOME}"
    value="${value//\$USER/$USER}"

    echo "$value"
}

get_expanded_config() {
    local key_name="$1"
    local value
    value=$(get_config_value "$key_name") || return 1
    expand_value "$value"
}

get_expanded_env() {
    local var_name="$1"
    local value
    value=$(get_env_value "$var_name") || return 1
    expand_value "$value"
}
