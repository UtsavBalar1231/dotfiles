# shellcheck shell=bash
# Step 5: make zsh the login shell of the invoking user (never root). The zsh
# config bootstraps its own plugin manager on first start.

step_shell() {
	local zsh current
	if ! have zsh; then
		[[ $DRY_RUN == 1 ]] || die "zsh is not installed; it belongs in packages/$DISTRO/base.list"
		as_root chsh -s /usr/bin/zsh "$ME"
		return 0
	fi
	current=$(getent passwd "$ME" | cut -d: -f7)
	if [[ $(readlink -f "$current") == "$(readlink -f "$(command -v zsh)")" ]]; then
		ok "login shell is already zsh ($current)"
		return 0
	fi
	# chsh only accepts a path listed in /etc/shells.
	zsh=$(grep -m1 -x '/.*/zsh' /etc/shells) || die "zsh is not listed in /etc/shells"
	as_root chsh -s "$zsh" "$ME"
}
