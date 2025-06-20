#!/usr/bin/env bash
# ====================================================================
# setup-arch.sh - Arch Linux specific setup
# ====================================================================

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source utility functions
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/scripts/utils.sh"

# ---------------------------------------------------------------------
# Arch-specific Setup Functions
# ---------------------------------------------------------------------

# Setup AUR helper
setup_aur_helper() {
	info "Setting up AUR helper"
	
	# Check if an AUR helper is already installed
	local aur_helpers=("yay" "pikaur" "trizen" "aurman")
	
	for helper in "${aur_helpers[@]}"; do
		if has_command "${helper}"; then
			info "AUR helper ${helper} is already installed"
			return 0
		fi
	done
	
	# Install yay as the default AUR helper
	sudo pacman -S --needed git base-devel
	git clone https://aur.archlinux.org/yay.git /tmp/yay
	cd /tmp/yay || exit
	makepkg -si
	
	info "AUR helper setup completed successfully"
	return 0
}

# Install packages from package lists
install_arch_packages() {
	info "Installing packages from package lists"
	
	# Get package installer script
	local pkg_installer="${SCRIPT_DIR}/scripts/package_manager.sh"
	
	if [[ ! -f "${pkg_installer}" ]]; then
		error "Package installer script not found: ${pkg_installer}"
		return 1
	fi
	
	# Find package list files
	local pkg_list_dir="${SCRIPT_DIR}/pkglist"
	local pkg_lists=()
	
	if [[ ! -d "${pkg_list_dir}" ]]; then
		error "Package list directory not found: ${pkg_list_dir}"
		return 1
	fi
	
	# Get list of package files
	while IFS= read -r -d '' file; do
		pkg_lists+=("${file}")
	done < <(find "${pkg_list_dir}" -name "*.list" -print0)
	
	if [[ ${#pkg_lists[@]} -eq 0 ]]; then
		warning "No package list files found in ${pkg_list_dir}"
		return 0
	fi
	
	# Display package lists
	info "Found ${#pkg_lists[@]} package list files:"
	for file in "${pkg_lists[@]}"; do
		info "  - $(basename "${file}")"
	done
	
	# Install packages from all files
	for file in "${pkg_lists[@]}"; do
		info "Installing packages from: $(basename "${file}")"
		
		if ! bash "${pkg_installer}" "${file}"; then
			warning "Failed to install some packages from ${file}"
		fi
	done
	
	info "Package installation completed"
	return 0
}

# Configure desktop environment if running under GNOME
configure_gnome_settings() {
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

# Set up zsh shell
setup_shell() {
	info "Setting up ZSH shell"
	
	if ! bash "${SCRIPT_DIR}/scripts/setup_shell.sh"; then
		error "Failed to set up ZSH shell"
		return 1
	fi
	
	info "ZSH shell setup completed successfully"
	return 0
}

# Main setup function
setup_arch() {
	info "Setting up Arch Linux environment"
	
	# Step 1: Set up AUR helper
	if ! setup_aur_helper; then
		error "Failed to set up AUR helper"
		return 1
	fi
	
	# Step 2: Install packages
	if ! install_arch_packages; then
		error "Failed to install packages"
		return 1
	fi
	
	# Step 3: Configure GNOME settings if applicable
	configure_gnome_settings
	
	# Step 4: Set up shell
	if ! setup_shell; then
		error "Failed to set up shell"
		return 1
	fi
	
	info "Arch Linux setup completed successfully"
	return 0
}

# ---------------------------------------------------------------------
# Main Script Logic
# ---------------------------------------------------------------------

# Set script name for logging
SCRIPT_NAME=$(basename "${0}")

# Initialize
info "Starting Arch Linux setup"
info "System: $(uname -a)"
info "User: $(whoami)"

# Run setup
setup_arch
exit_code=$?

# Final status
if [[ ${exit_code} -ne 0 ]]; then
	warning "Arch Linux setup completed with errors"
	exit ${exit_code}
else
	info "Arch Linux setup completed successfully"
	exit 0
fi
