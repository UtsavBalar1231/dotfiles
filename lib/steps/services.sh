# shellcheck shell=bash
# Step 7: optional timezone, then systemd units (skipped without systemd,
# e.g. in containers).

# An instance such as ly@tty2.service exists when its template ly@.service does.
unit_exists() {
	local unit=$1
	[[ $unit == *@?*.* ]] && unit=${unit%%@*}@.${unit##*.}
	[[ -n $(systemctl list-unit-files --no-legend "$unit" 2>/dev/null) ]]
}

enable_unit() {
	if ! unit_exists "$1"; then
		warn "$1 is not installed; not enabling it"
	elif systemctl is-enabled -q "$1" 2>/dev/null; then
		ok "$1 already enabled"
	else
		as_root systemctl enable "$1"
	fi
}

# Enabled only, never started: starting a display manager from a running
# session would take over the console.
enable_ly() {
	local unit dm=/etc/systemd/system/display-manager.service
	if unit_exists ly.service; then
		unit=ly.service
	elif unit_exists ly@.service; then
		unit=ly@tty2.service
	else
		info "ly is not installed; no display manager enabled"
		return 0
	fi
	if [[ -L $dm && $(readlink "$dm") != */ly* ]]; then
		warn "another display manager is enabled ($(readlink "$dm")); not enabling ly"
		return 0
	fi
	if [[ $unit == ly@tty2.service ]] && systemctl is-enabled -q getty@tty2.service 2>/dev/null; then
		as_root systemctl disable getty@tty2.service
	fi
	enable_unit "$unit"
}

set_timezone() {
	[[ -e /usr/share/zoneinfo/$TIMEZONE ]] || die "unknown timezone '$TIMEZONE' (no /usr/share/zoneinfo/$TIMEZONE; is tzdata installed?)"
	if [[ $(readlink /etc/localtime) == */zoneinfo/"$TIMEZONE" ]]; then
		ok "timezone is already $TIMEZONE"
	elif has_systemd; then
		as_root timedatectl set-timezone "$TIMEZONE"
	else
		as_root ln -sfn "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
	fi
}

step_services() {
	[[ -z $TIMEZONE ]] || set_timezone
	if ! has_systemd; then
		info "systemd is not running (container?); skipping services"
		return 0
	fi
	local u
	local -a units=(fstrim.timer)
	[[ $ROLE == desktop ]] && units+=(NetworkManager.service bluetooth.service)
	[[ $ROLE != minimal ]] && units+=(docker.service)
	[[ $ROLE == desktop || $LAPTOP == 1 ]] && units+=(power-profiles-daemon.service)
	for u in "${units[@]}"; do enable_unit "$u"; done
	[[ $ROLE == desktop ]] && enable_ly

	if [[ $ROLE != minimal ]] && getent group docker >/dev/null; then
		if [[ " $(id -nG "$ME") " == *" docker "* ]]; then
			ok "$ME is already in the docker group"
		else
			as_root usermod -aG docker "$ME"
		fi
	fi
}
