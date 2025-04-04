#!/bin/bash

PLIST_PATH=~/Library/LaunchAgents/com.local.KeyRemapping.plist
LABEL=com.local.KeyRemapping

create_launch_agent() {
    select_device
    
    if [ -z "$vendor_id" ] || [ -z "$product_id" ]; then
        echo "Missing required device identifiers. Aborting."
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
    
    echo "Plist file has been created: $PLIST_PATH"
    
    echo "Loading the service..."
    launchctl bootout gui/$(id -u) "$LABEL" 2>/dev/null || true
    launchctl bootstrap gui/$(id -u) "$PLIST_PATH"
    launchctl enable gui/$(id -u)/"$LABEL"
    
    echo "Service has been loaded. Key mapping should be active."
}

select_device() {
    echo "Detecting connected HID devices..."
    hidutil list
    
    echo ""
    echo "Enter the name of your keyboard (e.g., 'MX Keys'):"
    read keyboard_name

    if [ -z "$keyboard_name" ]; then
        keyboard_name="MX Keys"
        echo "Using default keyboard: $keyboard_name"
    fi
    
    vendor_id=$(hidutil list | grep -i "$keyboard_name" | head -1 | awk '{print $1}')
    product_id=$(hidutil list | grep -i "$keyboard_name" | head -1 | awk '{print $2}')
    
    if [ -z "$vendor_id" ] || [ -z "$product_id" ]; then
        echo "Device not found with name: $keyboard_name"
        echo "Enter identifiers manually:"
        read -p "VendorID (e.g., 0x046d): " vendor_id
        read -p "ProductID (e.g., 0xb35b): " product_id
    else
        echo "Selected device: $keyboard_name with VendorID: $vendor_id, ProductID: $product_id"
    fi
}

uninstall_service() {
    echo "Uninstalling the service..."
    launchctl bootout gui/$(id -u) com.local.KeyRemapping 2>/dev/null; rm ~/Library/LaunchAgents/com.local.KeyRemapping.plist; hidutil property --set '{"UserKeyMapping":[]}'
    echo "Service has been uninstalled."
}

show_menu() {
    echo ""
    echo "Key Mapping Tool (macOS)"
    echo "1. Create and load configuration"
    echo "2. Uninstall service"
    echo "3. Open mapping generator"
    echo "0. Exit"
    read -p "Choose an option: " choice

    case $choice in
        1)
            create_launch_agent
            ;;
        2)
            uninstall_service
            ;;
        3)
            open "https://hidutil-generator.netlify.app"
            ;;
        0)
            exit 0
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
    
    if [[ "$choice" != "0" ]]; then
        read -p "Press Enter to continue..."
        show_menu
    fi
}

show_menu
