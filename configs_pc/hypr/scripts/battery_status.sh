#!/usr/bin/env bash

# Battery Monitoring Script for Hyprland
# Requires `notify-send` for notifications

# Configuration
BATTERY=$(basename "$(find /sys/class/power_supply/ | grep BAT | head -n 1)") # Automatically detect battery name
CHECK_INTERVAL=1                                                              # Time in seconds between checks
LOW_BATTERY_THRESHOLD=20                                                      # Battery percentage for low battery warning
CRITICAL_BATTERY_THRESHOLD=10                                                 # Battery percentage for critical battery warning

# Icon Paths
GRUVBOX_PATH="/usr/share/icons/Gruvbox-Plus-Dark/panel/16"
BREEZE_PATH="/usr/share/icons/breeze/status/16"

# Determine icon set
if [[ -d $GRUVBOX_PATH ]]; then
	ICON_PATH=$GRUVBOX_PATH
elif [[ -d $BREEZE_PATH ]]; then
	ICON_PATH=$BREEZE_PATH
else
	ICON_PATH=
fi

# Functions
get_icon_for_capacity() {
	if [[ -z $ICON_PATH ]]; then
		echo ""
		return
	fi

	local capacity=$1
	case $capacity in
	[0-9] | 10) echo "$ICON_PATH/battery-010.svg" ;;
	1[1-9] | 20) echo "$ICON_PATH/battery-020.svg" ;;
	2[1-9] | 30) echo "$ICON_PATH/battery-030.svg" ;;
	3[1-9] | 40) echo "$ICON_PATH/battery-040.svg" ;;
	4[1-9] | 50) echo "$ICON_PATH/battery-050.svg" ;;
	5[1-9] | 60) echo "$ICON_PATH/battery-060.svg" ;;
	6[1-9] | 70) echo "$ICON_PATH/battery-070.svg" ;;
	7[1-9] | 80) echo "$ICON_PATH/battery-080.svg" ;;
	8[1-9] | 90) echo "$ICON_PATH/battery-090.svg" ;;
	100) echo "$ICON_PATH/battery-100.svg" ;;
	*) echo "$ICON_PATH/battery-000.svg" ;;
	esac
}

notify() {
	local urgency="$1"
	local title="$2"
	local message="$3"
	local icon="$4"
	notify-send -u "$urgency" -i "$icon" "$title" "$message"
}

get_battery_status() {
	cat /sys/class/power_supply/"$BATTERY"/status
}

get_battery_capacity() {
	cat /sys/class/power_supply/"$BATTERY"/capacity
}

monitor_battery() {
	local previous_status=""
	local previous_capacity=-1

	while true; do
		local status
		local capacity
		local icon

		status=$(get_battery_status)
		capacity=$(get_battery_capacity)
		icon=$(get_icon_for_capacity "$capacity")

		# Trigger notifications on status change
		if [[ "$status" != "$previous_status" ]]; then
			case "$status" in
			"Charging")
				notify "low" "Charging" "Battery is charging: $capacity%\nPlugged in and charging." "$icon"
				;;
			"Discharging")
				notify "normal" "Charger Disconnected" "Battery is discharging: $capacity%\nRunning on battery power." "$icon"
				;;
			"Full")
				notify "low" "Battery Fully Charged" "Battery is fully charged at $capacity%\nConsider unplugging the charger." "$icon"
				;;
			esac
			previous_status="$status"
		fi

		# Trigger notifications for low or critical battery levels
		if [[ "$status" == "Discharging" ]]; then
			if ((capacity <= CRITICAL_BATTERY_THRESHOLD && capacity != previous_capacity)); then
				notify "critical" "Critical Battery" "Battery critically low: $capacity%!\nPlease connect the charger immediately." "$icon"
			elif ((capacity <= LOW_BATTERY_THRESHOLD && capacity != previous_capacity)); then
				notify "normal" "Low Battery" "Battery low: $capacity%\nConsider connecting the charger." "$icon"
			fi
		fi

		previous_capacity=$capacity
		sleep $CHECK_INTERVAL
	done
}

# Run the monitor in the background
monitor_battery &