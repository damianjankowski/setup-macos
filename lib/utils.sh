#!/bin/bash

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'
log_success() { printf '%b%s%b\n' "$GREEN" "✅ $1" "$NC"; }
log_info()    { printf '%b%s%b\n' "$BLUE"  "ℹ️  $1" "$NC"; }
log_warn()    { printf '%b%s%b\n' "$YELLOW" "⚠️  $1" "$NC"; }
log_error()   { printf '%b%s%b\n' "$RED"   "❌ $1" "$NC" >&2; }
log_debug()   { [[ "${DEBUG:-0}" == "1" ]] && printf '%b%s%b\n' "$YELLOW" "🐛 $1" "$NC" || true; }

check_macos() {
    [[ "$(uname)" == "Darwin" ]] || { log_error "macOS only"; exit 1; }
}

command_exists() { 
    command -v "$1" >/dev/null 2>&1; 
}

validate_url() { 
    local url="$1"
    [[ -n "$url" && "$url" =~ ^https?://[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(/.*)?$ ]]
}

validate_input() {
    local input="$1"
    local max_length="${2:-255}"

    [[ -n "$input" ]] || return 1
    [[ ${#input} -le $max_length ]] || return 1
    [[ ! "$input" =~ '[;&|`$]' ]] || return 1

    return 0
}


confirm() {
    local prompt="${1:-Are you sure?}"
    local default="${2:-n}"
    
    while true; do
        if [[ "$default" == "y" ]]; then
            read -p "$prompt [Y/n]: " answer
            answer="${answer:-y}"
        else
            read -p "$prompt [y/N]: " answer
            answer="${answer:-n}"
        fi
        
        case "${answer:0:1}" in
            [Yy]*) return 0 ;;
            [Nn]*) return 1 ;;
            *) echo "Please answer yes or no." ;;
        esac
    done
}

get_input() {
    local prompt="$1"
    local default="${2:-}"
    local max_length="${3:-255}"
    local value
    
    while true; do
        if [[ -n "$default" ]]; then
            read -p "$prompt [$default]: " value
            value="${value:-$default}"
        else
            read -p "$prompt: " value
        fi
        
        if validate_input "$value" "$max_length"; then
            echo "$value"
            return 0
        else
            log_error "Invalid input. Please try again."
        fi
    done
}

get_macos_version() { 
    sw_vers -productVersion; 
}

is_apple_silicon() { 
    [[ "$(uname -m)" == "arm64" ]]; 
}
is_brew_installed() { 
    command_exists brew; 
}

get_brew_prefix() { 
    if is_apple_silicon; then
        echo "/opt/homebrew"
    else
        echo "/usr/local"
    fi
}

backup_file() {
    local file="$1"
    local backup_dir="${2:-$BACKUP_DIR}"
    local timestamp="${3:-$(date +%Y%m%d-%H%M%S)}"
    
    [[ -n "$file" ]] || { log_error "No file specified for backup"; return 1; }
    [[ -f "$file" ]] || { log_warn "File not found: $file"; return 1; }
    
    backup_dir="${backup_dir:-$HOME/.macos-setup/backups}"
    if ! mkdir -p "$backup_dir" 2>/dev/null; then
        log_error "Failed to create backup directory: $backup_dir"
        return 1
    fi
    
    local backup_file="${backup_dir}/$(basename "$file").${timestamp}.backup"
    
    if cp "$file" "$backup_file" 2>/dev/null; then
        log_info "Backed up $file to $backup_file"
        echo "$backup_file"
        return 0
    else
        log_error "Failed to backup $file"
        return 1
    fi
}

backup_files() {
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local backup_dir="${1:-$BACKUP_DIR}"
    local failed=()
    local success=0
    
    shift
    
    [[ $# -eq 0 ]] && { log_warn "No files specified for backup"; return 0; }
    
    log_info "Backing up $# files with timestamp: $timestamp"
    
    for file in "$@"; do
        if backup_file "$file" "$backup_dir" "$timestamp"; then
            ((success++))
        else
            failed+=("$(basename "$file")")
        fi
    done
    
    if [[ ${#failed[@]} -gt 0 ]]; then
        log_warn "Failed to backup: ${failed[*]}"
    fi
    
    log_info "Successfully backed up $success/$# files"
    return $([[ $success -gt 0 ]] && echo 0 || echo 1)
}

safe_copy() {
    local src="$1"
    local dest="$2"
    local create_backup="${3:-false}"
    
    [[ -n "$src" && -n "$dest" ]] || { log_error "Source and destination required"; return 1; }
    [[ -e "$src" ]] || { log_error "Source does not exist: $src"; return 1; }

    if [[ "$create_backup" == "true" && -e "$dest" ]]; then
        backup_file "$dest" || log_warn "Failed to backup existing file: $dest"
    fi

    local dest_dir=$(dirname "$dest")
    if [[ ! -d "$dest_dir" ]]; then
        mkdir -p "$dest_dir" || { log_error "Failed to create directory: $dest_dir"; return 1; }
    fi
    
    if cp -r "$src" "$dest" 2>/dev/null; then
        log_info "Copied $src to $dest"
        return 0
    else
        log_error "Failed to copy $src to $dest"
        return 1
    fi
}

safe_mkdir() {
    local dir="$1"
    local mode="${2:-755}"
    
    [[ -n "$dir" ]] || { log_error "Directory path required"; return 1; }
    
    if [[ -d "$dir" ]]; then
        log_debug "Directory already exists: $dir"
        return 0
    fi
    
    if mkdir -p "$dir" 2>/dev/null && chmod "$mode" "$dir" 2>/dev/null; then
        log_debug "Created directory: $dir"
        return 0
    else
        log_error "Failed to create directory: $dir"
        return 1
    fi
}

cleanup_temp() {
    local temp_dir="${1:-/tmp/macos-setup-$$}"
    
    if [[ -d "$temp_dir" ]]; then
        rm -rf "$temp_dir" 2>/dev/null && log_debug "Cleaned up temp directory: $temp_dir"
    fi
}
setup_cleanup() {
    local temp_dir="${1:-/tmp/macos-setup-$$}"
    trap "cleanup_temp '$temp_dir'" EXIT
}

init_utils() {
    check_macos
    log_debug "Utils library loaded"
}