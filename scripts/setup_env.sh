#!/usr/bin/env bash
# ====================================================================
# setup_env.sh - Environment and dependency setup
# ====================================================================

# Source utility functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/utils.sh"

# Base packages lists
readonly DEBIAN_BASE_PACKAGES=(
    autoconf
    bc
    bison
    build-essential
    bzip2
    clang
    cmake
    curl
    dwarves
    flex
    fzf
    g++-multilib
    gcc-multilib
    gnupg
    lib32ncurses-dev
    libelf-dev
    libncurses5-dev
    libssl-dev
    libxml2-utils
    make
    meson
    p7zip-full
    pkg-config
    python-is-python3
    python3
    rsync
    tmux
    unzip
    wget
    xclip
    xsel
    xsltproc
    zip
    zlib1g-dev
)

readonly ARCH_BASE_PACKAGES=(
    autoconf
    base-devel
    bc
    bison
    bzip2
    clang
    cmake
    curl
    flex
    fzf
    git
    gnupg
    make
    meson
    ncurses
    openssl
    p7zip
    python
    rsync
    tmux
    unzip
    wget
    xclip
    xsel
    xsltproc
    zip
    zlib
)

# ---------------------------------------------------------------------
# Setup Functions
# ---------------------------------------------------------------------

# Install base development tools
setup_base_dev_tools() {
    local distro
    distro=$(detect_distro)
    local errors=0
    
    info "Setting up base development tools for ${distro}"
    
    case "${distro}" in
        debian|ubuntu)
            # Update package lists
            if ! run_with_sudo apt-get update -y; then
                error "Failed to update package lists"
                ((errors++))
            fi
            
            # Install essential packages
            for package in "${DEBIAN_BASE_PACKAGES[@]}"; do
                if ! is_package_installed "${package}"; then
                    info "Installing ${package}"
                    
                    if ! run_with_sudo apt-get install -y "${package}"; then
                        error "Failed to install ${package}"
                        ((errors++))
                    fi
                else
                    debug "${package} is already installed"
                fi
            done
            ;;
            
        arch)
            # Update package database
            if ! run_with_sudo pacman -Sy; then
                error "Failed to update package database"
                ((errors++))
            fi
            
            # Install essential packages
            for package in "${ARCH_BASE_PACKAGES[@]}"; do
                if ! is_package_installed "${package}"; then
                    info "Installing ${package}"
                    
                    if ! run_with_sudo pacman -S --noconfirm "${package}"; then
                        error "Failed to install ${package}"
                        ((errors++))
                    fi
                else
                    debug "${package} is already installed"
                fi
            done
            ;;
            
        *)
            error "Unsupported distribution: ${distro}"
            return 1
            ;;
    esac
    
    if [[ ${errors} -gt 0 ]]; then
        warning "Completed environment setup with ${errors} errors"
        return 1
    fi
    
    info "Base development tools setup completed successfully"
    return 0
}

# Setup timezone
setup_timezone() {
    local timezone="${1:-Asia/Kolkata}"
    
    info "Setting timezone to ${timezone}"
    
    if [[ -f /usr/share/zoneinfo/${timezone} ]]; then
        if has_command timedatectl && has_systemd; then
            # Use systemd method if available
            if ! run_with_sudo timedatectl set-timezone "${timezone}"; then
                warning "Failed to set timezone using timedatectl, falling back to alternative method"
                if ! run_with_sudo ln -sf "/usr/share/zoneinfo/${timezone}" /etc/localtime; then
                    error "Failed to set timezone"
                    return 1
                fi
            fi
        else
            # Fallback method
            if ! run_with_sudo ln -sf "/usr/share/zoneinfo/${timezone}" /etc/localtime; then
                error "Failed to set timezone"
                return 1
            fi
        fi
        
        # Set environment variable
        export TZ="${timezone}"
        
        info "Timezone set to ${timezone}"
        return 0
    else
        error "Timezone data not found: ${timezone}"
        return 1
    fi
}

# Setup GNOME settings if applicable
setup_gnome_settings() {
    if ! has_command gsettings; then
        debug "gsettings not available, skipping GNOME configuration"
        return 0
    fi
    
    info "Configuring GNOME settings"
    
    # Font settings
    if run_cmd gsettings set org.gnome.desktop.interface font-name "JetBrainsMono Nerd Font 12"; then
        debug "Set interface font"
    else
        warning "Failed to set interface font"
    fi
    
    if run_cmd gsettings set org.gnome.desktop.interface monospace-font-name "FiraCode Nerd Font 10"; then
        debug "Set monospace font"
    else
        warning "Failed to set monospace font"
    fi
    
    if run_cmd gsettings set org.gnome.desktop.interface document-font-name "FiraCode Nerd Font 12"; then
        debug "Set document font"
    else
        warning "Failed to set document font"
    fi
    
    # Icon theme
    if run_cmd gsettings set org.gnome.desktop.interface icon-theme "Gruvbox Plus Dark"; then
        debug "Set icon theme"
    else
        warning "Failed to set icon theme"
    fi
    
    info "GNOME settings configured"
    return 0
}

