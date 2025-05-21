#!/bin/bash

# Brew categories for macOS setup
# This file contains categorized lists of brew packages

# Define categories
CATEGORIES=(
  "Cloud & Infrastructure"
  "Infrastructure as Code"
  "Development Tools"
  "Database Tools"
  "Container Tools"
  "Terminal & Shell"
  "System Utilities"
  "Communication & Productivity"
  "Zsh Plugins"
  "Common Tools"
)

# Define package lists for each category
CLOUD_TOOLS=(
  "awscli" "cli"
  "azure-cli" "cli"
  "granted" "cli"
  "kubernetes-cli" "cli"
  "helm" "cli"
  "k9s" "cli"
  "minicube" "cli"
  "skaffold" "cli"
  "argocd" "cli"
  "aws-vpn-client" "gui"
  "lens" "gui"
)

IAC_TOOLS=(
  "terraform" "cli"
  "tfenv" "cli"
  "tflint" "cli"
  "ansible" "cli"
  "ansible-lint" "cli"
)

DEV_TOOLS=(
  "act" "cli"
  "glab" "cli"
  "nvm" "cli"
  "pyenv" "cli"
  "pyenv-virtualenv" "cli"
  "pipx" "cli"
  "neovim" "cli"
  "visual-studio-code" "gui"
  "sublime-text" "gui"
  "pycharm" "gui"
  "pycharm-ce" "gui"
  "postman" "gui"
  "fork" "gui"
  "sourcetree" "gui"
)

DB_TOOLS=(
  "dbeaver-community" "gui"
)

CONTAINER_TOOLS=(
  "ctop" "cli"
  "docker" "gui"
  "orbStack" "gui"
)

TERMINAL_TOOLS=(
  "fzf" "cli"
  "htop" "cli"
  "tmux" "cli"
  "thefuck" "cli"
  "tldr" "cli"
  "iterm2" "gui"
  "warp" "gui"
)

SYS_UTILS=(
  "jq" "cli"
  "yq" "cli"
  "tree" "cli"
  "watch" "cli"
  "wget" "cli"
  "kcat" "cli"
  "wakeonlan" "cli"
  "stats" "cli"
  "rectangle-pro" "gui"
  "hiddenbar" "gui"
  "karabiner-elements" "gui"
  "lunar" "gui"
  "betterdisplay" "gui"
  "raycast" "gui"
  "stretchly" "gui"
  "double-commander" "gui"
)

COMM_TOOLS=(
  "slack" "gui"
  "discord" "gui"
  "spotify" "gui"
  "calibre" "gui"
  "obsidian" "gui"
)

ZSH_PLUGINS=(
  "zsh-autosuggestions" "cli"
  "zsh-syntax-highlighting" "cli"
)

COMMON_TOOLS=(
  "git" "cli"
  "dialog" "cli"
)

# Define GUI applications
GUI_APPS=(
  "aws-vpn-client"
  "lens"
  "visual-studio-code"
  "sublime-text"
  "pycharm"
  "pycharm-ce"
  "postman"
  "fork"
  "sourcetree"
  "dbeaver-community"
  "docker"
  "orbStack"
  "iterm2"
  "warp"
  "rectangle-pro"
  "hiddenbar"
  "karabiner-elements"
  "lunar"
  "raycast"
  "stretchly"
  "double-commander"
  "slack"
  "discord"
  "spotify"
  "calibre"
  "obsidian"
)

CATEGORY_VARS=(
  CLOUD_TOOLS
  IAC_TOOLS
  DEV_TOOLS
  DB_TOOLS
  CONTAINER_TOOLS
  TERMINAL_TOOLS
  SYS_UTILS
  COMM_TOOLS
  ZSH_PLUGINS
  COMMON_TOOLS
)

# for_each_package() {
#   local array_name="$1"
#   local callback="$2"
#   local arr=()
#   eval "arr=(\"\${$array_name[@]}\")"
#   for ((i=0; i<${#arr[@]}; i+=2)); do
#     "$callback" "${arr[$i]}" "${arr[$i+1]}"
#   done
# }

category_label() {
  case "$1" in
    CLOUD_TOOLS) echo "Cloud & Infrastructure";;
    IAC_TOOLS) echo "IaC";;
    DEV_TOOLS) echo "Dev tools";;
    DB_TOOLS) echo "DB tools";;
    CONTAINER_TOOLS) echo "Container tools";;
    TERMINAL_TOOLS) echo "Terminal";;
    SYS_UTILS) echo "System Utilities";;
    COMM_TOOLS) echo "Communication & Productivity";;
    ZSH_PLUGINS) echo "Zsh Plugins";;
    COMMON_TOOLS) echo "Common tools";;
    *) echo "Unknown";;
  esac
}

get_all_packages() {
  local all_packages=()
  for category in "${CATEGORY_VARS[@]}"; do
    local arr=()
    eval "arr=(\"\${$category[@]}\")"
    for ((i=0; i<${#arr[@]}; i+=2)); do
      all_packages+=("${arr[$i]}")
    done
  done
  echo "${all_packages[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '
}

get_category_for_package() {
  local package="$1"
  for category in "${CATEGORY_VARS[@]}"; do
    local arr=()
    eval "arr=(\"\${$category[@]}\")"
    for ((i=0; i<${#arr[@]}; i+=2)); do
      if [[ "${arr[$i]}" == "$package" ]]; then
        category_label "$category"
        return
      fi
    done
  done
  echo "Unknown"
}

# is_gui_app() {
#   local package="$1"
#   for category in "${CATEGORY_VARS[@]}"; do
#     local arr=()
#     eval "arr=(\"\${$category[@]}\")"
#     for ((i=0; i<${#arr[@]}; i+=2)); do
#       if [[ "${arr[$i]}" == "$package" ]]; then
#         [[ "${arr[$i+1]}" == "gui" ]] && echo "true" || echo "false"
#         return
#       fi
#     done
#   done
#   echo "false"
# } 