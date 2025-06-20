#!/usr/bin/env bash

PORTAL_PROCESSES=(
	xdg-desktop-portal-hyprland
	xdg-desktop-portal-gnome
	xdg-desktop-portal-kde
	xdg-desktop-portal-lxqt
	xdg-desktop-portal-wlr
	xdg-desktop-portal-gtk
	xdg-desktop-portal
)

kill_portals() {
	local process
	for process in "${PORTAL_PROCESSES[@]}"; do
		if pgrep -x "$process" >/dev/null; then
			echo "Killing $process..."
			sudo killall -e "$process" || true
		fi
	done
}

start_portal() {
	local portal_path="$1"
	if [[ -f "$portal_path" ]]; then
		echo "Starting $portal_path..."
		"$portal_path" &
		sleep 1
	fi
}

main() {
	kill_portals
	start_portal "/usr/lib/xdg-desktop-portal-gnome"
	start_portal "/usr/lib/xdg-desktop-portal-gtk"
	start_portal "/usr/lib/xdg-desktop-portal"
}

main "$@"