# Setup git configuration
setup_git() {
    info "Setting up git configuration"
    
    local dotfiles_dir
    dotfiles_dir="$(cd "${SCRIPT_DIR}/.." && pwd)"
    
    # Copy gitconfig
    if [[ -f "${dotfiles_dir}/.gitconfig" ]]; then
        if ! create_symlink "${dotfiles_dir}/.gitconfig" "${HOME}/.gitconfig"; then
            error "Failed to set up gitconfig"
            return 1
        fi
    else
        error "gitconfig file not found at ${dotfiles_dir}/.gitconfig"
        return 1
    fi
    
    # Setup githooks directory
    make_dir "${HOME}/.git/hooks"
    
    # Configure global hooks path
    if ! run_cmd git config --global core.hooksPath "${HOME}/.git/hooks"; then
        error "Failed to configure git hooks path"
        return 1
    fi
    
    # Download commit-msg hook
    local hook_url="https://gist.githubusercontent.com/UtsavBalar1231/c48cb6993ff45b077d41c13622fc27ba/raw/66f7da7f128a9511df81d624f23f87fc294b59b6/commit-msg"
    local hook_file="${HOME}/.git/hooks/commit-msg"
    
    if has_command curl; then
        if ! run_cmd curl -sLo "${hook_file}" "${hook_url}"; then
            error "Failed to download commit-msg hook"
            return 1
        fi
    elif has_command wget; then
        if ! run_cmd wget -qO "${hook_file}" "${hook_url}"; then
            error "Failed to download commit-msg hook"
            return 1
        fi
    else
        error "Neither curl nor wget is available to download commit-msg hook"
        return 1
    fi
    
    # Make hook executable
    if ! run_cmd chmod u+x "${hook_file}"; then
        error "Failed to make commit-msg hook executable"
        return 1
    fi
    
    info "Git configuration completed successfully"
    return 0
}

# Setup Rust environment
setup_rust() {
    info "Setting up Rust environment"
    
    # Check if rust is already installed
    if has_command rustc && has_command cargo; then
        info "Rust is already installed"
        return 0
    fi
    
    local distro
    distro=$(detect_distro)
    
    case "${distro}" in
        arch)
            info "Installing rustup via pacman"
            if ! run_with_sudo pacman -S --noconfirm rustup; then
                error "Failed to install rustup"
                return 1
            fi
            
            info "Setting up stable toolchain"
            if ! run_cmd rustup toolchain install stable --profile minimal; then
                error "Failed to install stable toolchain"
                return 1
            fi
            ;;
            
        *)
            info "Installing rustup via rustup.rs script"
            
            if has_command curl; then
                if ! run_cmd curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable; then
                    error "Failed to install rustup via curl"
                    return 1
                fi
            elif has_command wget; then
                if ! run_cmd wget -qO- https://sh.rustup.rs | sh -s -- -y --default-toolchain stable; then
                    error "Failed to install rustup via wget"
                    return 1
                fi
            else
                error "Neither curl nor wget is available to download rustup"
                return 1
            fi
            
            # Source environment
            if [[ -f "${HOME}/.cargo/env" ]]; then
                # shellcheck disable=SC1091
                source "${HOME}/.cargo/env"
            else
                error "Failed to find cargo environment file"
                return 1
            fi
            ;;
    esac
    
    # Verify installation
    if ! has_command rustc || ! has_command cargo; then
        error "Rust installation verification failed"
        return 1
    fi
    
    info "Rust environment setup completed successfully"
    return 0
}

# Setup common Rust utilities
setup_rust_utilities() {
    info "Setting up common Rust utilities"
    
    # Ensure Rust is installed
    if ! has_command cargo; then
        warning "Cargo not found, attempting to set up Rust first"
        if ! setup_rust; then
            error "Failed to set up Rust, cannot continue with Rust utilities"
            return 1
        fi
        
        # Source environment if needed
        if [[ -f "${HOME}/.cargo/env" ]]; then
            # shellcheck disable=SC1091
            source "${HOME}/.cargo/env"
        fi
    fi
    
    # List of utilities to install
    local utilities=(
        "eza"          # Modern ls replacement
        "bat"          # Cat with syntax highlighting
        "fd-find"      # Modern find replacement
        "ripgrep"      # Modern grep replacement
        "cargo-update" # Update cargo packages
        "git-delta"    # Better git diff
        "zoxide"       # Smarter cd
        "tree-sitter-cli" # Tree-sitter for nvim
    )
    
    local errors=0
    
    for util in "${utilities[@]}"; do
        local cmd_name
        case "${util}" in
            "fd-find") cmd_name="fd" ;;
            "git-delta") cmd_name="delta" ;;
            "cargo-update") cmd_name="cargo-install-update" ;;
            *) cmd_name="${util}" ;;
        esac
        
        if ! has_command "${cmd_name}"; then
            info "Installing ${util}"
            if ! run_cmd cargo install "${util}"; then
                error "Failed to install ${util}"
                ((errors++))
            fi
        else
            debug "${util} is already installed"
        fi
    done
    
    if [[ ${errors} -gt 0 ]]; then
        warning "Completed Rust utilities setup with ${errors} errors"
        return 1
    fi
    
    info "Rust utilities setup completed successfully"
    return 0
}

