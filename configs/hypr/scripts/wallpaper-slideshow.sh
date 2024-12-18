#!/usr/bin/env bash

# Configuration
WALLPAPER_DIR="${HOME}/Pictures/wallpapers/"
CHANGE_INTERVAL=240       # seconds (4 minutes)
TRANSITION_DURATION=0.069 # seconds (approximately 1 frame at 144Hz)

# Function to get a random wallpaper
get_random_wallpaper() {
	find "$WALLPAPER_DIR" -type f | shuf -n 1
}

# Function to set wallpaper with swww
set_wallpaper_swww() {
	local img="$1"
	if command -v swww >/dev/null 2>&1; then
		swww img "$img" --transition-type=random --transition-duration="$TRANSITION_DURATION" &>/dev/null
	fi
}

# Function to set wallpaper with other tools (fallback)
set_wallpaper_fallback() {
	local img="$1"
	if command -v wal >/dev/null 2>&1; then
		wal -ei "$img" &>/dev/null
	elif command -v matugen >/dev/null 2>&1; then
		matugen image "$img" &>/dev/null
	elif command -v hyprpaper >/dev/null 2>&1; then
		hyprctl hyprpaper preload "$img" &>/dev/null
		hyprctl hyprpaper wallpaper eDP-1,"$img" &>/dev/null # Replace eDP-1 if needed
	elif command -v swaybg >/dev/null 2>&1; then
		swaybg -i "$img" &
	elif command -v feh >/dev/null 2>&1; then
		feh --bg-fill "$img" &>/dev/null # Use --bg-fill for better scaling
	fi
}

# Main loop
if [ -d "$WALLPAPER_DIR" ]; then
	session=$(echo "$XDG_SESSION_TYPE" | tr '[:upper:]' '[:lower:]')

	while true; do
		img=$(get_random_wallpaper)
		if [[ -z "$img" ]]; then
			echo "No images found in $WALLPAPER_DIR"
			sleep "$CHANGE_INTERVAL"
			continue
		fi

		case "$session" in
		"wayland")
			set_wallpaper_swww "$img"
			if [[ $? -ne 0 ]]; then # Check if swww failed
				set_wallpaper_fallback "$img"
			fi
			;;
		"x11" | "") # Default to feh on X11 or if session is unknown
			set_wallpaper_fallback "$img"
			;;
		*) # Handle other session types if needed
			set_wallpaper_fallback "$img"
			;;
		esac
		sleep "$CHANGE_INTERVAL"
	done
fi
