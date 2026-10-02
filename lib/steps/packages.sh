# shellcheck shell=bash
# Step 3: install the packages of the selected groups.

step_packages() {
	case $DISTRO in
	arch) arch_packages ;;
	debian | ubuntu) apt_packages ;;
	esac
}

# --check: report every selected package the distro (or AUR) does not have,
# exiting non-zero when there is one.
check_packages() {
	local missing
	local -a names
	case $DISTRO in
	arch) missing=$(arch_check) ;;
	debian | ubuntu) missing=$(apt_check) ;;
	esac
	if [[ -n $missing ]]; then
		mapfile -t names <<<"$missing"
		header "Missing on $DISTRO_NAME (${#names[@]})"
		printf '  %s\n' "${names[@]}"
		exit 1
	fi
	ok "all $((${#REPO_PKGS[@]} + ${#AUR_PKGS[@]})) packages are available"
}
