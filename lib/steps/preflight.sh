# shellcheck shell=bash
# Step 1: who/what/where, the plan, and the go-ahead.

# Runs for every mode except --list/--help, before any step.
preflight_detect() {
	((EUID != 0)) || die "do not run as root; run as your normal user (it needs sudo rights)"
	detect_os

	GPU_SOURCE=flag
	if [[ $GPU == auto ]]; then
		GPU=$(detect_gpu)
		GPU_SOURCE=auto
	fi
	LAPTOP_SOURCE=flag
	if [[ $LAPTOP == auto ]]; then
		LAPTOP=0
		detect_laptop && LAPTOP=1
		LAPTOP_SOURCE=auto
	fi

	select_groups
	resolve_packages
}

show_plan() {
	local yn=(no yes) mode=install
	[[ $DRY_RUN == 1 ]] && mode=dry-run
	[[ $CHECK == 1 ]] && mode=check
	header "Plan"
	printf '  %-9s %s\n' \
		distro "$DISTRO_NAME ($DISTRO ${DISTRO_VERSION}, $ARCH)" \
		role "$ROLE" \
		gpu "$GPU ($GPU_SOURCE)" \
		laptop "${yn[$LAPTOP]} ($LAPTOP_SOURCE)" \
		extras "${EXTRAS[*]:--}" \
		groups "${SEL_GROUPS[*]}" \
		packages "${#REPO_PKGS[@]} from repos$([[ $DISTRO == arch ]] && echo ", ${#AUR_PKGS[@]} from the AUR")" \
		mode "$mode$([[ $NO_UPGRADE == 1 ]] && echo ', no system upgrade')"
	[[ $CHECK == 1 ]] || printf '  %-9s %s\n' steps "${RUN_STEPS[*]}"
	[[ -z $TIMEZONE ]] || printf '  %-9s %s\n' timezone "$TIMEZONE"
	printf '  %-9s %s\n' log "$LOG_FILE"
}

step_preflight() {
	show_plan
	[[ $DRY_RUN == 1 ]] && return 0
	confirm "Apply this plan?" || die "aborted; nothing was changed"
	run sudo -v
}
