#!/bin/bash

PLIST_PATH=~/Library/LaunchAgents/com.local.KeyRemapping.plist
LABEL=com.local.KeyRemapping

create_launch_agent() {
    select_device
    
    if [[ -z "$vendor_id" || -z "$product_id" ]]; then
        echo "Missing device identifiers. Aborting."
        return 1
    fi
    
    cat > "$PLIST_PATH" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/hidutil</string>
        <string>property</string>
        <string>--matching</string>
        <string>{"VendorID":$vendor_id,"ProductID":$product_id}</string>
        <string>--set</string>
        <string>{"UserKeyMapping":[
            {
              "HIDKeyboardModifierMappingSrc": 0x7000000E7,
              "HIDKeyboardModifierMappingDst": 0x7000000E6
            },
            {
              "HIDKeyboardModifierMappingSrc": 0x7000000E6,
              "HIDKeyboardModifierMappingDst": 0x7000000E7
            }
        ]}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
EOF

    chmod 644 "$PLIST_PATH"
    
    echo "Created plist: $PLIST_PATH"
    echo "Loading service..."
    
    launchctl bootout gui/$(id -u) "$LABEL" 2>/dev/null || true
    launchctl bootstrap gui/$(id -u) "$PLIST_PATH"
    launchctl enable gui/$(id -u)/"$LABEL"
    
    echo "Key mapping active."
}

select_device() {
    echo "Detecting HID devices..."
    hidutil list
    
    echo
    read -p "Enter keyboard name (e.g., 'MX Keys'): " keyboard_name
    keyboard_name="${keyboard_name:-MX Keys}"
    
    vendor_id=$(hidutil list | grep -i "$keyboard_name" | head -1 | awk '{print $1}')
    product_id=$(hidutil list | grep -i "$keyboard_name" | head -1 | awk '{print $2}')
    
    if [[ -z "$vendor_id" || -z "$product_id" ]]; then
        echo "Device not found: $keyboard_name"
        read -p "VendorID (e.g., 0x046d): " vendor_id
        read -p "ProductID (e.g., 0xb35b): " product_id
    else
        echo "Selected: $keyboard_name (VendorID: $vendor_id, ProductID: $product_id)"
    fi
}

uninstall_service() {
    echo "Uninstalling service..."
    launchctl bootout gui/$(id -u) "$LABEL" 2>/dev/null
    rm "$PLIST_PATH" 2>/dev/null
    hidutil property --set '{"UserKeyMapping":[]}'
    echo "Service uninstalled."
}

show_menu() {
    echo
    echo "Key Mapping Tool (macOS)"
    echo "1. Create and load configuration"
    echo "2. Uninstall service"
    echo "3. Open mapping generator"
    echo "0. Exit"
    
    read -p "Choose option: " choice

    case $choice in
        1) create_launch_agent ;;
        2) uninstall_service ;;
        3) open "https://hidutil-generator.netlify.app" ;;
        0) exit 0 ;;
        *) echo "Invalid option" ;;
    esac
    
    [[ "$choice" != "0" ]] && { read -p "Press Enter to continue..."; show_menu; }
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    show_menu
fi
