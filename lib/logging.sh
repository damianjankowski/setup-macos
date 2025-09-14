#!/bin/bash

if [[ -n "$_LOGGING_LIB_LOADED" ]]; then
    return 0
fi

_LOGGING_LIB_LOADED=true

LOG_LEVEL_DEBUG=0
LOG_LEVEL_INFO=1
LOG_LEVEL_WARN=2
LOG_LEVEL_ERROR=3

if [[ -z "$LOG_LEVEL" ]]; then
    LOG_LEVEL=$LOG_LEVEL_DEBUG
fi

if [[ -t 1 ]] && [[ -n "$TERM" ]]; then
    LOG_COLOR_DEBUG="\033[36m"  # Cyan
    LOG_COLOR_INFO="\033[32m"   # Green
    LOG_COLOR_WARN="\033[33m"   # Yellow
    LOG_COLOR_ERROR="\033[31m"  # Red
    LOG_COLOR_RESET="\033[0m"   # Reset
    LOG_COLOR_BLUE="\033[34m"   # Blue
else
    LOG_COLOR_DEBUG=""
    LOG_COLOR_INFO=""
    LOG_COLOR_WARN=""
    LOG_COLOR_ERROR=""
    LOG_COLOR_RESET=""
    LOG_COLOR_BLUE=""
fi

get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

log_message() {
    local level="$1"
    local message="$2"
    local color="$3"
    if [[ $level -ge $LOG_LEVEL ]]; then
        local timestamp=$(get_timestamp)
        local level_name=""
        
        case $level in
            $LOG_LEVEL_DEBUG) level_name="DEBUG" ;;
            $LOG_LEVEL_INFO)  level_name="INFO"  ;;
            $LOG_LEVEL_WARN)  level_name="WARN"  ;;
            $LOG_LEVEL_ERROR) level_name="ERROR" ;;
        esac
        
        echo -e "${color}[${timestamp}] [${level_name}] ${message}${LOG_COLOR_RESET}" >&2
    fi
}

log_debug() {
    log_message $LOG_LEVEL_DEBUG "$1" "$LOG_COLOR_DEBUG"
}

log_info() {
    log_message $LOG_LEVEL_INFO "$1" "$LOG_COLOR_INFO"
}

log_warn() {
    log_message $LOG_LEVEL_WARN "$1" "$LOG_COLOR_WARN"
}

log_error() {
    log_message $LOG_LEVEL_ERROR "$1" "$LOG_COLOR_ERROR"
}

log_blue() {
    log_message $LOG_LEVEL_BLUE "$1" "$LOG_COLOR_BLUE"
}

export -f log_debug log_info log_warn log_error get_timestamp log_message
