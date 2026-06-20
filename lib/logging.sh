#!/bin/bash

if [[ -n "$_LOGGING_LIB_LOADED" ]]; then
    return 0
fi
_LOGGING_LIB_LOADED=true

if [[ -t 2 ]] && [[ -n "$TERM" ]]; then
    LOG_COLOR_DEBUG="\033[36m"  # Cyan
    LOG_COLOR_INFO="\033[32m"   # Green
    LOG_COLOR_WARN="\033[33m"   # Yellow
    LOG_COLOR_ERROR="\033[31m"  # Red
    LOG_COLOR_BLUE="\033[34m"   # Blue
    LOG_COLOR_RESET="\033[0m"   # Reset
else
    LOG_COLOR_DEBUG=""
    LOG_COLOR_INFO=""
    LOG_COLOR_WARN=""
    LOG_COLOR_ERROR=""
    # shellcheck disable=SC2034  # consumed by lib/utils.sh (progress_bar, wait_for_user)
    LOG_COLOR_BLUE=""
    LOG_COLOR_RESET=""
fi

log_debug() {
    [[ -z "${DEBUG:-}" ]] && return 0
    echo -e "${LOG_COLOR_DEBUG}[DEBUG] $1${LOG_COLOR_RESET}" >&2
}

log_info() {
    echo -e "${LOG_COLOR_INFO}[INFO] $1${LOG_COLOR_RESET}" >&2
}

log_warn() {
    echo -e "${LOG_COLOR_WARN}[WARN] $1${LOG_COLOR_RESET}" >&2
}

log_error() {
    echo -e "${LOG_COLOR_ERROR}[ERROR] $1${LOG_COLOR_RESET}" >&2
}
