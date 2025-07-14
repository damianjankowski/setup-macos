# macOS Setup

Automated macOS development environment setup script with Homebrew, packages, and system configuration.

## Features

- Homebrew installation and management
- Package installation (CLI tools and GUI apps)
- Oh My Zsh setup
- Git configuration with work/personal identities
- Catppuccin themes for terminal apps
- System settings configuration
- Configuration backup/export

## Requirements

- macOS 10.15+
- Internet connection

## Installation

### With git
```bash
git clone https://github.com/damianjankowski/setup-macos.git
cd setup-macos
./setup.sh
```

### Without git
```bash
curl -L -o setup-macos.zip https://github.com/damianjankowski/setup-macos/archive/main.zip
unzip setup-macos.zip
cd setup-macos-main
./setup.sh
```

## Usage

```bash
./setup.sh           # Interactive menu
./setup.sh homebrew  # Install Homebrew only
./setup.sh packages  # Package management
./setup.sh all       # Install essentials
```

## Configuration

Create a `.env` file for Git multi-identity setup:
```bash
PERSONAL_NAME="Your Name"
PERSONAL_EMAIL="personal@example.com"
WORK_NAME="Your Name"
WORK_EMAIL="work@company.com"
```

- Personal repos → `~/src/` (uses personal identity)
- Work repos → `~/repo/` (uses work identity)

## Package Categories

- **Essentials**: git, curl, wget, jq, tree
- **Development**: VS Code, neovim, Docker, Postman
- **Cloud**: AWS CLI, kubectl, Terraform, Helm
- **Terminal**: iTerm2, Warp, tmux, fzf, bat
- **System**: Rectangle, Stats, Raycast

## License

MIT
