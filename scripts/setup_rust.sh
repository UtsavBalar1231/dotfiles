#!/usr/bin/env bash
# ====================================================================
# setup_rust.sh - Rust installation and toolchain setup
# ====================================================================

# Source utility functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/utils.sh"

# ---------------------------------------------------------------------
# Rust Setup Functions
# ---------------------------------------------------------------------

# Install Rust using official rustup
install_rust_via_rustup() {
	info "Installing Rust via rustup.rs script"
	
	if has_command curl; then
		if ! run_cmd curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable; then
			error "Failed to install Rust via curl"
			return 1
		fi
	elif has_command wget; then
		if ! run_cmd wget -qO- https://sh.rustup.rs | sh -s -- -y --default-toolchain stable; then
			error "Failed to install Rust via wget"
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
	
	return 0
}

# Install Rust using package manager
install_rust_via_package_manager() {
	local distro="$1"
	
	case "${distro}" in
		arch)
			info "Installing rustup via pacman"
			
			if ! run_with_sudo pacman -S --noconfirm rustup; then
				error "Failed to install rustup via pacman"
				return 1
			fi
			
			info "Setting up stable toolchain"
			if ! run_cmd rustup toolchain install stable --profile minimal; then
				error "Failed to install stable toolchain"
				return 1
			fi
			;;
			
		debian|ubuntu)
			info "Installing Rust via apt"
			
			if ! run_with_sudo apt-get update -y; then
				error "Failed to update package lists"
				return 1
			fi
			
			if ! run_with_sudo apt-get install -y rustc cargo; then
				error "Failed to install Rust via apt"
				warning "Falling back to rustup installation"
				return 1
			fi
			;;
			
		*)
			error "Unsupported distribution for package manager installation: ${distro}"
			return 1
			;;
	esac
	
	return 0
}

# Verify Rust installation
verify_rust_installation() {
	# Check cargo
	if ! has_command cargo; then
		# Try to source environment and check again
		if [[ -f "${HOME}/.cargo/env" ]]; then
			# shellcheck disable=SC1091
			source "${HOME}/.cargo/env"
			
			if ! has_command cargo; then
				error "Cargo not found even after sourcing environment"
				return 1
			fi
		else
			error "Cargo not found and no environment file exists"
			return 1
		fi
	fi
	
	# Check rustc
	if ! has_command rustc; then
		error "rustc not found"
		return 1
	fi
	
	# Check rustup if it was installed
	if [[ -f "${HOME}/.cargo/bin/rustup" ]] && ! has_command rustup; then
		error "rustup not found in PATH but exists in ~/.cargo/bin"
		return 1
	fi
	
	# Get and log versions
	local cargo_version
	local rustc_version
	cargo_version=$(cargo --version)
	rustc_version=$(rustc --version)
	
	info "Verified Rust installation:"
	info "  ${cargo_version}"
	info "  ${rustc_version}"
	
	return 0
}

# Update PATH for current session
update_rust_path() {
	# Add cargo bin to PATH if not already there
	if [[ ! ":${PATH}:" == *":${HOME}/.cargo/bin:"* ]]; then
		export PATH="${HOME}/.cargo/bin:${PATH}"
		debug "Added ${HOME}/.cargo/bin to PATH"
	fi
	
	# Source environment file if it exists
	if [[ -f "${HOME}/.cargo/env" ]]; then
		# shellcheck disable=SC1091
		source "${HOME}/.cargo/env"
		debug "Sourced ${HOME}/.cargo/env"
	fi
}

# Main setup function
setup_rust() {
	info "Setting up Rust environment"
	
	# Check if Rust is already installed
	if has_command rustc && has_command cargo; then
		local cargo_version
		local rustc_version
		cargo_version=$(cargo --version)
		rustc_version=$(rustc --version)
		
		info "Rust is already installed:"
		info "  ${cargo_version}"
		info "  ${rustc_version}"
		
		# Update Rust if rustup is available
		if has_command rustup; then
			info "Updating Rust via rustup"
			
			if ! run_cmd rustup update; then
				warning "Failed to update Rust"
			fi
		fi
		
		update_rust_path
		return 0
	fi
	
	# Detect distribution
	local distro
	distro=$(detect_distro)
	
	# Try package manager installation first
	if install_rust_via_package_manager "${distro}"; then
		update_rust_path
		if verify_rust_installation; then
			info "Rust installed successfully via package manager"
			return 0
		else
			warning "Package manager installation succeeded but verification failed"
		fi
	fi
	
	# Fall back to rustup installation
	warning "Falling back to rustup installation"
	if install_rust_via_rustup; then
		update_rust_path
		if verify_rust_installation; then
			info "Rust installed successfully via rustup"
			return 0
		else
			error "rustup installation succeeded but verification failed"
			return 1
		fi
	else
		error "Failed to install Rust"
		return 1
	fi
}

# Run setup if the script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	setup_rust "$@"
	exit $?
fi
