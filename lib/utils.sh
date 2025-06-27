#!/bin/bash

# =============================================================================
# Utilities Library
# Common functions, logging, and error handling for macOS setup scripts
# =============================================================================

# Version and metadata
SCRIPT_VERSION="2.0.0"
SCRIPT_NAME="macOS Setup Utilities"

# Colors and formatting
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# =============================================================================
# Logging Functions
# =============================================================================

# Success message
log_success() {
    local message="$1"
    echo -e "${GREEN}✅ ${message}${NC}"
}

# Info message
log_info() {
    local message="$1"
    echo -e "${BLUE}ℹ️  ${message}${NC}"
}

# Warning message
log_warn() {
    local message="$1"
    echo -e "${YELLOW}⚠️  ${message}${NC}"
}

# Error message
log_error() {
    local message="$1"
    echo -e "${RED}❌ ${message}${NC}" >&2
}

# Debug message (only shown if DEBUG=1)
log_debug() {
    local message="$1"
    if [[ "${DEBUG:-0}" == "1" ]]; then
        echo -e "${PURPLE}🐛 ${message}${NC}"
    fi
}

# Fancy colored message (backward compatibility)
log() {
    log_info "$1"
}

# =============================================================================
# Error Handling
# =============================================================================

# =============================================================================
# Validation Functions
# =============================================================================

# Check if running on macOS
check_macos() {
    if [[ "$(uname)" != "Darwin" ]]; then
        log_error "This script only works on macOS"
        exit 1
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Validate URL
validate_url() {
    local url="$1"
    if [[ ! "$url" =~ ^https?:// ]]; then
        return 1
    fi
    return 0
}



# =============================================================================
# User Interaction
# =============================================================================

# Ask user for confirmation
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
            [Yy]* ) return 0 ;;
            [Nn]* ) return 1 ;;
            * ) echo "Please answer yes or no." ;;
        esac
    done
}

# Get user input with validation
get_input() {
    local prompt="$1"
    local default="${2:-}"
    local validator="${3:-}"
    local value
    
    while true; do
        if [[ -n "$default" ]]; then
            read -p "$prompt [$default]: " value
            value="${value:-$default}"
        else
            read -p "$prompt: " value
        fi
        
        if [[ -n "$validator" ]] && ! eval "$validator '$value'"; then
            log_error "Invalid input. Please try again."
            continue
        fi
        
        echo "$value"
        break
    done
}

# =============================================================================
# System Information
# =============================================================================

# Get macOS version
get_macos_version() {
    sw_vers -productVersion
}

# Check if running on Apple Silicon
is_apple_silicon() {
    [[ "$(uname -m)" == "arm64" ]]
}

# =============================================================================
# Package Management
# =============================================================================

# Check if Homebrew is installed
is_brew_installed() {
    command_exists brew
}

# Get Homebrew prefix
get_brew_prefix() {
    if is_apple_silicon; then
        echo "/opt/homebrew"
    else
        echo "/usr/local"
    fi
}

# =============================================================================
# Cleanup and Maintenance
# =============================================================================

# Create backup of file
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

# =============================================================================
# Performance and Progress
# =============================================================================

# Show progress bar
show_progress() {
    local current="$1"
    local total="$2"
    local prefix="${3:-Progress}"
    
    local percent=$((current * 100 / total))
    local filled=$((percent / 2))
    local empty=$((50 - filled))
    
    printf "\r%s: [" "$prefix"
    printf "%*s" "$filled" | tr ' ' '█'
    printf "%*s" "$empty" | tr ' ' '░'
    printf "] %d%%" "$percent"
    
    if [[ "$current" -eq "$total" ]]; then
        echo
    fi
}

# Initialize utilities
init_utils() {
    check_macos
    log_info "Starting $SCRIPT_NAME v$SCRIPT_VERSION"
} 