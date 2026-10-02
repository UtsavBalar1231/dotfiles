# shellcheck shell=bash
# Step 8: summary and the things the installer deliberately leaves to you.

step_post() {
	header "Done: $DISTRO_NAME, role $ROLE, groups ${SEL_GROUPS[*]}"
	echo "Manual follow-ups:"
	echo "  - Log out and back in so the login shell and group changes apply."
	echo "  - Restore your wallpapers into ~/Pictures/wallpapers."
	if [[ $GPU == nvidia ]]; then
		cat <<-'EOF'
			  - NVIDIA: the installer never edits the bootloader, kernel command line,
			    mkinitcpio or initramfs. Do that by hand if you need it, and do NOT add
			    the nvidia modules to the initramfs on the RTX 5090 machine: it hangs boot.
		EOF
		if [[ $DISTRO == debian ]]; then
			cat <<-'EOF'
				  - Debian's packaged NVIDIA driver (550) cannot drive RTX 50 series cards.
				    Those need driver 570+ from NVIDIA's own apt repository, which this
				    installer deliberately does not add (no third-party repos).
			EOF
		fi
	fi
	if [[ ${BUILT_WAYLAND_FROM_SOURCE:-0} == 1 ]]; then
		echo "  - niri/eww/awww/xwayland-satellite were built from source into ~/.cargo/bin;"
		echo "    cargo does not install niri's session files (resources/ in its repo)."
	fi
	echo "  - Full log: $LOG_FILE"
}
