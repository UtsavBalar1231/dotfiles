#!/usr/bin/env bash
# ====================================================================
# setup_git.sh - Git configuration and setup
# ====================================================================

# Source utility functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/utils.sh"

# ---------------------------------------------------------------------
# Git Setup Functions
# ---------------------------------------------------------------------

# Install Git if not available
install_git() {
    if has_command git; then
        info "Git is already installed"
        return 0
    fi
    
    local distro
    distro=$(detect_distro)
    
    info "Installing Git for ${distro}"
    
    case "${distro}" in
        arch)
            if ! run_with_sudo pacman -S --noconfirm git; then
                error "Failed to install Git via pacman"
                return 1
            fi
            ;;
            
        debian|ubuntu)
            if ! run_with_sudo apt-get update -y; then
                error "Failed to update package lists"
                return 1
            fi
            
            if ! run_with_sudo apt-get install -y git; then
                error "Failed to install Git via apt"
                return 1
            fi
            ;;
            
        *)
            error "Unsupported distribution for Git installation: ${distro}"
            return 1
            ;;
    esac
    
    # Verify installation
    if ! has_command git; then
        error "Git installation verification failed"
        return 1
    fi
    
    local git_version
    git_version=$(git --version)
    info "Git installed successfully: ${git_version}"
    return 0
}

# Set up Git configuration
setup_git_config() {
    info "Setting up Git configuration"
    
    # Get dotfiles directory
    local dotfiles_dir
    dotfiles_dir="$(cd "${SCRIPT_DIR}/.." && pwd)"
    
    # Copy gitconfig
    if [[ -f "${dotfiles_dir}/.gitconfig" ]]; then
        info "Copying gitconfig file"
        
        if ! create_symlink "${dotfiles_dir}/.gitconfig" "${HOME}/.gitconfig"; then
            error "Failed to set up gitconfig"
            return 1
        fi
    else
        warning "gitconfig file not found at ${dotfiles_dir}/.gitconfig"
        
        # Set some basic git configuration if no config file exists
        info "Setting basic Git configuration"
        
        # Prompt for user information if not already set
        local git_name
        local git_email
        
        if ! git config --global user.name >/dev/null 2>&1; then
            if [[ "${VERBOSE}" == "true" ]]; then
                # Only prompt if in interactive mode
                echo -n "Enter your Git username: "
                read -r git_name
                
                if [[ -n "${git_name}" ]]; then
                    if ! run_cmd git config --global user.name "${git_name}"; then
                        warning "Failed to set Git username"
                    fi
                else
                    warning "No Git username provided, using default"
                    if ! run_cmd git config --global user.name "Dotfiles User"; then
                        warning "Failed to set default Git username"
                    fi
                fi
            else
                # Non-interactive mode, use default
                if ! run_cmd git config --global user.name "Dotfiles User"; then
                    warning "Failed to set default Git username"
                fi
            fi
        fi
        
        if ! git config --global user.email >/dev/null 2>&1; then
            if [[ "${VERBOSE}" == "true" ]]; then
                # Only prompt if in interactive mode
                echo -n "Enter your Git email: "
                read -r git_email
                
                if [[ -n "${git_email}" ]]; then
                    if ! run_cmd git config --global user.email "${git_email}"; then
                        warning "Failed to set Git email"
                    fi
                else
                    warning "No Git email provided, using default"
                    if ! run_cmd git config --global user.email "user@example.com"; then
                        warning "Failed to set default Git email"
                    fi
                fi
            else
                # Non-interactive mode, use default
                if ! run_cmd git config --global user.email "user@example.com"; then
                    warning "Failed to set default Git email"
                fi
            fi
        fi
        
        # Set some sensible defaults
        if ! run_cmd git config --global core.editor "vim"; then
            warning "Failed to set Git editor"
        fi
        
        if ! run_cmd git config --global init.defaultBranch "main"; then
            warning "Failed to set Git default branch"
        fi
        
        if ! run_cmd git config --global pull.rebase false; then
            warning "Failed to set Git pull mode"
        fi
    fi
    
    return 0
}

# Setup Git hooks
setup_git_hooks() {
    info "Setting up Git hooks"
    
    # Create hooks directory if it doesn't exist
    local hooks_dir="${HOME}/.git/hooks"
    
    if ! make_dir "${hooks_dir}"; then
        error "Failed to create Git hooks directory"
        return 1
    fi
    
    # Configure global hooks path
    if ! run_cmd git config --global core.hooksPath "${hooks_dir}"; then
        error "Failed to set global hooks path"
        return 1
    fi
    
    # Download commit-msg hook
    local hook_url="https://gist.githubusercontent.com/UtsavBalar1231/c48cb6993ff45b077d41c13622fc27ba/raw/66f7da7f128a9511df81d624f23f87fc294b59b6/commit-msg"
    local hook_file="${hooks_dir}/commit-msg"
    
    info "Downloading commit-msg hook"
    
    if has_command curl; then
        if ! run_cmd curl -sLo "${hook_file}" "${hook_url}"; then
            error "Failed to download commit-msg hook with curl"
            return 1
        fi
    elif has_command wget; then
        if ! run_cmd wget -qO "${hook_file}" "${hook_url}"; then
            error "Failed to download commit-msg hook with wget"
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
    
    info "Git hooks setup completed successfully"
    return 0
}

# Setup diff-so-fancy
setup_git_diff_so_fancy() {
    if has_command diff-so-fancy; then
        info "diff-so-fancy is already installed"
    else
        info "Installing diff-so-fancy"
        
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
    fi
    
    # Configure Git to use diff-so-fancy
    local git_diff_configs=(
        "core.pager=diff-so-fancy | less --tabs=4 -RFX"
        "interactive.diffFilter=diff-so-fancy --patch"
        "color.ui=true"
        "color.diff-highlight.oldNormal=red bold"
        "color.diff-highlight.oldHighlight=red bold 52"
        "color.diff-highlight.newNormal=green bold"
        "color.diff-highlight.newHighlight=green bold 22"
        "color.diff.meta=11"
        "color.diff.frag=magenta bold"
        "color.diff.func=146 bold"
        "color.diff.commit=yellow bold"
        "color.diff.old=red bold"
        "color.diff.new=green bold"
        "color.diff.whitespace=red reverse"
    )
    
    for config in "${git_diff_configs[@]}"; do
        local key="${config%%=*}"
        local value="${config#*=}"
        
        if ! run_cmd git config --global "${key}" "${value}"; then
            warning "Failed to set Git config: ${key}=${value}"
        fi
    done
    
    info "diff-so-fancy setup completed successfully"
    return 0
}

# Main setup function
setup_git() {
    local errors=0
    
    # Install Git if needed
    if ! install_git; then
        error "Failed to install Git"
        ((errors++))
    fi
    
    # Set up Git configuration
    if ! setup_git_config; then
        error "Failed to set up Git configuration"
        ((errors++))
    fi
    
    # Setup Git hooks
    if ! setup_git_hooks; then
        error "Failed to set up Git hooks"
        ((errors++))
    fi
    
    # Setup diff-so-fancy
    if ! setup_git_diff_so_fancy; then
        warning "Failed to set up diff-so-fancy"
    fi
    
    if [[ ${errors} -gt 0 ]]; then
        warning "Git setup completed with ${errors} errors"
        return 1
    fi
    
    info "Git setup completed successfully"
    return 0
}

# Run setup if the script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_git "$@"
    exit $?
fi
