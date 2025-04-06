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

check_brew_installed() {
  if ! command -v brew &> /dev/null; then
    log "Homebrew is not installed. Please install Homebrew first."
    exit 1
  fi
}

log "Welcome to DJ's package installer!"
echo "Press any key to start"
read -n 1 -s key
echo ""

install_brew () {
  if ! command -v brew &> /dev/null
  then
    log "Installing homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    (echo; /opt/homebrew/bin/brew shellenv) >> /Users/$USER/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
    brew tap versent/homebrew-taps
  else
    log "Homebrew is already installed."
  fi
}

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

install_common_tools () {
  check_brew_installed
  log "Installing most common tools..."
  brew tap hashicorp/tap
  brew install dialog git || { log "Error installing common CLI tools."; exit 1; }
}

install_dev_apps () {
  check_brew_installed
  brew_dev_apps=$(dialog --title "Choose non GUI apps you'd like to install" \
   --checklist "Use SPACE to select/deselect options. Confirm your choice by clicking ENTER." 20 80 6 \
  "awscli" "AWS CLI" OFF \
  "azure-cli" "Azure CLI" OFF \
  "granted" "Cloud role access manager" OFF \
  "aws-vpn-client" "AWS VPN Client" OFF \
  "kubernetes-cli" "Kubernetes CLI" OFF \
  "helm" "Helm" OFF \
  "k9s" "k9s" OFF \
  "minicube" "Minicube" OFF \
  "skaffold" "Skaffold" OFF \
  "argocd" "ArgoCD" OFF \
  "terraform" "Terraform" OFF \
  "tfenv" "Terraform version manager" OFF \
  "tflint" "Terraform linter" OFF \
  "ansible" "Ansible" OFF \
  "ansible-lint" "Linter for Ansible" OFF \
  "act" "Run GitHub Actions locally" OFF \
  "glab" "GitLab CLI tool" OFF \
  "nvm" "Node Version Manager" OFF \
  "pyenv" "Python version manager" OFF \
  "pyenv-virtualenv" "Pyenv plugin for virtualenv" OFF \
  "pipx" "pipx" OFF \
  "neovim" "Vim-based text editor" OFF \
  "fzf" "Command-line fuzzy finder" OFF \
  "htop" "htop" OFF \
  "jq" "JSON processor" OFF \
  "yq" "YAML processor" OFF \
  "tmux" "tmux" OFF \
  "tree" "tree" OFF \
  "watch" "watch" OFF \
  "wget" "wget" OFF \
  "thefuck" "Command correction tool" OFF \
  "tldr" "Simplified command documentation" OFF \
  "ctop" "Container metrics viewer" OFF \
  "kcat" "Kafka CLI tool" OFF \
  "wakeonlan" "Wake-on-LAN" OFF \
  "stats" "System resource monitor" OFF \
  3>&1 1>&2 2>&3)
  if [[ "$brew_dev_apps" ]]; then
    log "Installing additional packages: $brew_dev_apps"
    for app in $brew_dev_apps; do
      log "Installing $app..."
      brew install $app
    done
  fi
}

install_cask_apps () {
  check_brew_installed
  brew_cask_apps=$(dialog --title "Choose GUI apps you'd like to install" \
  --checklist "Use SPACE to select/deselect options. Confirm your choice by clicking ENTER." 20 80 6 \
    "visual-studio-code" "VSCode" OFF \
    "sublime-text" "Sublime" OFF \
    "pycharm" "Python IDE" OFF \
    "pycharm-ce" "Python IDE (Community Edition)" OFF \
    "dbeaver-community" "Database tool" OFF \
    "postman" "Postman" OFF \
    "docker" "Docker" OFF \
    "orbStack" "orbStack" OFF \
    "lens" "Kubernetes IDE" OFF \
    "fork" "Git client" OFF \
    "sourcetree" "Git client" OFF \
    "iterm2" "Terminal" OFF \
    "warp" "Terminal" OFF \
    "rectangle-pro" "Window manager" OFF \
    "hiddenbar" "Menu bar manager" OFF \
    "karabiner-elements" "Keyboard customizer" OFF \
    "lunar" "Monitor brightness control" OFF \
    "raycast" "Productivity launcher" OFF \
    "stretchly" "Break reminder" OFF \
    "slack" "Team communication" OFF \
    "discord" "Voice and text chat" OFF \
    "spotify" "Music streaming" OFF \
    "calibre" "E-book manager" OFF \
    "aws-vpn-client" "AWS VPN Client" OFF \
    "garmin-express" "Garmin device manager" OFF \
    "obsidian" "Knowledge base" OFF \
    "double-commander" "File manager" OFF \
    3>&1 1>&2 2>&3)

  if [[ "$brew_cask_apps" ]]; then
    log "Installing GUI packages: $brew_cask_apps"

    for app in $(echo "$brew_cask_apps" | tr -d '"'); do
      log "Installing $app..."
      if [[ "$app" == "stretchly" ]]; then
        brew update && brew install --cask --no-quarantine stretchly
      else
        brew install --cask "$app"
      fi
    done
  else
    log "No apps selected for installation."
  fi
}

install_zsh_plugins () {
  check_brew_installed
  zsh_plugins=$(dialog --title "Choose iTerm2 plugins you'd like to install" \
   --checklist "Use SPACE to select/deselect options. Confirm your choice by clicking ENTER." 20 60 4 \
  "zsh-autosuggestions" "zsh-autosuggestions" OFF \
  "zsh-syntax-highlighting" "zsh-syntax-highlighting" OFF \
  3>&1 1>&2 2>&3)

  if [[ "$zsh_plugins" ]]; then
    log "Installing iTerm plugins: $zsh_plugins"
    for app in $zsh_plugins; do
      log "Installing $app..."
      brew install $app

      case $app in
        "zsh-syntax-highlighting")
          printf "\nsource $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> ~/.zshrc
          log "Sourced zsh-syntax-highlighting"
          ;;
        "zsh-autosuggestions")
          printf "\nsource $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh" >>~/.zshrc
          log "Sourced zsh-autosuggestions"
          ;;
      esac
    done
  fi
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
  echo "4) Install common tools"
  echo "5) Install development CLI apps"
  echo "6) Install GUI apps"
  echo "7) Install Zsh plugins"
  echo "8) Remap keyboard keys"  
  echo "9) Setup git identities"  
  echo "0) Exit"
  read -p "Enter your choice [0-9]: " choice

  case "$choice" in
    1) install_brew ;;
    2) install_ohmyzsh ;;
    3) install_rosetta ;;
    4) install_common_tools ;;
    5) install_dev_apps ;;
    6) install_cask_apps ;;
    7) install_zsh_plugins ;;
    8) remap_keyboard ;;
    9) setup_git_identities ;;
    0) log "Exiting..."; break ;;
    *) log "Invalid choice! Please select a valid option." ;;
  esac
done

