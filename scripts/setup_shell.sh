#!/usr/bin/env bash
# ====================================================================
# setup_shell.sh - Shell configuration and ZSH setup
# ====================================================================

# Source utility functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/utils.sh"

# ---------------------------------------------------------------------
# ZSH Setup Functions
# ---------------------------------------------------------------------

# Install ZSH if not available
install_zsh() {
    info "Checking for ZSH installation"
    
    if has_command zsh; then
        info "ZSH is already installed"
        return 0
    fi
    
    local distro
    distro=$(detect_distro)
    
    case "${distro}" in
        arch)
            info "Installing ZSH via pacman"
            if ! run_with_sudo pacman -S --noconfirm zsh; then
                error "Failed to install ZSH via pacman"
                return 1
            fi
            ;;
            
        debian|ubuntu)
            info "Installing ZSH via apt"
            if ! run_with_sudo apt-get update -y; then
                error "Failed to update package lists"
                return 1
            fi
            
            if ! run_with_sudo apt-get install -y zsh; then
                error "Failed to install ZSH via apt"
                return 1
            fi
            ;;
            
        *)
            error "Unsupported distribution for ZSH installation: ${distro}"
            return 1
            ;;
    esac
    
    # Verify installation
    if ! has_command zsh; then
        error "ZSH installation verification failed"
        return 1
    fi
    
    info "ZSH installed successfully"
    return 0
}

# Build ZSH from source (for Ubuntu/Debian)
build_zsh_from_source() {
    info "Building ZSH from source"
    
    # Check if zsh is already installed with acceptable version
    if has_command zsh; then
        local zsh_version
        zsh_version=$(zsh --version | awk '{print $2}')
        if [[ $(echo "${zsh_version}" | awk -F. '{ print $1 * 100 + $2 }') -ge 505 ]]; then
            info "ZSH ${zsh_version} is already installed and meets version requirements"
            return 0
        else
            info "Installed ZSH version ${zsh_version} is outdated, building newer version"
        fi
    fi
    
    # Install build dependencies
    local build_deps=("git" "make" "gcc" "autoconf" "libncurses-dev" "yodl" "libcap-dev")
    for dep in "${build_deps[@]}"; do
        if ! is_package_installed "${dep}"; then
            info "Installing build dependency: ${dep}"
            if ! run_with_sudo apt-get install -y "${dep}"; then
                warning "Failed to install dependency: ${dep}, but continuing anyway"
            fi
        fi
    done
    
    # Create temporary directory
    local temp_dir
    temp_dir=$(mktemp -d)
    
    # Clone repository
    info "Cloning ZSH repository"
    if ! run_cmd git clone --depth=1 https://github.com/zsh-users/zsh "${temp_dir}"; then
        error "Failed to clone ZSH repository"
        rm -rf "${temp_dir}"
        return 1
    fi
    
    # Build and install
    (
        cd "${temp_dir}" || return 1
        
        info "Running preconfig"
        if ! run_cmd ./Util/preconfig; then
            error "Failed to run preconfig"
            return 1
        fi
        
        info "Configuring ZSH build"
        if ! run_cmd ./configure --enable-cflags=-O3; then
            error "Failed to configure ZSH build"
            return 1
        fi
        
        local cpu_count
        cpu_count=$(nproc)
        info "Building ZSH with ${cpu_count} cores"
        if ! run_cmd make -j"${cpu_count}"; then
            error "Failed to build ZSH"
            return 1
        fi
        
        info "Installing ZSH (requires sudo)"
        if ! run_with_sudo make -j"${cpu_count}" install; then
            error "Failed to install ZSH"
            return 1
        fi
    ) || {
        error "Failed to build and install ZSH"
        rm -rf "${temp_dir}"
        return 1
    }
    
    rm -rf "${temp_dir}"
    
    # Verify installation
    if ! has_command zsh; then
        error "ZSH installation verification failed"
        return 1
    fi
    
    local new_version
    new_version=$(zsh --version | awk '{print $2}')
    info "ZSH ${new_version} built and installed successfully"
    return 0
}

