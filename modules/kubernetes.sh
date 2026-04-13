#!/bin/bash

install_krew() {
    if [[ "$(uname)" != "Darwin" ]]; then
        log_error "This function only supports macOS."
        return 1
    fi

    log_info "Checking krew installation status..."

    if command -v kubectl-krew >/dev/null 2>&1 || kubectl krew version >/dev/null 2>&1; then
        log_info "krew is already installed."
        return 0
    fi

    if ! require_tool git; then
        log_error "git is required to install krew. Please install git first."
        return 1
    fi

    if ! require_tool curl; then
        log_error "curl is required to install krew."
        return 1
    fi

    log_info "Installing krew..."

    (
        set -x; cd "$(mktemp -d)" &&
        OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
        ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
        KREW="krew-${OS}_${ARCH}" &&
        curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
        tar zxvf "${KREW}.tar.gz" &&
        ./"${KREW}" install krew
    )

    if [ $? -ne 0 ]; then
        log_error "krew installation failed."
        return 1
    fi

    local rc_file="$HOME/.zshrc"
    local krew_path='export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"'

    if [[ -f "$rc_file" ]]; then
        if ! grep -q '\.krew/bin' "$rc_file"; then
            echo "" >> "$rc_file"
            echo "# krew" >> "$rc_file"
            echo "$krew_path" >> "$rc_file"
            log_info "Added krew to PATH in .zshrc"
        else
            log_info "krew PATH already configured in .zshrc"
        fi
    else
        log_warn ".zshrc not found at $rc_file"
    fi

    export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

    if kubectl krew version >/dev/null 2>&1; then
        log_info "krew installation completed successfully."
    else
        log_warn "krew installed but verification failed. Restart your shell and run 'kubectl krew' to verify."
    fi
}

install_krew_plugin() {
    local plugin="$1"

    if ! kubectl krew version >/dev/null 2>&1; then
        log_error "krew is not installed. Please install krew first."
        return 1
    fi

    if kubectl krew list | grep -q "^${plugin} "; then
        log_info "$plugin is already installed via krew"
        return 0
    fi

    log_info "Installing krew plugin: $plugin..."
    if kubectl krew install "$plugin"; then
        log_info "✓ $plugin installed successfully via krew"
        return 0
    else
        log_error "✗ Failed to install $plugin via krew"
        return 1
    fi
}

install_krew_plugins() {
    if [[ "$(uname)" != "Darwin" ]]; then
        log_error "This function only supports macOS."
        return 1
    fi

    if ! kubectl krew version >/dev/null 2>&1; then
        log_error "krew is not installed. Please install krew first."
        return 1
    fi

    select_packages_from_catalog "krew-plugins" "$SCRIPT_DIR/catalog.yaml"
}

export -f install_krew install_krew_plugin install_krew_plugins
