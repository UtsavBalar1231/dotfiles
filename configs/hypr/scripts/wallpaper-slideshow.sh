#!/usr/bin/env bash

# Set the background
if [ -d "${HOME}/Pictures/wallpapers/" ]; then
	# check XDG session
	session=$(echo "$XDG_SESSION_TYPE" | tr '[:upper:]' '[:lower:]')

	case "$session" in
	"x11")
		while true; do
			feh --randomize --no-fehbg --bg-max "${HOME}/Pictures/wallpapers/" | tee -a /tmp/i3-startup.log
			sleep 60
		done
		;;
	"wayland")
		while true; do
			img=$(find "${HOME}/Pictures/wallpapers/" | shuf -n 1)

			if command -v wal >/dev/null 2>&1; then
				wal -ei "${img}" 2>&1 | tee -a /tmp/pywal.log
			fi
			if command -v hyprpaper >/dev/null 2>&1; then
				notify-send -i "$img" "Wallpaper changed"
				hyprctl hyprpaper preload "${img}"
				hyprctl hyprpaper wallpaper eDP-1,"$img"
			else
				swaybg -i "${img}" &
			fi
			sleep 240
		done
		;;
	*)
		while true; do
			feh --randomize --no-fehbg --bg-max "${HOME}/Pictures/wallpapers/" | tee -a /tmp/i3-startup.log
			sleep 60
		done
		;;
	esac
fi
