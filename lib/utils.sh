#!/bin/bash

# Utilities for macOS setup
VERSION="2.0.0"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Logging functions
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}" >&2; }
log_debug() { [[ "${DEBUG:-0}" == "1" ]] && echo -e "${YELLOW}🐛 $1${NC}" || true; }

# System checks
check_macos() {
    [[ "$(uname)" == "Darwin" ]] || { log_error "macOS only"; exit 1; }
}

command_exists() { command -v "$1" >/dev/null 2>&1; }

validate_url() { [[ "$1" =~ ^https?:// ]]; }

# User interaction
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
    local value
    
    if [[ -n "$default" ]]; then
        read -p "$prompt [$default]: " value
        echo "${value:-$default}"
    else
        read -p "$prompt: " value
        echo "$value"
    fi
}

# System information
get_macos_version() { sw_vers -productVersion; }
is_apple_silicon() { [[ "$(uname -m)" == "arm64" ]]; }

# Homebrew helpers
is_brew_installed() { command_exists brew; }
get_brew_prefix() { is_apple_silicon && echo "/opt/homebrew" || echo "/usr/local"; }

# File operations
backup_file() {
    local file="$1"
    local backup_dir="${2:-${HOME}/.macos-setup/backups}"
    
    if [[ -f "$file" ]]; then
        mkdir -p "$backup_dir"
        local backup_file="${backup_dir}/$(basename "$file").$(date +%Y%m%d-%H%M%S).backup"
        cp "$file" "$backup_file"
        log_info "Backed up $file to $backup_file"
        echo "$backup_file"
    fi
}

# Initialize
init_utils() {
    check_macos
    log_debug "Utils v$VERSION loaded"
} 