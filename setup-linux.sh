#!/usr/bin/env bash
# ====================================================================
# setup-linux.sh - Ubuntu/Debian specific setup
# ====================================================================

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source utility functions
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/scripts/utils.sh"

# ---------------------------------------------------------------------
# Ubuntu/Debian-specific Setup Functions
# ---------------------------------------------------------------------

# Setup environment
setup_env() {
    info "Setting up development environment"
    
    # Run the environment setup script
    if ! bash "${SCRIPT_DIR}/scripts/setup_env.sh"; then
        error "Failed to set up development environment"
        return 1
    fi
    
    info "Development environment setup completed successfully"
    return 0
}

# Setup shell
setup_shell() {
    info "Setting up ZSH shell"
    
    # Run the shell setup script
    if ! bash "${SCRIPT_DIR}/scripts/setup_shell.sh"; then
        error "Failed to set up ZSH shell"
        return 1
    fi
    
    info "ZSH shell setup completed successfully"
    return 0
}

# Install kitty terminal
install_kitty() {
    info "Installing kitty terminal"
    
    if has_command kitty; then
        info "kitty is already installed"
        return 0
    fi
    
    # Install kitty via installer script
    info "Installing kitty via installer script"
    
    if has_command curl; then
        if ! run_cmd curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin installer=nightly; then
            error "Failed to install kitty via curl"
            return 1
        fi
    elif has_command wget; then
        if ! run_cmd wget -O- https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin installer=nightly; then
            error "Failed to install kitty via wget"
            return 1
        fi
    else
        error "Neither curl nor wget is available to download kitty installer"
        return 1
    fi
    
    # Kill any running kitty instances
    if pgrep kitty >/dev/null; then
        info "Terminating running kitty instances"
        pkill kitty || warning "Failed to terminate kitty instances"
    fi
    
    # Create symlinks
    info "Creating kitty symlinks"
    
    # Create local bin directory if it doesn't exist
    make_dir "${HOME}/.local/bin"
    
    # Create symlinks for kitty and kitten
    if ! create_symlink "${HOME}/.local/kitty.app/bin/kitty" "${HOME}/.local/bin/kitty"; then
        warning "Failed to create kitty symlink"
    fi
    
    if ! create_symlink "${HOME}/.local/kitty.app/bin/kitten" "${HOME}/.local/bin/kitten"; then
        warning "Failed to create kitten symlink"
    fi
    
    # Install desktop files
    info "Installing kitty desktop files"
    
    make_dir "${HOME}/.local/share/applications"
    
    if ! create_symlink "${HOME}/.local/kitty.app/share/applications/kitty.desktop" "${HOME}/.local/share/applications/kitty.desktop"; then
        warning "Failed to create kitty.desktop symlink"
    fi
    
    if ! create_symlink "${HOME}/.local/kitty.app/share/applications/kitty-open.desktop" "${HOME}/.local/share/applications/kitty-open.desktop"; then
        warning "Failed to create kitty-open.desktop symlink"
    fi
    
    # Update desktop file paths
    info "Updating desktop file paths"
    
    local icon_path
    icon_path=$(readlink -f "${HOME}")/.local/kitty.app/share/icons/hicolor/256x256/apps/kitty.png
    local bin_path
    bin_path=$(readlink -f "${HOME}")/.local/kitty.app/bin/kitty
    
    if ! run_cmd sed -i "s|Icon=kitty|Icon=${icon_path}|g" "${HOME}/.local/share/applications/kitty"*.desktop; then
        warning "Failed to update kitty icon path"
    fi
    
    if ! run_cmd sed -i "s|Exec=kitty|Exec=${bin_path}|g" "${HOME}/.local/share/applications/kitty"*.desktop; then
        warning "Failed to update kitty executable path"
    fi
    
    # Make kitty the default terminal
    info "Setting kitty as default terminal"
    
    if ! run_cmd mkdir -p "${HOME}/.config"; then
        warning "Failed to create config directory"
    fi
    
    if ! echo 'kitty.desktop' > "${HOME}/.config/xdg-terminals.list"; then
        warning "Failed to set kitty as default terminal"
    fi
    
    # Verify installation
    if ! has_command kitty; then
        warning "kitty installation verification failed"
        
        # Check if it's installed but not in PATH
        if [[ -f "${HOME}/.local/kitty.app/bin/kitty" ]]; then
            warning "kitty is installed but not in PATH"
            return 0
        else
            error "kitty installation failed"
            return 1
        fi
    fi
    
    info "kitty terminal setup completed successfully"
    return 0
}

