#!/usr/bin/env bash
# ====================================================================
# package_manager.sh - Package installation management
# ====================================================================

# Source utility functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/utils.sh"

# Global constants
readonly CACHE_DIR="${HOME}/.cache/dotfiles/packages"
readonly DEFAULT_CACHE="${CACHE_DIR}/default_pkgs.cache"
readonly AUR_CACHE="${CACHE_DIR}/aur_pkgs.cache"
readonly GROUP_CACHE="${CACHE_DIR}/pkg_groups.cache"
readonly CACHE_EXPIRY=3600 # 1 hour expiry

# AUR helper configuration
AUR_HELPER="yay"
AUR_HELPERS=("yay" "pikaur" "aurman" "trizen")

# ---------------------------------------------------------------------
# Cache Management Functions
# ---------------------------------------------------------------------

# Initialize package cache
init_cache() {
    debug "Initializing package cache"
    make_dir "${CACHE_DIR}"
}

# Clear package cache
clear_cache() {
    if [[ -d "${CACHE_DIR}" ]]; then
        debug "Clearing package cache"
        rm -rf "${CACHE_DIR:?}"/*
        make_dir "${CACHE_DIR}"
    fi
}

# Check if cache is expired
is_cache_expired() {
    local cache_file="$1"
    
    [[ ! -f "${cache_file}" ]] && return 0
    
    local file_time
    file_time=$(stat -c %Y "${cache_file}")
    local current_time
    current_time=$(date +%s)
    
    if (( current_time - file_time > CACHE_EXPIRY )); then
        debug "Cache expired: ${cache_file}"
        return 0
    fi
    
    return 1
}

# ---------------------------------------------------------------------
# Arch Linux Package Management
# ---------------------------------------------------------------------

# Find and set available AUR helper
find_aur_helper() {
    for helper in "${AUR_HELPERS[@]}"; do
        if has_command "${helper}"; then
            AUR_HELPER="${helper}"
            debug "Using AUR helper: ${AUR_HELPER}"
            return 0
        fi
    done
    
    # If no helper is found, attempt to install the default one
    if ! has_command "${AUR_HELPER}"; then
        info "No AUR helper found, attempting to install ${AUR_HELPER}"
        install_aur_helper
        return $?
    fi
    
    return 0
}

# Install AUR helper (yay by default)
install_aur_helper() {
    if has_command "${AUR_HELPER}"; then
        debug "AUR helper ${AUR_HELPER} is already installed"
        return 0
    fi
    
    if ! has_command git; then
        info "Installing git for AUR helper installation"
        run_with_sudo pacman -S --noconfirm git || {
            error "Failed to install git"
            return 1
        }
    fi
    
    if ! has_command rustup && ! has_command cargo; then
        info "Installing rust for AUR helper installation"
        if ! run_with_sudo pacman -S --noconfirm rustup; then
            error "Failed to install rustup"
            return 1
        fi
        
        if ! rustup default stable; then
            error "Failed to set up rust stable toolchain"
            return 1
        fi
    fi
    
    local temp_dir
    temp_dir=$(mktemp -d)
    
    info "Cloning ${AUR_HELPER} repository"
    if ! run_cmd git clone "https://aur.archlinux.org/${AUR_HELPER}.git" "${temp_dir}"; then
        error "Failed to clone ${AUR_HELPER} repository"
        rm -rf "${temp_dir}"
        return 1
    fi
    
    info "Building and installing ${AUR_HELPER}"
    (
        cd "${temp_dir}" || return 1
        run_cmd makepkg -si --noconfirm
    ) || {
        error "Failed to build and install ${AUR_HELPER}"
        rm -rf "${temp_dir}"
        return 1
    }
    
    rm -rf "${temp_dir}"
    
    if ! has_command "${AUR_HELPER}"; then
        error "Installation of ${AUR_HELPER} failed"
        return 1
    fi
    
    info "Successfully installed ${AUR_HELPER}"
    return 0
}

# Fetch or load default Arch Linux repository packages
fetch_arch_default_pkgs() {
    if ! is_cache_expired "${DEFAULT_CACHE}"; then
        debug "Using cached default packages list"
        cat "${DEFAULT_CACHE}"
        return 0
    fi
    
    info "Fetching default Arch packages list"
    if ! run_cmd pacman -Ssq > "${DEFAULT_CACHE}.tmp"; then
        error "Failed to fetch default packages list"
        
        if [[ -f "${DEFAULT_CACHE}" ]]; then
            warning "Using potentially outdated cache"
            cat "${DEFAULT_CACHE}"
            return 0
        fi
        
        return 1
    fi
    
    mv "${DEFAULT_CACHE}.tmp" "${DEFAULT_CACHE}"
    cat "${DEFAULT_CACHE}"
    return 0
}

# Fetch or load AUR package list
fetch_aur_pkgs() {
    if ! is_cache_expired "${AUR_CACHE}"; then
        debug "Using cached AUR packages list"
        cat "${AUR_CACHE}"
        return 0
    fi
    
    info "Fetching AUR packages list"
    if ! run_cmd curl -s "https://aur.archlinux.org/packages.gz" | gunzip > "${AUR_CACHE}.tmp"; then
        error "Failed to fetch AUR packages list"
        
        if [[ -f "${AUR_CACHE}" ]]; then
            warning "Using potentially outdated cache"
            cat "${AUR_CACHE}"
            return 0
        fi
        
        return 1
    fi
    
    mv "${AUR_CACHE}.tmp" "${AUR_CACHE}"
    cat "${AUR_CACHE}"
    return 0
}

# Fetch or load Arch Linux package groups
fetch_arch_pkg_groups() {
    if ! is_cache_expired "${GROUP_CACHE}"; then
        debug "Using cached package groups list"
        cat "${GROUP_CACHE}"
        return 0
    fi
    
    info "Fetching package groups list"
    if ! run_cmd pacman -Sg | awk '{print $1}' | sort -u > "${GROUP_CACHE}.tmp"; then
        error "Failed to fetch package groups list"
        
        if [[ -f "${GROUP_CACHE}" ]]; then
            warning "Using potentially outdated cache"
            cat "${GROUP_CACHE}"
            return 0
        fi
        
        return 1
    fi
    
    mv "${GROUP_CACHE}.tmp" "${GROUP_CACHE}"
    cat "${GROUP_CACHE}"
    return 0
}

# Install Arch packages from file
install_arch_packages() {
    local file="$1"
    local quiet="${2:-false}"
    
    if [[ ! -f "${file}" ]]; then
        error "Package list file not found: ${file}"
        return 1
    fi
    
    [[ "${quiet}" == "false" ]] && info "Processing package list: ${file}"
    
    # Find AUR helper if needed
    find_aur_helper || {
        error "Failed to find or install AUR helper"
        return 1
    }
    
    # Load package lists
    local default_pkgs
    local aur_pkgs
    local pkg_groups
    
    default_pkgs=$(fetch_arch_default_pkgs) || {
        error "Failed to fetch default packages list"
        return 1
    }
    
    aur_pkgs=$(fetch_aur_pkgs) || {
        error "Failed to fetch AUR packages list"
        return 1
    }
    
    pkg_groups=$(fetch_arch_pkg_groups) || {
        error "Failed to fetch package groups list"
        return 1
    }
    
    # Read the package list into an array
    local packages
    mapfile -t packages < "${file}"
    
    # Categorize packages
    local default_found=()
    local aur_found=()
    local group_found=()
    local not_found=()
    
    for package in "${packages[@]}"; do
        # Skip empty lines and comments
        [[ -z "${package}" || "${package}" =~ ^# ]] && continue
        
        if grep -q "^${package}$" <<< "${default_pkgs}"; then
            default_found+=("${package}")
        elif grep -q "^${package}$" <<< "${aur_pkgs}"; then
            aur_found+=("${package}")
        elif grep -q "^${package}$" <<< "${pkg_groups}"; then
            group_found+=("${package}")
        else
            not_found+=("${package}")
        fi
    done
    
    # Install packages
    local install_errors=0
    
    # Install default packages
    if [[ ${#default_found[@]} -gt 0 ]]; then
        info "Installing ${#default_found[@]} default packages"
        
        if ! run_with_sudo pacman -S --needed --noconfirm "${default_found[@]}"; then
            error "Failed to install some default packages"
            ((install_errors++))
        fi
    fi
    
    # Install package groups
    if [[ ${#group_found[@]} -gt 0 ]]; then
        info "Installing ${#group_found[@]} package groups"
        
        if ! run_with_sudo pacman -S --needed --noconfirm "${group_found[@]}"; then
            error "Failed to install some package groups"
            ((install_errors++))
        fi
    fi
    
    # Install AUR packages
    if [[ ${#aur_found[@]} -gt 0 ]]; then
        info "Installing ${#aur_found[@]} AUR packages"
        
        for package in "${aur_found[@]}"; do
            info "Installing AUR package: ${package}"
            
            if ! run_cmd "${AUR_HELPER}" -S --needed --noconfirm "${package}"; then
                error "Failed to install AUR package: ${package}"
                ((install_errors++))
            fi
        done
    fi
    
    # Report not found packages
    if [[ ${#not_found[@]} -gt 0 ]]; then
        warning "The following packages were not found:"
        for package in "${not_found[@]}"; do
            warning "  - ${package}"
        done
    fi
    
    # Return success if no errors
    return ${install_errors}
}

# ---------------------------------------------------------------------
# Debian/Ubuntu Package Management
# ---------------------------------------------------------------------

# Install Debian/Ubuntu packages from a list
install_debian_packages() {
    local packages="$1"
    local quiet="${2:-false}"
    
    if [[ ! -f "${packages}" ]]; then
        # Assume it's a string of package names
        packages=$(echo "${packages}" | tr -d '\n')
    else
        # Read the file content
        packages=$(tr '\n' ' ' < "${packages}")
    fi
    
    [[ "${quiet}" == "false" ]] && info "Installing packages: ${packages}"
    
    # Update package lists
    if ! run_with_sudo apt-get update -y; then
        error "Failed to update package lists"
        return 1
    fi
    
    # Convert to array
    local package_list
    read -ra package_list <<< "${packages}"
    local install_errors=0
    
    # Install each package with error tracking
    for package in "${package_list[@]}"; do
        # Skip empty lines and comments
        [[ -z "${package}" || "${package}" =~ ^# ]] && continue
        
        info "Installing package: ${package}"
        
        if ! run_with_sudo apt-get install -y "${package}"; then
            error "Failed to install package: ${package}"
            ((install_errors++))
        fi
    done
    
    return ${install_errors}
}

# ---------------------------------------------------------------------
# General Package Management
# ---------------------------------------------------------------------

# Install packages based on distribution
install_packages() {
    local file="$1"
    local distro
    distro=$(detect_distro)
    
    case "${distro}" in
        arch)
            install_arch_packages "${file}"
            ;;
        debian|ubuntu)
            install_debian_packages "${file}"
            ;;
        *)
            error "Unsupported distribution for package installation: ${distro}"
            return 1
            ;;
    esac
}

# Install a list of packages from multiple files
install_package_lists() {
    local files=("$@")
    local errors=0
    
    init_cache
    
    for file in "${files[@]}"; do
        info "Processing package list: ${file}"
        
        if ! install_packages "${file}"; then
            error "Failed to install some packages from: ${file}"
            ((errors++))
        fi
    done
    
    if [[ ${errors} -gt 0 ]]; then
        warning "Completed with ${errors} errors"
        return 1
    fi
    
    info "All packages installed successfully"
    return 0
}

# Main function to handle different scenarios
main() {
    # Initialize
    init_cache
    
    # Parse arguments
    if [[ $# -eq 0 ]]; then
        error "No package list files specified"
        echo "Usage: $0 <file1> [<file2> ...]"
        return 1
    fi
    
    # Install packages from all files
    install_package_lists "$@"
    return $?
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
    exit $?
fi 