# Set ZSH as default shell
set_zsh_default() {
    local user="${1:-$(whoami)}"
    local zsh_path
    
    info "Setting ZSH as default shell for user: ${user}"
    
    # Find zsh path
    zsh_path=$(command -v zsh)
    if [[ -z "${zsh_path}" ]]; then
        error "ZSH executable not found"
        return 1
    fi
    
    # Check if ZSH is already the default shell
    local current_shell
    current_shell=$(getent passwd "${user}" | cut -d: -f7)
    
    if [[ "${current_shell}" == "${zsh_path}" ]]; then
        info "ZSH is already the default shell for ${user}"
        return 0
    fi
    
    # Check if ZSH is in /etc/shells
    if ! grep -q "${zsh_path}" /etc/shells; then
        info "Adding ${zsh_path} to /etc/shells"
        if ! run_with_sudo sh -c "echo '${zsh_path}' >> /etc/shells"; then
            error "Failed to add ZSH to /etc/shells"
            return 1
        fi
    fi
    
    # Change shell for user
    info "Changing default shell to ZSH for ${user}"
    if [[ "${user}" == "$(whoami)" ]]; then
        if ! run_with_sudo chsh -s "${zsh_path}" "${user}"; then
            error "Failed to set ZSH as default shell for ${user}"
            return 1
        fi
    else
        if ! run_with_sudo chsh -s "${zsh_path}" "${user}"; then
            error "Failed to set ZSH as default shell for ${user}"
            return 1
        fi
    fi
    
    info "ZSH set as default shell for ${user}"
    return 0
}

# Setup custom ZSH plugins
setup_zsh_plugins() {
    info "Setting up ZSH plugins"
    
    local plugins_dir="${HOME}/.oh-my-zsh/custom/plugins"
    make_dir "${plugins_dir}"
    
    # List of plugins to install
    local plugins=(
        "zsh-users/zsh-autosuggestions"
        "zsh-users/zsh-syntax-highlighting"
        "zsh-users/zsh-completions"
        "zsh-users/zsh-history-substring-search"
        "Aloxaf/fzf-tab"
        "z-shell/F-Sy-H"
    )
    
    local errors=0
    
    for plugin in "${plugins[@]}"; do
        local repo_name="${plugin##*/}"
        local target_dir="${plugins_dir}/${repo_name}"
        
        if [[ -d "${target_dir}" ]]; then
            info "Plugin ${repo_name} is already installed, updating"
            (
                cd "${target_dir}" || return 1
                if ! run_cmd git pull --quiet; then
                    error "Failed to update plugin: ${repo_name}"
                    return 1
                fi
            ) || ((errors++))
        else
            info "Installing plugin: ${repo_name}"
            if ! run_cmd git clone --depth=1 "https://github.com/${plugin}.git" "${target_dir}"; then
                error "Failed to install plugin: ${repo_name}"
                ((errors++))
            fi
        fi
    done
    
    if [[ ${errors} -gt 0 ]]; then
        warning "Completed ZSH plugins setup with ${errors} errors"
        return 1
    fi
    
    info "ZSH plugins setup completed successfully"
    return 0
}

