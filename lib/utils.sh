#!/bin/bash

ask_for_confirmation() {
    read -p "$1 [y/N]: " confirmation
    if [[ $confirmation != "y" ]]; then
        return 1
    fi
    return 0
}

ask_for_input() {
    read -p "$1: " input
    echo "$input"
}

wait_for_user() {
    echo ""
    if [[ -n "$LOG_COLOR_BLUE" ]]; then
        echo -e "${LOG_COLOR_BLUE}Press Enter to continue...${LOG_COLOR_RESET}"
    else
        echo -e "Press Enter to continue..."
    fi
    read -p ""
}

progress_bar() {
    local current=$1
    local total=$2
    local width=40
    local percentage=$((current * 100 / total))
    local bar_length=$((width * percentage / 100))
    local bar=""
    for ((i=0; i<width; i++)); do
        if [[ $i -lt $bar_length ]]; then
            bar="${bar}█"
        else
            bar="${bar}░"
        fi
    done
    if [[ -n "$LOG_COLOR_BLUE" ]]; then
        echo ""
        echo -e "${LOG_COLOR_BLUE}[$current/$total]${LOG_COLOR_RESET} ${LOG_COLOR_INFO}$bar${LOG_COLOR_RESET} ${LOG_COLOR_WARN}${percentage}%${LOG_COLOR_RESET}"
        echo ""
    else
        echo ""
        echo -e "[$current/$total] $bar ${percentage}%"
        echo ""
    fi
}

check_if_file_exists() {
    local file_path="$1"
    if [[ -f "$file_path" ]]; then
        return 0
    else
        log_error "File does not exist: $file_path"
        return 1
    fi
}

require_tool() {
    local tool_name="$1"
    if ! command -v "$tool_name" >/dev/null 2>&1; then
        log_error "Required tool not found: $tool_name"
        return 1
    fi
    return 0
}