#!/bin/bash

_CONFIG_DATA=""

parse_config() {
    local config_file="$1"
    if [[ -z "$config_file" ]]; then
        config_file="./config.json"
    fi

    if [[ ! -f "$config_file" ]]; then
        log_error "Config file not found: $config_file"
        return 1
    fi
    if ! command -v jq >/dev/null 2>&1; then
        log_error "jq is required but not installed"
        return 1
    fi
    _CONFIG_DATA=$(jq '.' "$config_file" 2>/dev/null)
    
    if [[ $? -ne 0 ]] || [[ -z "$_CONFIG_DATA" ]]; then
        log_error "Failed to parse config file: $config_file"
        return 1
    fi

    log_info "Configuration loaded from: $config_file"
    return 0
}
get_config_value() {
    local key_name="$1"
    
    if [[ -z "$_CONFIG_DATA" ]]; then
        log_error "No configuration loaded. Call parse_config first."
        return 1
    fi

    if [[ -z "$key_name" ]]; then
        log_error "Key name is required"
        return 1
    fi
    local value=$(echo "$_CONFIG_DATA" | jq -r ".$key_name" 2>/dev/null)
    
    if [[ $? -ne 0 ]] || [[ "$value" == "null" ]]; then
        log_error "Key not found: $key_name"
        return 1
    fi

    echo "$value"
}

is_config_loaded() {
    [[ -n "$_CONFIG_DATA" ]]
}

parse_env() {
    local env_file="$1"
    if [[ -z "$env_file" ]]; then
        env_file=".env"
    fi

    if [[ ! -f "$env_file" ]]; then
        log_error "Env file not found: $env_file"
        return 1
    fi
    if [[ -f "$env_file" ]]; then
        set -a
        source "$env_file"
        set +a
        log_info "Environment variables loaded from: $env_file"
        return 0
    else
        log_error "Failed to load environment file: $env_file"
        return 1
    fi
}

get_env_value() {
    local var_name="$1"
    
    if [[ -z "$var_name" ]]; then
        log_error "Variable name is required"
        return 1
    fi
    local value
    eval "value=\$$var_name"
    
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
    local value=$(get_config_value "$key_name")
    
    if [[ $? -eq 0 ]]; then
        expand_value "$value"
    else
        return 1
    fi
}

get_expanded_env() {
    local var_name="$1"
    local value=$(get_env_value "$var_name")
    
    if [[ $? -eq 0 ]]; then
        expand_value "$value"
    else
        return 1
    fi
}  

export -f parse_config get_config_value expand_value get_expanded_config is_config_loaded parse_env get_env_value get_expanded_env