# Setup diff-so-fancy
setup_diff_so_fancy() {
    info "Setting up diff-so-fancy"
    
    if has_command diff-so-fancy; then
        info "diff-so-fancy is already installed"
        return 0
    fi
    
    # Get latest version
    local version
    version=$(get_github_release "so-fancy/diff-so-fancy") || {
        error "Failed to get latest diff-so-fancy version"
        return 1
    }
    
    info "Installing diff-so-fancy version ${version}"
    
    local temp_file
    temp_file=$(mktemp)
    
    # Download binary
    if has_command curl; then
        if ! run_cmd curl -sLo "${temp_file}" "https://github.com/so-fancy/diff-so-fancy/releases/download/${version}/diff-so-fancy"; then
            error "Failed to download diff-so-fancy"
            rm -f "${temp_file}"
            return 1
        fi
    elif has_command wget; then
        if ! run_cmd wget -qO "${temp_file}" "https://github.com/so-fancy/diff-so-fancy/releases/download/${version}/diff-so-fancy"; then
            error "Failed to download diff-so-fancy"
            rm -f "${temp_file}"
            return 1
        fi
    else
        error "Neither curl nor wget is available to download diff-so-fancy"
        rm -f "${temp_file}"
        return 1
    fi
    
    # Make executable
    if ! run_cmd chmod a+x "${temp_file}"; then
        error "Failed to make diff-so-fancy executable"
        rm -f "${temp_file}"
        return 1
    fi
    
    # Install to system
    if ! run_with_sudo mv "${temp_file}" /usr/local/bin/diff-so-fancy; then
        error "Failed to install diff-so-fancy"
        rm -f "${temp_file}"
        return 1
    fi
    
    # Verify installation
    if ! has_command diff-so-fancy; then
        error "diff-so-fancy installation verification failed"
        return 1
    fi
    
    info "diff-so-fancy setup completed successfully"
    return 0
}

# Setup btop
setup_btop() {
    info "Setting up btop"
    
    if has_command btop; then
        info "btop is already installed"
        return 0
    fi
    
    local distro
    distro=$(detect_distro)
    local arch
    arch=$(uname -m)
    
    case "${distro}" in
        arch)
            info "Installing btop via pacman"
            if ! run_with_sudo pacman -S --noconfirm btop; then
                error "Failed to install btop via pacman"
                return 1
            fi
            ;;
            
        ubuntu|debian)
            local ubuntu_version
            ubuntu_version=$(get_ubuntu_version)
            
            if [[ "${ubuntu_version}" -ge 23 ]]; then
                info "Installing btop via apt"
                if ! run_with_sudo apt-get install -y btop; then
                    error "Failed to install btop via apt"
                    return 1
                fi
            else
                info "Using prebuilt btop binary for Ubuntu ${ubuntu_version}"
                
                local dotfiles_dir
                dotfiles_dir="$(cd "${SCRIPT_DIR}/.." && pwd)"
                local prebuilt_dir="${dotfiles_dir}/prebuilts"
                local btop_binary
                
                case "${arch}" in
                    x86_64)
                        btop_binary="${prebuilt_dir}/btop-x86_64"
                        ;;
                    aarch64)
                        btop_binary="${prebuilt_dir}/btop-aarch64"
                        ;;
                    *)
                        error "Unsupported architecture for btop: ${arch}"
                        return 1
                        ;;
                esac
                
                if [[ ! -f "${btop_binary}" ]]; then
                    error "Prebuilt btop binary not found: ${btop_binary}"
                    return 1
                fi
                
                if ! run_with_sudo cp -f "${btop_binary}" /usr/local/bin/btop; then
                    error "Failed to install btop binary"
                    return 1
                fi
                
                if ! run_with_sudo chmod a+x /usr/local/bin/btop; then
                    error "Failed to make btop executable"
                    return 1
                fi
            fi
            ;;
            
        *)
            error "Unsupported distribution for btop installation: ${distro}"
            return 1
            ;;
    esac
    
    # Verify installation
    if ! has_command btop; then
        error "btop installation verification failed"
        return 1
    fi
    
    info "btop setup completed successfully"
    return 0
}

