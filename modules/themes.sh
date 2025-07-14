#!/bin/bash

# =============================================================================
# Themes Configuration Module
# Catppuccin theme installations for various applications
# =============================================================================

# =============================================================================
# Bat Catppuccin Themes Installation
# =============================================================================

install_bat_catppuccin_themes() {
    log_info "Installing Catppuccin themes for bat..."
    local bat_config_dir
    bat_config_dir="$(bat --config-dir 2>/dev/null)"
    if [[ -z "$bat_config_dir" ]]; then
        log_error "Could not determine bat config directory. Is bat installed?"
        return 1
    fi
    mkdir -p "$bat_config_dir/themes"
    log_info "Created theme directory: $bat_config_dir/themes"

    wget -P "$bat_config_dir/themes" https://github.com/catppuccin/bat/raw/main/themes/Catppuccin%20Latte.tmTheme
    wget -P "$bat_config_dir/themes" https://github.com/catppuccin/bat/raw/main/themes/Catppuccin%20Frappe.tmTheme
    wget -P "$bat_config_dir/themes" https://github.com/catppuccin/bat/raw/main/themes/Catppuccin%20Macchiato.tmTheme
    wget -P "$bat_config_dir/themes" https://github.com/catppuccin/bat/raw/main/themes/Catppuccin%20Mocha.tmTheme

    log_info "Rebuilding bat theme cache..."
    bat cache --build && log_success "Catppuccin themes installed and cache rebuilt!" || log_error "Failed to rebuild bat cache."
}

# =============================================================================
# Kitty Catppuccin Themes Installation
# =============================================================================

install_kitty_catppuccin_themes() {
    log_info "Installing Catppuccin themes for kitty..."
    
    # Check if git is available
    if ! command_exists git; then
        log_error "Git is required to clone kitty themes repository"
        return 1
    fi
    
    local kitty_config_dir="$HOME/.config/kitty"
    local kitty_themes_dir="$kitty_config_dir/kitty-themes"
    local kitty_config_file="$kitty_config_dir/kitty.conf"
    
    # Create kitty config directory if it doesn't exist
    mkdir -p "$kitty_config_dir"
    
    # Remove existing kitty-themes directory if it exists and clone fresh
    if [[ -d "$kitty_themes_dir" ]]; then
        log_info "Removing existing kitty-themes directory..."
        rm -rf "$kitty_themes_dir"
    fi
    
    log_info "Cloning Catppuccin kitty themes..."
    git clone https://github.com/catppuccin/kitty.git "$kitty_themes_dir" || {
        log_error "Failed to clone Catppuccin kitty themes repository"
        return 1
    }
    
    log_success "Catppuccin kitty themes downloaded to $kitty_themes_dir"
    
    # Create or backup existing kitty.conf
    if [[ -f "$kitty_config_file" ]]; then
        backup_file "$kitty_config_file"
    else
        touch "$kitty_config_file"
    fi
    
    # Add include for Mocha theme if not already present
    local include_line="include $kitty_themes_dir/themes/mocha.conf"
    if ! grep -q "mocha.conf" "$kitty_config_file"; then
        echo "" >> "$kitty_config_file"
        echo "# Catppuccin Mocha theme" >> "$kitty_config_file"
        echo "$include_line" >> "$kitty_config_file"
        log_info "Added Catppuccin Mocha theme include to kitty.conf"
    else
        log_info "Catppuccin Mocha theme already configured in kitty.conf"
    fi
    
    log_success "Kitty Catppuccin themes installed and Mocha theme configured!"
    echo
    echo "Available themes in $kitty_themes_dir/themes/:"
    echo "• latte.conf"
    echo "• frappe.conf" 
    echo "• macchiato.conf"
    echo "• mocha.conf (currently configured)"
    echo
    echo "To switch themes, edit $kitty_config_file"
    echo "and change the include line to your preferred theme."
}

# =============================================================================
# Warp Catppuccin Themes Installation
# =============================================================================

