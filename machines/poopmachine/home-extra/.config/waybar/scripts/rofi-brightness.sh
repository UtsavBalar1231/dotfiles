#!/bin/bash

# Rofi brightness menu - synced with cache

OPTIONS="25%\n50%\n75%\n100%\nNight Mode (5%)"

chosen=$(echo -e "$OPTIONS" | rofi -dmenu -p "󰃠 Brightness" -theme-str 'window {width: 20%;}')

case "$chosen" in
    "25%") val=25 ;;
    "50%") val=50 ;;
    "75%") val=75 ;;
    "100%") val=100 ;;
    "Night Mode (5%)") val=5 ;;
    *) exit 0 ;;
esac

# Update cache

echo "$val" > /tmp/waybar_brightness



# Trigger waybar update

pkill -RTMIN+10 waybar



# Sync to monitor in background

pkill ddcutil 2>/dev/null

ddcutil setvcp 10 "$val" --brief >/dev/null 2>&1 &
