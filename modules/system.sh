#!/bin/bash

get_hostname() {
    log_info "Getting hostname..."

    current_hostname=$(scutil --get HostName)
    current_computer_name=$(scutil --get ComputerName)
    current_local_hostname=$(scutil --get LocalHostName)
    
    log_info "Current HostName: $current_hostname"
    log_info "Current ComputerName: $current_computer_name"
    log_info "Current LocalHostName: $current_local_hostname"
}

set_hostname() {
    get_hostname
    current_hostname=$(scutil --get HostName)
    local desired_hostname

    if ! desired_hostname=$(get_expanded_env "HOSTNAME"); then
        log_error "HOSTNAME variable is not defined in your environment file."
        return 1
    fi

    if [[ -z "$desired_hostname" ]]; then
        log_error "HOSTNAME variable is empty. Please set a valid value in your environment file."
        return 1
    fi
    
    if [[ "$current_hostname" == "$desired_hostname" ]]; then
        log_info "Hostname is already set to $current_hostname"
        return 0
    else
        log_info "Current hostname: $current_hostname"
        log_info "Desired hostname: $desired_hostname"
        ask_for_confirmation "Would you like to change it?"
        if [[ $? -eq 0 ]]; then
            log_info "Setting hostname to $desired_hostname"
            sudo scutil --set HostName "$desired_hostname"
            sudo scutil --set ComputerName "$desired_hostname"
            sudo scutil --set LocalHostName "$desired_hostname"
            log_info "HostName set to $desired_hostname"
            log_info "ComputerName set to $desired_hostname"
            log_info "LocalHostName set to $desired_hostname"
        else
            log_info "Hostname change cancelled"
        fi
    fi
}

show_system_menu() {
    clear
    echo "┌─────────────────────────────┐"
    echo "│         System Tools         │"
    echo "└─────────────────────────────┘"
    echo ""
    echo "1) Get hostname"
    echo "2) Set hostname"
    echo "3) Configure finder"
    echo "0) Back"
    echo ""
}

handle_system_menu() {
    while true; do
        show_system_menu
        read -p "Choice [0-1]: " choice
        
        case $choice in
            1)
                get_hostname
                wait_for_user
                ;;
            2)
                set_hostname
                wait_for_user
                ;;
            3)
                configure_finder_dialog
                wait_for_user
                ;;
            0)
                return
                ;;
            *)
                echo "Invalid choice. Please try again."
                sleep 1
                ;;
        esac
    done
}

system_tools() {
    handle_system_menu
}

export -f set_hostname get_hostname show_system_menu handle_system_menu system_tools