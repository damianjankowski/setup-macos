#!/bin/bash

get_detailed_system_info() {
    log_info "Mac OS version:"
    sw_vers -productVersion 2>/dev/null || echo "Unknown"
    echo ""
    log_info "Kernel & arch:"
    uname -a
    echo ""
    log_info "SIP status:"
    csrutil status
    echo ""
    log_info "Gatekeeper status:"
    spctl --status
    echo ""
    log_info "Update history:"
    softwareupdate --history
    echo ""
    log_info "OS, kernel, secure boot, etc.:"
    system_profiler SPSoftwareDataType
    echo ""
    log_info "Configuration profiles (MDM):"
    profiles list
    echo ""
}

get_detailed_hardware_info() {
    log_info "Model, chip, RAM, serial:"
    system_profiler SPHardwareDataType
    echo ""
    log_info "CPU brand:"
    sysctl -n machdep.cpu.brand_string
    echo ""
    log_info "CPU details:"
    sysctl -a | grep -i "cpu\|brand\|cache"
    echo ""
    log_info "Displays/GPU:"
    system_profiler SPDisplaysDataType
    echo ""
    log_info "Memory slots:"
    system_profiler SPMemoryDataType
    echo ""
}

get_detailed_storage_info() {
    log_info "Disks & partitions:"
    diskutil list
    echo ""
    log_info "Info about current volume:"
    diskutil info /
    echo ""
    log_info "Info about current volume:"
    diskutil info /
    echo ""
    log_info "APFS containers/volumes:"
    diskutil apfs list
    echo ""
    log_info "Mounted filesystems:"
    df -h
    echo ""
    log_info "Mount options:"
    mount
    echo ""
    log_info "FileVault status:"
    fdesetup status
    echo ""
    log_info "Time Machine destinations:"
    tmutil destinationinfo
    echo ""
    log_info "Backups:"
    tmutil listbackups
    echo ""
}

get_detailed_power_info() {
    log_info "Getting detailed power information..."
    log_info "Battery status:"
    pmset -g batt
    echo ""
    log_info "Power management capabilities:"
    pmset -g cap
    echo ""
    log_info "Current power settings:"
    pmset -g custom
    echo ""
    log_info "Power/battery info:"
    system_profiler SPPowerDataType
    echo ""
}

get_detailed_network_info() {
    log_info "Getting detailed network information..."
    log_info "Maps en0/en1 to Wi-Fi/Ethernet:"
    networksetup -listallhardwareports
    echo ""
    log_info "Interfaces:"
    ifconfig -a
    echo ""
    log_info "Current IPv4 on en0:"
    ipconfig getifaddr en0
    echo ""
    log_info "DNS config:"
    scutil --dns
    echo ""
    log_info "Reachability paths:"
    scutil --nwi
    echo ""
    log_info "Default route/gateway:"
    route -n get default
    echo ""
    log_info "Routing table:"
    netstat -nr
    echo ""
    log_info "Network locations/services:"
    system_profiler SPNetworkDataType
    echo ""
    log_info "Bluetooth:"
    system_profiler SPBluetoothDataType
    echo ""
    log_info "Wi-Fi (detailed):"
    system_profiler SPAirPortDataType
    echo ""
}




show_system_info_menu() {
    clear
    echo "┌─────────────────────────────┐"
    echo "│         System Info Tools         │"
    echo "└─────────────────────────────┘"
    echo ""
	echo "1) Detailed system information"
    echo "2) Detailed hardware information"
    echo "3) Detailed storage information"
    echo "4) Detailed power information"
    echo "5) Detailed network information"
    echo "0) Back"
    echo ""
}

handle_system_info_menu() {
    while true; do
        show_system_info_menu
        read -p "Choice [0-5]: " choice
        
        case $choice in
            1)
                get_detailed_system_info
                wait_for_user
                ;;
            2)
                get_detailed_hardware_info
                wait_for_user
                ;;
            3)
                get_detailed_storage_info
                wait_for_user
                ;;
            4)
                get_detailed_power_info
                wait_for_user
                ;;
            5)
                get_detailed_network_info
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
system_info_tools() {
    handle_system_info_menu
}

export -f get_detailed_system_info get_detailed_hardware_info get_detailed_storage_info get_detailed_power_info get_detailed_network_info show_system_info_menu handle_system_info_menu system_info_tools