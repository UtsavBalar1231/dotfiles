#!/usr/bin/env bash
# shellcheck disable=SC2155

ICON_WIFI=" "
ICON_ETHERNET="󰈀 "
ICON_DISCONNECTED="󰖪 "
ICON_BATTERY=(
	"󰂎" "󰁺" "󰁻" "󰁼" "󰁽"
	"󰁾" "󰁿" "󰂀" "󰂁" "󰂂"
	"󰁹"
)
ICON_USER=" "
ICON_PLAYING="󰎈 "
ICON_PAUSED="󰏤 "
ICON_STOPPED="󰐊 "

get_network_details() {
	local wifi_status="" ethernet_status="" interfaces ip_address essid
	interfaces="$(ip link show | awk '/^[0-9]+: / {print $2}')"

	for interface in $interfaces; do
		interface="${interface%:}"
		ip_address="$(ip addr show "$interface" 2>/dev/null | awk '/inet / {print $2}' | cut -d/ -f1)"

		if [[ -n "$ip_address" ]]; then
			if [[ "$interface" =~ ^w ]]; then
				essid="$(iw dev "$interface" link 2>/dev/null | awk '/SSID/ {for (i=2; i<=NF; i++) printf "%s ", $i; print ""}')"
				wifi_status="$ICON_WIFI $essid"
			elif [[ "$interface" =~ ^e ]]; then
				ethernet_status="$ICON_ETHERNET $ip_address"
			fi
		fi
	done

	if [[ -n "$wifi_status" && -n "$ethernet_status" ]]; then
		echo "$wifi_status $ethernet_status"
	elif [[ -n "$wifi_status" ]]; then
		echo "$wifi_status"
	elif [[ -n "$ethernet_status" ]]; then
		echo "$ICON_DISCONNECTED $ethernet_status"
	else
		echo "$ICON_DISCONNECTED"
	fi
}

get_battery_percentage() {
	local battery_percentage=-1 battery_capacity="/sys/class/power_supply/BAT1/capacity"

	if [[ -f "$battery_capacity" ]]; then
		battery_percentage="$(cat "$battery_capacity")"
	else
		echo "󰂎 Error: Battery information not found."
		exit 1
	fi

	if [[ $battery_percentage -ge 0 ]]; then
		echo "${ICON_BATTERY[$((battery_percentage / 10))]} $battery_percentage%"
	else
		echo "󰂎 No battery found."
		exit 1
	fi
}

get_whoami() {
	echo "$ICON_USER $(whoami)"
}

get_which_song() {
	if ! command -v mpc &>/dev/null; then
		echo ""
		return
	fi

	local music_status which_song
	music_status="$(mpc status 2>/dev/null | awk '/^\[.*\]/ {print $1}')"
	which_song="$(mpc current 2>/dev/null)"

	case "$music_status" in
	"[playing]")
		echo "$ICON_PLAYING $which_song"
		;;
	"[paused]")
		echo "$ICON_PAUSED $which_song"
		;;
	"[stopped]")
		echo "$ICON_STOPPED Not Playing"
		;;
	*)
		echo ""
		;;
	esac
}

main() {
	case "${1:-}" in
	"network")
		get_network_details
		;;
	"battery")
		get_battery_percentage
		;;
	"whoami")
		get_whoami
		;;
	"song")
		get_which_song
		;;
	*)
		echo "󰇚 Usage: $0 {network|battery|whoami|song}"
		exit 1
		;;
	esac
}

main "$@"