# Configure ZSH with custom settings
configure_zsh() {
    info "Configuring ZSH settings"
    
    local dotfiles_dir
    dotfiles_dir="$(cd "${SCRIPT_DIR}/.." && pwd)"
    local zsh_config_source
    local zshrc_config_source
    local zsh_config_target="${HOME}/.config/zsh"
    [[ ! -e ${zsh_config_target} ]] && mkdir -p ${zsh_config_target} 
    local zshrc_config_target="${HOME}/.zshrc"
    
    # Determine which zsh config to use
    zsh_config_source="${dotfiles_dir}/configs/zsh"
    zshrc_config_source="${dotfiles_dir}/configs/zshrc"
    
    # Copy zsh files
    if [[ -e "${zsh_config_source}" ]]; then
        info "Copying ZSH configuration from ${zsh_config_source}"

	cp -vr ${zsh_config_source}/* "${zsh_config_target}/"
    fi
        
    if [[ -e "${zshrc_config_source}" ]]; then
        info "Copying ZSHRC from ${zshrc_config_source}"

	cp -vaf "${zshrc_config_source}" "${zshrc_config_target}"
    fi
    
    info "ZSH configuration completed"
    return 0
}

# Install and configure nerd fonts
setup_nerd_fonts() {
    info "Setting up Nerd Fonts"
    
    # Check if fonts are already installed
    if [[ -d "${HOME}/.local/share/fonts/NerdFonts" ]]; then
        info "Nerd Fonts appear to be already installed"
        return 0
    fi
    
    # Install getnf tool
    if ! has_command getnf; then
        info "Installing getnf tool"
        
        if has_command curl; then
            if ! run_cmd curl -fsSL https://raw.githubusercontent.com/getnf/getnf/main/install.sh | bash -s -- --silent; then
                error "Failed to install getnf"
                return 1
            fi
        elif has_command wget; then
            if ! run_cmd wget -qO- https://raw.githubusercontent.com/getnf/getnf/main/install.sh | bash -s -- --silent; then
                error "Failed to install getnf"
                return 1
            fi
        else
            error "Neither curl nor wget is available to download getnf"
            return 1
        fi
    fi
    
    # Path to getnf executable
    local getnf_path="/usr/bin/getnf"
    
    # Verify getnf installation
    if [[ ! -f "${getnf_path}" ]]; then
	if [[ -f "${HOME}/.local/bin/getnf" ]]; then
		getnf_path="${HOME}/.local/bin/getnf"
	else
		error "getnf installation verification failed"
		return 1
	fi
    fi
    
    # Install fonts
    info "Installing Nerd Fonts"
    local fonts_to_install=("0xProto" "AdwaitaMono" "FiraCode" "IBMPlexMono" "IntelOneMono" "Iosevka" "JetBrainsMono" "NerdFontsSymbolsOnly")
    
    if ! run_cmd "${getnf_path}" -i "$(IFS=,; echo "${fonts_to_install[*]}")"; then
        error "Failed to install Nerd Fonts"
        return 1
    fi
    
    # Update font cache
    if has_command fc-cache; then
        info "Updating font cache"
        if ! run_cmd fc-cache -f; then
            warning "Failed to update font cache"
        fi
    fi
    
    info "Nerd Fonts setup completed successfully"
    return 0
}

# Main setup function
setup_shell() {
    local errors=0
    
    # Install ZSH
    if ! install_zsh; then
        error "Failed to install ZSH"
        ((errors++))
    fi
    
    # Build ZSH from source for Ubuntu/Debian
    if [[ $(detect_distro) == "ubuntu" || $(detect_distro) == "debian" ]]; then
        if ! build_zsh_from_source; then
            warning "Failed to build ZSH from source, using system ZSH"
        fi
    fi

    # Set ZSH as default shell
    if ! set_zsh_default "$(whoami)"; then
        error "Failed to set ZSH as default shell for current user"
        ((errors++))
    fi
    
    # Set ZSH as default shell for root
    if ! set_zsh_default "root"; then
        warning "Failed to set ZSH as default shell for root user"
    fi
    
    # Setup ZSH plugins
    if ! setup_zsh_plugins; then
        error "Failed to set up ZSH plugins"
        ((errors++))
    fi
    
    # Configure ZSH
    if ! configure_zsh; then
        error "Failed to configure ZSH"
        ((errors++))
    fi
    
    # Setup Nerd Fonts
    if ! setup_nerd_fonts; then
        warning "Failed to set up Nerd Fonts"
    fi
    
    if [[ ${errors} -gt 0 ]]; then
        warning "Shell setup completed with ${errors} errors"
        return 1
    fi
    
    info "Shell setup completed successfully"
    return 0
}

# Run setup if the script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_shell "$@"
    exit $?
fi