install_warp_catppuccin_themes() {
    log_info "Installing Catppuccin themes for Warp..."
    
    # Check if git is available
    if ! command_exists git; then
        log_error "Git is required to clone warp themes repository"
        return 1
    fi
    
    local warp_themes_dir="$HOME/.warp/themes"
    local temp_clone_dir="/tmp/catppuccin-warp-$$"
    
    # Create warp themes directory if it doesn't exist
    mkdir -p "$warp_themes_dir"
    
    # Clone the repository to a temporary directory
    log_info "Cloning Catppuccin warp themes repository..."
    git clone https://github.com/catppuccin/warp.git "$temp_clone_dir" || {
        log_error "Failed to clone Catppuccin warp themes repository"
        return 1
    }
    
    # Copy all theme files from themes/ directory to warp themes directory
    if [[ -d "$temp_clone_dir/themes" ]]; then
        log_info "Copying theme files to $warp_themes_dir..."
        
        # List what files are actually in the themes directory for debugging
        log_info "Found files in themes directory:"
        ls -la "$temp_clone_dir/themes/"
        
        # Try copying .yaml files first
        local copied_files=0
        if ls "$temp_clone_dir/themes"/*.yaml >/dev/null 2>&1; then
            cp "$temp_clone_dir/themes"/*.yaml "$warp_themes_dir/"
            copied_files=$((copied_files + $(ls "$temp_clone_dir/themes"/*.yaml 2>/dev/null | wc -l)))
        fi
        
        # Try copying .yml files
        if ls "$temp_clone_dir/themes"/*.yml >/dev/null 2>&1; then
            cp "$temp_clone_dir/themes"/*.yml "$warp_themes_dir/"
            copied_files=$((copied_files + $(ls "$temp_clone_dir/themes"/*.yml 2>/dev/null | wc -l)))
        fi
        
        # Try copying any other theme files (in case they have different extensions)
        if ls "$temp_clone_dir/themes"/* >/dev/null 2>&1; then
            # Copy all files that are not directories
            find "$temp_clone_dir/themes" -maxdepth 1 -type f -exec cp {} "$warp_themes_dir/" \;
            copied_files=$((copied_files + $(find "$temp_clone_dir/themes" -maxdepth 1 -type f | wc -l)))
        fi
        
        if [[ $copied_files -eq 0 ]]; then
            log_error "No theme files found in themes directory."
            log_info "Available files:"
            ls -la "$temp_clone_dir/themes/" || log_error "Could not list themes directory"
            rm -rf "$temp_clone_dir"
            return 1
        fi
        
        log_success "Successfully copied $copied_files theme files to $warp_themes_dir"
        
        # List installed themes
        echo
        echo "Installed themes:"
        ls -1 "$warp_themes_dir"/ 2>/dev/null | while read -r theme; do
            echo "• $theme"
        done
        
        echo
        echo "To apply a theme:"
        echo "1. Restart Warp terminal"
        echo "2. Open Settings > Themes"
        echo "3. Select your preferred Catppuccin flavor"
        
    else
        log_error "Themes directory not found in repository"
        rm -rf "$temp_clone_dir"
        return 1
    fi
    
    # Clean up temporary directory
    rm -rf "$temp_clone_dir"
    
    log_success "Warp Catppuccin themes installation completed!"
}

# =============================================================================
# Yazi Catppuccin Themes Installation
# =============================================================================

install_yazi_catppuccin_themes() {
    log_info "Installing Catppuccin themes for Yazi..."
    
    # Check if git is available
    if ! command_exists git; then
        log_error "Git is required to clone yazi themes repository"
        return 1
    fi
    
    # Check if yazi is installed
    if ! command_exists yazi; then
        log_warning "Yazi is not installed. Installing themes anyway for future use."
    fi
    
    local yazi_config_dir="$HOME/.config/yazi"
    local temp_clone_dir="/tmp/catppuccin-yazi-$$"
    local bat_config_dir
    
    # Get bat config directory for .tmTheme files
    if command_exists bat; then
        bat_config_dir="$(bat --config-dir 2>/dev/null)"
    fi
    
    # Create yazi config directory if it doesn't exist
    mkdir -p "$yazi_config_dir"
    
    # Clone the repository to a temporary directory
    log_info "Cloning Catppuccin yazi themes repository..."
    git clone https://github.com/catppuccin/yazi.git "$temp_clone_dir" || {
        log_error "Failed to clone Catppuccin yazi themes repository"
        return 1
    }
    
    # Check if themes directory exists
    if [[ ! -d "$temp_clone_dir/themes" ]]; then
        log_error "Themes directory not found in repository"
        rm -rf "$temp_clone_dir"
        return 1
    fi
    
    # List available themes
    log_info "Available Catppuccin themes:"
    local themes=()
    local theme_files=()
    
    # First, try to find .toml files
    while IFS= read -r -d '' theme_file; do
        local theme_name=$(basename "$theme_file" .toml)
        # Store relative path from themes directory (e.g., "mocha/catppuccin-mocha-blue.toml")
        local relative_path="${theme_file#$temp_clone_dir/themes/}"
        themes+=("$theme_name")
        theme_files+=("$relative_path")
        echo "• $theme_name"
    done < <(find "$temp_clone_dir/themes" -name "*.toml" -print0 | sort -z)
    
    # If no .toml files found, look for any theme files
    if [[ ${#themes[@]} -eq 0 ]]; then
        log_warning "No .toml files found, checking for other theme file formats..."
        while IFS= read -r -d '' theme_file; do
            local theme_name=$(basename "$theme_file")
            local relative_path="${theme_file#$temp_clone_dir/themes/}"
            themes+=("$theme_name")
            theme_files+=("$relative_path")
            echo "• $theme_name"
        done < <(find "$temp_clone_dir/themes" -type f \( -name "*.yaml" -o -name "*.yml" -o -name "*.json" -o -name "*mocha*" -o -name "*latte*" -o -name "*frappe*" -o -name "*macchiato*" \) -print0 | sort -z)
    fi
    
    if [[ ${#themes[@]} -eq 0 ]]; then
        log_error "No theme files found in themes directory"
        log_info "Available files:"
        find "$temp_clone_dir/themes" -type f | head -10
        rm -rf "$temp_clone_dir"
        return 1
    fi
    
    echo
    echo "Select a theme to install (default: mocha):"
    for i in "${!themes[@]}"; do
        echo "$((i+1))) ${themes[i]}"
    done
    
    local choice=$(get_input "Enter your choice (1-${#themes[@]})" "4")
    
    # Validate choice and get theme name
    local selected_theme
    local selected_relative_path
    if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le "${#themes[@]}" ]]; then
        selected_theme="${themes[$((choice-1))]}"
        selected_relative_path="${theme_files[$((choice-1))]}"
    else
        # Find a default mocha theme
        local default_index=-1
        for i in "${!themes[@]}"; do
            if [[ "${themes[i]}" == *"mocha"* ]]; then
                default_index=$i
                break
            fi
        done
        
        if [[ $default_index -ge 0 ]]; then
            selected_theme="${themes[$default_index]}"
            selected_relative_path="${theme_files[$default_index]}"
            log_info "Invalid choice, defaulting to ${selected_theme} theme"
        else
            selected_theme="${themes[0]}"
            selected_relative_path="${theme_files[0]}"
            log_info "Invalid choice, defaulting to ${selected_theme} theme"
        fi
    fi
    
    local theme_file="$temp_clone_dir/themes/${selected_relative_path}"
    local target_theme_file="$yazi_config_dir/theme.toml"
    
    # Backup existing theme if it exists
    if [[ -f "$target_theme_file" ]]; then
        backup_file "$target_theme_file"
    fi
    
    # Copy selected theme
    if [[ ! -f "$theme_file" ]]; then
        log_error "Theme file does not exist: $theme_file"
        log_info "Available files in themes directory:"
        find "$temp_clone_dir/themes" -type f -name "*.toml" | while read -r file; do
            echo "  $(basename "$file")"
        done
        rm -rf "$temp_clone_dir"
        return 1
    fi
    
    cp "$theme_file" "$target_theme_file" || {
        log_error "Failed to copy theme file"
        rm -rf "$temp_clone_dir"
        return 1
    }
    
    log_success "Installed $selected_theme theme to $target_theme_file"
    
    # Set up syntax highlighting with .tmTheme if bat is available
    if [[ -n "$bat_config_dir" ]] && [[ -d "$bat_config_dir/themes" ]]; then
        log_info "Setting up Catppuccin syntax highlighting..."
        
        # Extract base theme name (mocha, frappe, macchiato, latte) from selected theme
        local base_theme=""
        if [[ "$selected_theme" == *"mocha"* ]]; then
            base_theme="Mocha"
        elif [[ "$selected_theme" == *"frappe"* ]]; then
            base_theme="Frappe"
        elif [[ "$selected_theme" == *"macchiato"* ]]; then
            base_theme="Macchiato"
        elif [[ "$selected_theme" == *"latte"* ]]; then
            base_theme="Latte"
        fi
        
        if [[ -n "$base_theme" ]]; then
            # Check if catppuccin bat themes are available
            local tmtheme_file="$bat_config_dir/themes/Catppuccin $base_theme.tmTheme"
            if [[ ! -f "$tmtheme_file" ]]; then
                # Try alternative naming
                tmtheme_file="$bat_config_dir/themes/Catppuccin-$base_theme.tmTheme"
            fi
            if [[ ! -f "$tmtheme_file" ]]; then
                # Try lowercase
                tmtheme_file="$bat_config_dir/themes/Catppuccin ${base_theme,,}.tmTheme"
            fi
            
            if [[ -f "$tmtheme_file" ]]; then
                # Update the syntect_theme option in the theme file
                if grep -q "syntect_theme" "$target_theme_file"; then
                    # Replace existing syntect_theme line
                    sed -i.bak "s|syntect_theme = .*|syntect_theme = \"$tmtheme_file\"|" "$target_theme_file"
                    log_info "Updated syntect_theme setting to use $tmtheme_file"
                else
                    # Add syntect_theme to the theme file
                    echo "" >> "$target_theme_file"
                    echo "# Catppuccin syntax highlighting" >> "$target_theme_file"
                    echo "syntect_theme = \"$tmtheme_file\"" >> "$target_theme_file"
                    log_info "Added syntect_theme setting for $tmtheme_file"
                fi
                log_success "Catppuccin syntax highlighting configured!"
            else
                log_warning "Catppuccin .tmTheme file not found for $base_theme"
                echo "To set up syntax highlighting:"
                echo "1. Install Catppuccin themes for bat first"
                echo "2. Edit $target_theme_file"
                echo "3. Add: syntect_theme = \"/path/to/catppuccin-${base_theme,,}.tmTheme\""
            fi
        else
            log_warning "Could not determine base theme for syntax highlighting"
            echo "To set up syntax highlighting:"
            echo "1. Install Catppuccin themes for bat first"
            echo "2. Edit $target_theme_file"
            echo "3. Add: syntect_theme = \"/path/to/catppuccin-theme.tmTheme\""
        fi
    else
        log_warning "Bat themes directory not found. Syntax highlighting not configured."
        echo "To set up syntax highlighting:"
        echo "1. Install bat and Catppuccin themes for bat"
        echo "2. Edit $target_theme_file"
        echo "3. Add: syntect_theme = \"/path/to/catppuccin-theme.tmTheme\""
    fi
    
    # Clean up temporary directory
    rm -rf "$temp_clone_dir"
    
    echo
    log_success "Yazi Catppuccin theme installation completed!"
    echo
    echo "Theme configuration: $target_theme_file"
    echo "To use the theme, restart Yazi or run: yazi"
    echo
    echo "Available themes can be switched by running this installer again"
    echo "or manually copying theme files from the repository."
}

# =============================================================================
# Delta Catppuccin Theme Configuration
# =============================================================================

configure_delta_catppuccin_theme() {
    if ! command_exists delta; then
        log_error "git-delta (delta) is not installed. Please install it first."
        return 1
    fi
    if ! command_exists wget; then
        log_error "wget is required to download the Catppuccin theme. Please install wget."
        return 1
    fi
    local delta_config_dir="$HOME/.config/delta"
    local catppuccin_config="$delta_config_dir/catppuccin.gitconfig"
    mkdir -p "$delta_config_dir"
    wget -O "$catppuccin_config" https://raw.githubusercontent.com/catppuccin/delta/main/catppuccin.gitconfig
    log_success "Downloaded Catppuccin delta theme to $catppuccin_config"

    local gitconfig="$HOME/.gitconfig"
    backup_file "$gitconfig"

    # Remove any previous include for catppuccin.gitconfig to avoid duplicates
    sed -i.bak '/catppuccin.gitconfig/d' "$gitconfig"
    # Add include path at the end
    printf "\n[include]\n    path = %s\n" "$catppuccin_config" >> "$gitconfig"
    log_info "Enforced Catppuccin theme include in ~/.gitconfig"

    # Enforce delta configuration
    git config --global core.pager delta
    git config --global interactive.diffFilter 'delta --color-only'
    git config --global delta.features catppuccin-mocha
    git config --global delta.side-by-side true
    git config --global delta.navigate true

    log_success "Catppuccin theme for delta is now fully enforced in your git configuration!"
}

# =============================================================================
# Themes Menu
# =============================================================================

show_themes_menu() {
    while true; do
        echo
        log_info "🎨 Catppuccin Themes Installation"
        echo "=================================="
        
        echo "Available theme installations:"
        echo
        echo "1) Install Catppuccin themes for bat"
        echo "2) Install Catppuccin themes for kitty"
        echo "3) Install Catppuccin themes for Warp"
        echo "4) Install Catppuccin themes for Yazi"
        echo "5) Configure Catppuccin theme for delta (git)"
        echo "6) Install all themes"
        echo "0) Back to main menu"
        
        local choice=$(get_input "Enter your choice" "0")
        
        case "$choice" in
            "1") install_bat_catppuccin_themes ;;
            "2") install_kitty_catppuccin_themes ;;
            "3") install_warp_catppuccin_themes ;;
            "4") install_yazi_catppuccin_themes ;;
            "5") configure_delta_catppuccin_theme ;;
            "6") install_all_catppuccin_themes ;;
            "0") break ;;
            *) log_error "Invalid choice: $choice" ;;
        esac
        
        if [[ "$choice" != "0" ]]; then
            echo
            read -p "Press Enter to continue..." -r
        fi
    done
}

# Install all Catppuccin themes
install_all_catppuccin_themes() {
    log_info "Installing all Catppuccin themes..."
    echo
    
    install_bat_catppuccin_themes
    echo
    install_kitty_catppuccin_themes
    echo
    install_warp_catppuccin_themes
    echo
    install_yazi_catppuccin_themes
    echo
    configure_delta_catppuccin_theme
    
    log_success "All Catppuccin themes have been installed!"
} 