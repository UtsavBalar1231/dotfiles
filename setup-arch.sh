#!/usr/bin/env bash

function cargo_check() {
	if ! command -v paru >/dev/null 2>&1; then
		if ! command -v cargo >/dev/null 2>&1; then
			if [ -d ~/.cargo/bin ]; then
				export PATH="$HOME/.cargo/bin:$PATH"
			fi

			cargo install paru
		fi
	fi
}

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_DIR="$SOURCE_DIR/scripts"

if [ ! -d "$SCRIPT_DIR" ]; then
	echo "ERROR: Unable to find scripts directory."
	exit 1
fi

echo "Setting up Arch Linux..."

ARCH_PKG_INSTALLER="$SCRIPT_DIR/install_arch_pkgs"

if [ ! -f "$ARCH_PKG_INSTALLER" ]; then
	echo "ERROR: Unable to find package installer script."
	exit 1
fi

pkgs_list_files=$(find "$SOURCE_DIR/pkglist/" -name "*.list" | tr '\n' ' ')
if [ -z "$pkgs_list_files" ]; then
	echo "WARNING: No package list files found."
fi

echo "Installing packages..."

"$ARCH_PKG_INSTALLER" "$pkgs_list_files"
