#!/bin/bash

setup_granted() {
    log_info "Setting up Granted..."

    if ! check_if_file_exists ~/.aws/config; then
        mkdir -p ~/.aws/config
    fi
    
    require_tool granted

	granted credentials add

    log_info "Setting up Granted..."
}

show_aws_menu() {
    clear
    echo "┌─────────────────────────────┐"
    echo "│         AWS Tools         │"
    echo "└─────────────────────────────┘"
    echo ""
    echo "1) Setup Granted"
    echo "0) Back"
    echo ""
}

handle_aws_menu() {
    while true; do
        show_aws_menu
        read -p "Choice [0-1]: " choice
        
        case $choice in
            1)
                setup_granted
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

aws_tools() {
    handle_aws_menu
}

export -f setup_granted