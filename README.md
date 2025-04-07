# setup_macos

**setup_macos** is an interactive Bash script that automates the configuration of a development environment on macOS. It supports the installation of Homebrew, Oh My Zsh, Rosetta (for Apple Silicon), as well as various CLI tools and GUI applications via Homebrew.

## Features

- **Homebrew Installation** 
- **Oh My Zsh Installation** 
- **Rosetta Installation** 
- **CLI & GUI Tools Installation**
- **Zsh Plugins Setup** Adds useful plugins such as `zsh-autosuggestions` and `zsh-syntax-highlighting` to enhance your terminal experience.

## Requirements

- **Operating System:** macOS
- **Shell:** Bash
- **Homebrew:** The script installs Homebrew if it's not already installed.
- **Dialog:** Used for interactive selection of applications (installed automatically if missing).

## Installation

1. Version with `git` already installed:
   ```bash
   git clone https://github.com/yourusername/setup_macos.git
   cd setup_macos
   chmod +x setup_macos.sh 
   ./setup_macos.sh 
   
2. Without `git` installed:
   ```bash
   curl -L -o main.zip https://codeload.github.com/damianjankowski/setup-macos/zip/refs/heads/main
   unzip main.zip
   cd setup-macos-main
   chmod +x setup_macos.sh 
   ./setup_macos.sh 
