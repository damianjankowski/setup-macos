#!/bin/bash

# Source the categories file
source "$(dirname "$0")/brew_categories.sh"

# Colors and formatting
BOLD=$(tput bold)
NORM=$(tput sgr0)
FANCY_COLOR='\033[38;5;39m'

log() {
  echo -e "${FANCY_COLOR}$1${NORM}"
}

# Check if Homebrew is installed
check_brew_installed() {
  if ! command -v brew &> /dev/null; then
    log "Homebrew is not installed. Please install Homebrew first."
    exit 1
  fi
}

# Install Homebrew
install_brew() {
  if ! command -v brew &> /dev/null; then
    log "Installing homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    (echo; /opt/homebrew/bin/brew shellenv) >> /Users/$USER/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
    brew tap versent/homebrew-taps
  else
    log "Homebrew is already installed."
  fi
}

# Install common tools
install_common_tools() {
  check_brew_installed
  log "Installing common tools..."
  brew tap hashicorp/tap
  
  for tool in "${COMMON_TOOLS[@]}"; do
    log "Installing $tool..."
    brew install "$tool" || { log "Error installing $tool."; }
  done
}

# Function to create a dialog checklist from an array
create_dialog_checklist() {
  local title="$1"
  local array_name="$2"
  local height="$3"
  local width="$4"
  local list_height="$5"
  
  # Create the dialog command
  local dialog_cmd="dialog --title \"$title\" --checklist \"Use SPACE to select/deselect options. Confirm your choice by clicking ENTER.\" $height $width $list_height"
  
  # Pobierz tablicę jako lokalną
  local arr=()
  eval "arr=(\"\${$array_name[@]}\")"
  for ((i=0; i<${#arr[@]}; i+=2)); do
    name="${arr[$i]}"
    type="${arr[$i+1]}"
    if [[ "$type" == "gui" ]]; then
      dialog_cmd="$dialog_cmd \"$name\" \"$name (GUI)\" OFF"
    else
      dialog_cmd="$dialog_cmd \"$name\" \"$name (CLI)\" OFF"
    fi
  done
  
  # Execute the dialog command
  eval "$dialog_cmd 3>&1 1>&2 2>&3"
}

# Install packages from a specific category
install_category() {
  local category_name="$1"
  local category_array="$2"
  
  check_brew_installed
  log "Installing $category_name..."
  
  # Get the number of items in the category
  local item_count=$(eval "echo \${#$category_array[@]}")
  
  # Create dialog checklist
  local selected_items=$(create_dialog_checklist "Choose $category_name to install" "$category_array" 20 80 $item_count)
  
  if [[ "$selected_items" ]]; then
    log "Installing selected $category_name: $selected_items"
    
    for item in $selected_items; do
      # Remove quotes
      item=$(echo "$item" | tr -d '"')
      
      log "Installing $item..."
      
      # Special case for stretchly
      if [[ "$item" == "stretchly" ]]; then
        brew update && brew install --cask --no-quarantine stretchly
      # Special case for GUI apps
      elif [[ " ${GUI_APPS[*]} " =~ " ${item} " ]]; then
        brew install --cask "$item"
      # Special case for zsh plugins
      elif [[ " ${ZSH_PLUGINS[*]} " =~ " ${item} " ]]; then
        brew install "$item"
        
        # Add to .zshrc
        case "$item" in
          "zsh-syntax-highlighting")
            printf "\nsource $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> ~/.zshrc
            log "Sourced zsh-syntax-highlighting"
            ;;
          "zsh-autosuggestions")
            printf "\nsource $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh" >>~/.zshrc
            log "Sourced zsh-autosuggestions"
            ;;
        esac
      # Default case for CLI tools
      else
        brew install "$item"
      fi
    done
  else
    log "No $category_name selected for installation."
  fi
}

# Install all packages from all categories
install_all_packages() {
  check_brew_installed
  log "Installing packages from all categories..."
  
  # Get all packages
  local all_packages=($(get_all_packages))
  local item_count=${#all_packages[@]}
  
  # Create dialog checklist
  local dialog_cmd="dialog --title \"Choose packages to install\" --checklist \"Use SPACE to select/deselect options. Confirm your choice by clicking ENTER.\" 20 80 $item_count"
  
  # Add each item to the dialog command with its category and type
  for item in "${all_packages[@]}"; do
    local category=$(get_category_for_package "$item")
    local type="CLI"
    if [[ " ${GUI_APPS[*]} " =~ " ${item} " ]]; then
      type="GUI"
    fi
    dialog_cmd="$dialog_cmd \"$item\" \"$category ($type)\" OFF"
  done
  
  # Execute the dialog command
  local selected_items=$(eval "$dialog_cmd 3>&1 1>&2 2>&3")
  
  if [[ "$selected_items" ]]; then
    log "Installing selected packages: $selected_items"
    
    for item in $selected_items; do
      # Remove quotes
      item=$(echo "$item" | tr -d '"')
      
      log "Installing $item..."
      
      # Special case for stretchly
      if [[ "$item" == "stretchly" ]]; then
        brew update && brew install --cask --no-quarantine stretchly
      # Special case for GUI apps
      elif [[ " ${GUI_APPS[*]} " =~ " ${item} " ]]; then
        brew install --cask "$item"
      # Special case for zsh plugins
      elif [[ " ${ZSH_PLUGINS[*]} " =~ " ${item} " ]]; then
        brew install "$item"
        
        # Add to .zshrc
        case "$item" in
          "zsh-syntax-highlighting")
            printf "\nsource $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> ~/.zshrc
            log "Sourced zsh-syntax-highlighting"
            ;;
          "zsh-autosuggestions")
            printf "\nsource $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh" >>~/.zshrc
            log "Sourced zsh-autosuggestions"
            ;;
        esac
      # Default case for CLI tools
      else
        brew install "$item"
      fi
    done
  else
    log "No packages selected for installation."
  fi
}

# Main menu function
show_brew_menu() {
  while true; do
    echo ""
    log "Brew Package Installer Menu:"
    echo "1) Cloud & Infrastructure"
    echo "2) IaC"
    echo "3) Dev tools"
    echo "4) DB tools"
    echo "5) Container tools"
    echo "6) Terminal"
    echo "7) System Utilities"
    echo "8) Communication & Productivity tools"
    echo "9) Zsh Plugins"
    echo "10) All Packages"
    echo "0) Back to Main Menu"
    read -p "Enter your choice [0-10]: " choice

    case "$choice" in
      1) install_category "Cloud & Infrastructure" "CLOUD_TOOLS" ;;
      2) install_category "IaC" "IAC_TOOLS" ;;
      3) install_category "Dev tools" "DEV_TOOLS" ;;
      4) install_category "DB tools" "DB_TOOLS" ;;
      5) install_category "Container tools" "CONTAINER_TOOLS" ;;
      6) install_category "Terminal" "TERMINAL_TOOLS" ;;
      7) install_category "System Utilities" "SYS_UTILS" ;;
      8) install_category "Communication & Productivity tools" "COMM_TOOLS" ;;
      9) install_category "Zsh Plugins" "ZSH_PLUGINS" ;;
      10) install_all_packages ;;
      0) break ;;
      *) log "Invalid choice! Please select a valid option." ;;
    esac
  done
} 