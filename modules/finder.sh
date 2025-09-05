
#!/bin/bash

configure_finder_dialog() {
    log_info "Opening Finder configuration dialog..."
    
    if ! command -v dialog >/dev/null 2>&1; then
        log_error "dialog utility not found. Please install dialog first."
        return 1
    fi
    
    local temp_file=$(mktemp)
    
    dialog --title "Configure Finder Settings" \
           --backtitle "macOS Finder Configuration" \
           --checklist "Select Finder settings to enable:" \
           20 60 10 \
           "hidden_files" "Show hidden files" off \
           "screenshot_jpg" "Set screenshot type to jpg" off \
           "screenshot_desktop" "Set screenshot location to Desktop" off \
           "status_bar" "Show status bar" off \
           "path_bar" "Show path bar" off \
           "list_view" "Use list view by default" off \
           "folders_on_top" "Keep folders on top when sorting by name" off \
           "search_current" "Search the current folder by default" off \
           "disable_extension_warning" "Disable warning when changing a file extension" off \
           "show_extensions" "Show all filename extensions" off \
           2> "$temp_file"
    
    local dialog_exit_code=$?
    
    if [[ $dialog_exit_code -ne 0 ]]; then
        log_info "Dialog cancelled by user"
        rm -f "$temp_file"
        return 1
    fi
    
    local selected_options=$(cat "$temp_file")
    rm -f "$temp_file"
    
    if [[ -z "$selected_options" ]]; then
        log_info "No settings selected"
        return 1
    fi
    
    log_info "Processing selected Finder settings..."
    
    IFS=' ' read -a selected_array <<< "$selected_options"
    
    for setting in "${selected_array[@]}"; do
        setting=$(echo "$setting" | sed 's/^"//;s/"$//')
        apply_finder_setting "$setting"
    done
    
    log_info "Finder configuration completed"
    return 0
}

apply_finder_setting() {
    local setting="$1"
    
    case "$setting" in
        "hidden_files")
            show_hidden_files
            ;;
        "screenshot_jpg")
            set_screenshot_type_jpg
            ;;
        "screenshot_desktop")
            set_screenshot_location_desktop
            ;;
        "status_bar")
            show_status_bar
            ;;
        "path_bar")
            show_path_bar
            ;;
        "list_view")
            use_list_view_default
            ;;
        "folders_on_top")
            keep_folders_on_top
            ;;
        "search_current")
            search_current_folder_default
            ;;
        "disable_extension_warning")
            disable_extension_warning
            ;;
        "show_extensions")
            show_all_filename_extensions
            ;;
        *)
            log_warn "Unknown setting: $setting"
            ;;
    esac
}

show_hidden_files() {
    log_info "Enabling hidden files display..."
    defaults write com.apple.finder AppleShowAllFiles -bool true
    killall Finder
}

set_screenshot_type_jpg() {
    log_info "Setting screenshot type to JPG..."
    defaults write com.apple.screencapture type jpg
    killall SystemUIServer
}

set_screenshot_location_desktop() {
    log_info "Setting screenshot location to Desktop..."
    defaults write com.apple.screencapture location ~/Desktop
    killall SystemUIServer
}

show_status_bar() {
    log_info "Enabling status bar..."
    defaults write com.apple.finder ShowStatusBar -bool true
    killall Finder
}

show_path_bar() {
    log_info "Enabling path bar..."
    defaults write com.apple.finder ShowPathbar -bool true
    killall Finder
}

use_list_view_default() {
    log_info "Setting list view as default..."
    defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
    killall Finder
}

keep_folders_on_top() {
    log_info "Keeping folders on top when sorting by name..."
    defaults write com.apple.finder _FXSortFoldersFirst -bool true
    killall Finder
}

search_current_folder_default() {
    log_info "Setting search to current folder by default..."
    defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
    killall Finder
}

disable_extension_warning() {
    log_info "Disabling file extension change warning..."
    defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
    killall Finder
}

show_all_filename_extensions() {
    log_info "Showing all filename extensions..."
    defaults write com.apple.finder AppleShowAllExtensions -bool true
    killall Finder
}



main() {
    if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
        configure_finder_dialog
    fi
}

export -f configure_finder_dialog
export -f apply_finder_setting
export -f show_hidden_files
export -f set_screenshot_type_jpg
export -f set_screenshot_location_desktop
export -f show_status_bar
export -f show_path_bar
export -f use_list_view_default
export -f keep_folders_on_top
export -f search_current_folder_default
export -f disable_extension_warning
export -f show_all_filename_extensions

main "$@"