# Install Vim
install_vim() {
    info "Installing Vim"
    
    if has_command vim; then
        info "Vim is already installed"
        return 0
    fi
    
    # Install vim via apt
    if ! run_with_sudo apt-get update -y; then
        error "Failed to update package lists"
        return 1
    fi
    
    if ! run_with_sudo apt-get install -y vim; then
        error "Failed to install vim"
        return 1
    fi
    
    # Verify installation
    if ! has_command vim; then
        error "Vim installation verification failed"
        return 1
    fi
    
    info "Vim installed successfully"
    return 0
}

# Install Neovim
install_neovim() {
    info "Installing Neovim"
    
    if has_command nvim; then
        info "Neovim is already installed"
        return 0
    fi
    
    # Install software-properties-common if needed for add-apt-repository
    if ! has_command add-apt-repository; then
        info "Installing software-properties-common"
        
        if ! run_with_sudo apt-get update -y; then
            error "Failed to update package lists"
            return 1
        fi
        
        if ! run_with_sudo apt-get install -y software-properties-common; then
            error "Failed to install software-properties-common"
            return 1
        fi
    fi
    
    # Add Neovim repository
    info "Adding Neovim repository"
    
    if ! run_with_sudo add-apt-repository -y ppa:neovim-ppa/stable; then
        error "Failed to add Neovim repository"
        return 1
    fi
    
    # Update package lists
    if ! run_with_sudo apt-get update -y; then
        error "Failed to update package lists"
        return 1
    fi
    
    # Install Neovim
    if ! run_with_sudo apt-get install -y neovim; then
        error "Failed to install Neovim"
        return 1
    fi
    
    # Verify installation
    if ! has_command nvim; then
        error "Neovim installation verification failed"
        return 1
    fi
    
    info "Neovim installed successfully"
    return 0
}

# Install Node.js
install_nodejs() {
    info "Installing Node.js"
    
    # Use the setup_nodejs function from setup_env.sh
    if ! bash "${SCRIPT_DIR}/scripts/setup_env.sh" setup_nodejs; then
        error "Failed to install Node.js using nvm"
        return 1
    fi
    
    info "Node.js installed successfully via nvm"
    return 0
}

# Main Ubuntu/Debian setup function
setup_ubuntu() {
    info "Setting up Ubuntu/Debian environment"
    local errors=0
    
    # Step 1: Set up development environment
    if ! setup_env; then
        error "Failed to set up development environment"
        ((errors++))
    fi
    
    # Step 2: Install kitty terminal
    if ! install_kitty; then
        error "Failed to install kitty terminal"
        ((errors++))
    fi
    
    # Step 3: Install Vim
    if ! install_vim; then
        error "Failed to install Vim"
        ((errors++))
    fi
    
    # Step 4: Install Neovim
    if ! install_neovim; then
        error "Failed to install Neovim"
        ((errors++))
    fi
    
    # Step 5: Install Node.js
    if ! install_nodejs; then
        error "Failed to install Node.js"
        ((errors++))
    fi
    
    # Step 6: Set up ZSH shell (should be last because it might change the shell)
    if ! setup_shell; then
        error "Failed to set up ZSH shell"
        ((errors++))
    fi
    
    if [[ ${errors} -gt 0 ]]; then
        warning "Ubuntu/Debian setup completed with ${errors} errors"
        return 1
    fi
    
    info "Ubuntu/Debian setup completed successfully"
    return 0
}

# ---------------------------------------------------------------------
# Main Script Logic
# ---------------------------------------------------------------------

# Set script name for logging
SCRIPT_NAME=$(basename "${0}")

# Initialize
info "Starting Ubuntu/Debian setup"
info "System: $(uname -a)"
info "User: $(whoami)"

# Run setup
setup_ubuntu
exit_code=$?

# Final status
if [[ ${exit_code} -ne 0 ]]; then
    warning "Ubuntu/Debian setup completed with errors"
    exit ${exit_code}
else
    info "Ubuntu/Debian setup completed successfully"
    exit 0
fi
