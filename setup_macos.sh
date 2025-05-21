#!/bin/bash

if [ "$(uname)" != "Darwin" ]; then
  echo "This script only works on macOS."
  exit 1
fi

BOLD=$(tput bold)
NORM=$(tput sgr0)
FANCY_COLOR='\033[38;5;39m'

log () {
  echo -e "${FANCY_COLOR}$1${NORM}"
}

# Source the brew installer
source "$(dirname "$0")/brew_installer.sh"

install_ohmyzsh() {
  if [ -d "$HOME/.oh-my-zsh" ]; then
    log "Oh My Zsh is already installed."
    return
  fi
  log "Installing Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

install_rosetta() {
    if [ -e /usr/libexec/rosetta ]; then
        log "Rosetta is already installed."
        return 0
    fi

    read -p "Do you want to install Rosetta? (y/n) " answer
    case ${answer:0:1} in
        y|Y )
            log "Installing Rosetta..."
            /usr/sbin/softwareupdate --install-rosetta --agree-to-license
            
            if [ $? -eq 0 ]; then
                log "Rosetta was successfully installed."
            else
                log "There was a problem installing Rosetta."
                return 1
            fi
            ;;
        * )
            log "Installation of Rosetta was cancelled."
            return 0
            ;;
    esac
}

remap_keyboard() {
  log "Starting keyboard remapping tool..."
  
  if [ -f "./remap_keyboard.sh" ]; then
    chmod +x ./remap_keyboard.sh
    ./remap_keyboard.sh
  else
    log "Error: remap_keyboard.sh not found in the current directory."
    log "Please make sure the script is in the same directory as setup_macos.sh"
  fi
}

setup_git_identities() {
  log "Setup git identities..."
  
  if [ -f "./setup_git_identities.sh" ]; then
    chmod +x ./setup_git_identities.sh
    ./setup_git_identities.sh
  else
    log "Error: setup_git_identities.sh not found in the current directory."
    log "Please make sure the script is in the same directory as setup_macos.sh"
  fi
}

# Menu
while true; do
  echo ""
  log "Please choose an option:"
  echo "1) Install Homebrew"
  echo "2) Install Oh My Zsh"
  echo "3) Install Rosetta"
  echo "4) Install Common Tools"
  echo "5) Brew Package Manager"
  echo "6) Remap keyboard keys"  
  echo "7) Setup git identities"  
  echo "0) Exit"
  read -p "Enter your choice [0-7]: " choice

  case "$choice" in
    1) install_brew ;;
    2) install_ohmyzsh ;;
    3) install_rosetta ;;
    4) install_common_tools ;;
    5) show_brew_menu ;;
    6) remap_keyboard ;;
    7) setup_git_identities ;;
    0) log "Exiting..."; break ;;
    *) log "Invalid choice! Please select a valid option." ;;
  esac
done

