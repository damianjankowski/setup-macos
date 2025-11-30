#!/bin/bash

ensure_pipx() {
    if ! require_tool pipx; then
        log_info "Installing pipx..."
        brew install pipx
        pipx ensurepath
        
        # Reload path for current session
        export PATH="$PATH:$HOME/.local/bin"
    fi
}

install_pipx_package() {
    local package="$1"
    
    ensure_pipx
    
    if pipx list --short | grep -q "^$package "; then
        log_info "$package is already installed via pipx"
        return 0
    fi
    
    log_info "Installing $package via pipx..."
    if pipx install "$package"; then
        log_info "$package installed successfully via pipx"
        return 0
    else
        log_error "Failed to install $package via pipx"
        return 1
    fi
}

export -f ensure_pipx install_pipx_package
