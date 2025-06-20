#!/usr/bin/env bash
# ====================================================================
# setup.sh - Main dotfiles setup script
# ====================================================================

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source utility functions
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/scripts/utils.sh"

# ---------------------------------------------------------------------
# Command Line Arguments and Global Options
# ---------------------------------------------------------------------

# Parse common arguments
parse_args "$@"
parsed_index=$?

# If all arguments were processed, there are no additional arguments
if [[ ${parsed_index} -eq -1 ]]; then
    ARGS=()
else
    # Extract the remaining arguments
    ARGS=("${@:$((parsed_index+1))}")
fi

# ---------------------------------------------------------------------
# Usage and Help Functions
# ---------------------------------------------------------------------

# Display usage information
usage() {
    echo "Usage: ${0} [OPTIONS] [COMMANDS]"
    echo
    echo "Dotfiles setup tool to configure system environment."
    echo
    echo "Options:"
    echo "  -v, --verbose         Enable verbose output"
    echo "  -d, --debug           Enable debug mode"
    echo "  -t, --trace           Enable trace mode (very verbose)"
    echo "  --dry-run             Show actions without performing them"
    echo "  --log-level=LEVEL     Set log level (ERROR|WARNING|INFO|DEBUG|TRACE)"
    echo
    echo "Commands:"
    echo "  arch                  Setup Arch Linux"
    echo "  ubuntu                Setup Ubuntu/Debian"
    echo "  git                   Setup Git configuration only"
    echo "  shell                 Setup ZSH shell only"
    echo "  env                   Setup development environment only"
    echo "  rust                  Setup Rust environment only"
    echo "  help                  Show this help message"
    echo
    echo "If no command is specified, only common setup is performed."
}

# Display detailed help for specific command
usage_command() {
    local command="$1"
    
    case "${command}" in
        arch)
            echo "Usage: ${0} [OPTIONS] arch"
            echo
            echo "Setup Arch Linux with optimized configuration for dotfiles."
            echo "This will install necessary packages and configure the system."
            ;;
        ubuntu|debian)
            echo "Usage: ${0} [OPTIONS] ubuntu"
            echo
            echo "Setup Ubuntu/Debian with optimized configuration for dotfiles."
            echo "This will install necessary packages and configure the system."
            ;;
        git)
            echo "Usage: ${0} [OPTIONS] git"
            echo
            echo "Setup Git configuration with user settings and hooks."
            ;;
        shell)
            echo "Usage: ${0} [OPTIONS] shell"
            echo
            echo "Setup ZSH shell with Oh My Zsh and plugins."
            ;;
        env)
            echo "Usage: ${0} [OPTIONS] env"
            echo
            echo "Setup development environment with tools and configurations."
            ;;
        rust)
            echo "Usage: ${0} [OPTIONS] rust"
            echo
            echo "Setup Rust environment with toolchain and utilities."
            ;;
        *)
            usage
            ;;
    esac
}

# ---------------------------------------------------------------------
# Setup Functions
# ---------------------------------------------------------------------

# Common setup for all systems
setup_common() {
    info "Performing common setup steps"
    
    # Set local timezone
    export TZ="Asia/Kolkata"
    
    # Setup Git
    info "Setting up Git..."
    bash "${SCRIPT_DIR}/scripts/setup_git.sh" || {
        error "Git setup failed"
        return 1
    }
    
    info "Common setup completed successfully"
    return 0
}

# Setup Arch Linux
setup_arch() {
    info "Setting up Arch Linux"
    
    # Run the Arch-specific setup script
    bash "${SCRIPT_DIR}/setup-arch.sh" || {
        error "Arch Linux setup failed"
        return 1
    }
    
    info "Arch Linux setup completed successfully"
    return 0
}

# Setup Ubuntu/Debian
setup_ubuntu() {
    info "Setting up Ubuntu/Debian"
    
    # Run the Ubuntu-specific setup script
    bash "${SCRIPT_DIR}/setup-linux.sh" || {
        error "Ubuntu/Debian setup failed"
        return 1
    }
    
    info "Ubuntu/Debian setup completed successfully"
    return 0
}

# Setup Shell
setup_shell() {
    info "Setting up Shell environment"
    
    # Run the shell setup script
    bash "${SCRIPT_DIR}/scripts/setup_shell.sh" || {
        error "Shell setup failed"
        return 1
    }
    
    info "Shell setup completed successfully"
    return 0
}

# Setup Environment
setup_env() {
    info "Setting up development environment"
    
    # Run the environment setup script
    bash "${SCRIPT_DIR}/scripts/setup_env.sh" || {
        error "Environment setup failed"
        return 1
    }
    
    info "Development environment setup completed successfully"
    return 0
}

# Setup Rust
setup_rust() {
    info "Setting up Rust environment"
    
    # Run the Rust setup script
    bash "${SCRIPT_DIR}/scripts/setup_rust.sh" || {
        error "Rust setup failed"
        return 1
    }
    
    info "Rust environment setup completed successfully"
    return 0
}

# ---------------------------------------------------------------------
# Main Script Logic
# ---------------------------------------------------------------------

# Display help if requested
if [[ "${#ARGS[@]}" -gt 0 ]] && [[ "${ARGS[0]}" == "help" ]]; then
    if [[ "${#ARGS[@]}" -gt 1 ]]; then
        usage_command "${ARGS[1]}"
    else
        usage
    fi
    exit 0
fi

# Set script name for logging
SCRIPT_NAME=$(basename "${0}")

# Initialize
info "Starting dotfiles setup"
info "System: $(uname -a)"
info "User: $(whoami)"

# Perform common setup
errors=0

setup_common || ((errors++))

# Process commands
if [[ "${#ARGS[@]}" -gt 0 ]]; then
    for arg in "${ARGS[@]}"; do
        case "${arg}" in
            arch)
                setup_arch || ((errors++))
                ;;
            ubuntu|debian)
                setup_ubuntu || ((errors++))
                ;;
            git)
                bash "${SCRIPT_DIR}/scripts/setup_git.sh" || ((errors++))
                ;;
            shell)
                setup_shell || ((errors++))
                ;;
            env)
                setup_env || ((errors++))
                ;;
            rust)
                setup_rust || ((errors++))
                ;;
            help)
                usage
                exit 0
                ;;
            *)
                warning "Unknown option: ${arg}"
                usage
                exit 1
                ;;
        esac
    done
else
    # Auto-detect system type if no commands provided
    distro=$(detect_distro)
    
    info "Auto-detected distribution: ${distro}"
    
    case "${distro}" in
        arch)
            setup_arch || ((errors++))
            ;;
        ubuntu|debian)
            setup_ubuntu || ((errors++))
            ;;
        *)
            warning "Unsupported distribution: ${distro}"
            warning "Please specify a command (arch|ubuntu) for setup"
            errors=1
            ;;
    esac
fi

# Final status
if [[ ${errors} -gt 0 ]]; then
    warning "Setup completed with ${errors} errors"
    exit 1
else
    info "Setup completed successfully"
    exit 0
fi
