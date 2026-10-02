#!/bin/bash
# Rofi power menu for Niri

# Dependency check
for cmd in rofi notify-send systemctl; do
    command -v "$cmd" &>/dev/null || { notify-send -u critical "Missing: $cmd"; exit 1; }
done

# Helper: confirmation dialog
confirm() {
    local action="$1"
    local response
    response=$(echo -e "Yes\nNo" | rofi -dmenu -p "Confirm $action?" -theme-str 'window {width: 15%;}')
    [ "$response" = "Yes" ]
}

# Build menu dynamically based on available commands
options=""
command -v swaylock &>/dev/null && options+="󰌾 Lock\n"
command -v niri &>/dev/null && options+="󰍃 Logout\n"
options+="󰜉 Reboot\n󰐥 Shutdown\n󰒲 Suspend"

# Add hibernate if supported
if [ -f /sys/power/disk ] && grep -q 'disk' /sys/power/state 2>/dev/null; then
    options+="\n󰤄 Hibernate"
fi

chosen=$(echo -e "$options" | rofi -dmenu -p "󰐦 Power" -theme-str 'window {width: 20%;}')

case "$chosen" in
    "󰌾 Lock")
        swaylock
        ;;
    "󰍃 Logout")
        niri msg action quit
        ;;
    "󰜉 Reboot")
        confirm "Reboot" && systemctl reboot
        ;;
    "󰐥 Shutdown")
        confirm "Shutdown" && systemctl poweroff
        ;;
    "󰒲 Suspend")
        systemctl suspend
        ;;
    "󰤄 Hibernate")
        confirm "Hibernate" && systemctl hibernate
        ;;
esac