# Setup Node.js environment
setup_nodejs() {
    info "Setting up Node.js environment using nvm"
    
    # Check if nvm is already installed
    if [[ -d "${HOME}/.nvm" ]] && [[ -s "${HOME}/.nvm/nvm.sh" ]]; then
        info "nvm is already installed, sourcing it"
        # shellcheck disable=SC1091
        source "${HOME}/.nvm/nvm.sh"
    else
        info "Installing nvm"
        
        # Install nvm
        if has_command curl; then
            if ! run_cmd curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash; then
                error "Failed to install nvm via curl"
                return 1
            fi
        elif has_command wget; then
            if ! run_cmd wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash; then
                error "Failed to install nvm via wget"
                return 1
            fi
        else
            error "Neither curl nor wget is available to download nvm"
            return 1
        fi
        
        # Source nvm
        export NVM_DIR="$HOME/.nvm"
        # shellcheck disable=SC1091
        if [[ -s "$NVM_DIR/nvm.sh" ]]; then
            source "$NVM_DIR/nvm.sh"
        else
            error "Failed to source nvm.sh after installation"
            return 1
        fi
    fi
    
    # Verify nvm installation
    if ! command -v nvm >/dev/null 2>&1; then
        error "nvm installation verification failed"
        return 1
    fi
    
    # Install latest LTS version of Node.js
    info "Installing latest LTS version of Node.js"
    if ! nvm install --lts; then
        error "Failed to install LTS version of Node.js"
        return 1
    fi
    
    # Set the installed version as default
    if ! nvm alias default "lts/*"; then
        warning "Failed to set LTS Node.js as default, but installation succeeded"
    fi
    
    # Verify installation
    if ! command -v node >/dev/null 2>&1; then
        error "Node.js installation verification failed"
        return 1
    fi
    
    # Install essential global packages
    info "Installing essential npm global packages"
    local global_packages=(
        "npm"           # Latest npm
        "yarn"          # Yarn package manager
        "pnpm"          # pnpm package manager
        "typescript"    # TypeScript
        "ts-node"       # TypeScript execution
    )
    
    for pkg in "${global_packages[@]}"; do
        info "Installing ${pkg} globally"
        if ! npm install -g "${pkg}"; then
            warning "Failed to install ${pkg} globally, but continuing"
        fi
    done
    
    local node_version
    node_version=$(node --version)
    info "Node.js ${node_version} setup completed successfully"
    
    # Add nvm initialization to shell startup files if needed
    if ! grep -q "nvm.sh" "${HOME}/.bashrc" 2>/dev/null; then
        info "Adding nvm initialization to .bashrc"
        {
            echo "# NVM initialization"
            echo 'export NVM_DIR="$HOME/.nvm"'
            echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm'
            echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion'
        } >> "${HOME}/.bashrc"
    fi
    
    if [[ -f "${HOME}/.zshrc" ]] && ! grep -q "nvm.sh" "${HOME}/.zshrc" 2>/dev/null; then
        info "Adding nvm initialization to .zshrc"
        {
            echo "# NVM initialization"
            echo 'export NVM_DIR="$HOME/.nvm"'
            echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm'
            echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion'
        } >> "${HOME}/.zshrc"
    fi
    
    return 0
}

# Main setup function
setup_environment() {
    local errors=0
    
    # Set timezone
    if ! setup_timezone "Asia/Kolkata"; then
        error "Failed to set timezone"
        ((errors++))
    fi
    
    # Setup git
    if ! setup_git; then
        error "Failed to set up git"
        ((errors++))
    fi
    
    # Install base development tools
    if ! setup_base_dev_tools; then
        error "Failed to set up base development tools"
        ((errors++))
    fi
    
    # Setup Rust
    if ! setup_rust; then
        error "Failed to set up Rust"
        ((errors++))
    fi
    
    # Setup common Rust utilities
    if ! setup_rust_utilities; then
        error "Failed to set up Rust utilities"
        ((errors++))
    fi
    
    # Setup diff-so-fancy
    if ! setup_diff_so_fancy; then
        error "Failed to set up diff-so-fancy"
        ((errors++))
    fi
    
    # Setup btop
    if ! setup_btop; then
        error "Failed to set up btop"
        ((errors++))
    fi
    
    # Setup Node.js
    if ! setup_nodejs; then
        error "Failed to set up Node.js"
        ((errors++))
    fi
    
    # Setup GNOME settings if applicable
    setup_gnome_settings
    
    if [[ ${errors} -gt 0 ]]; then
        warning "Environment setup completed with ${errors} errors"
        return 1
    fi
    
    info "Environment setup completed successfully"
    return 0
}

# Run setup if the script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_environment "$@"
    exit $?
fi
