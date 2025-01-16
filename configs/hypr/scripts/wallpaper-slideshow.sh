#!/usr/bin/env bash

# Configuration
STATIC_WALLPAPER_DIR="$HOME/Pictures/wallpapers"
DYNAMIC_WALLPAPER_DIR="$HOME/Pictures/wallpapers/gifs"
CHANGE_INTERVAL=540
TRANSITION_DURATION=0.694
LOG_FILE="$HOME/.cache/wallpaper_changer.log"
TMP_DIR=$(mktemp -d)
DEFAULT_GIF_SPEED=0.010
SLIDESHOW_STATUS="stopped" # stopped|running|paused

# Check if session is Xorg
is_xorg() { [[ "$XDG_SESSION_TYPE" == "x11" ]]; }

# Check if session is Wayland
is_wayland() { [[ "$XDG_SESSION_TYPE" == "wayland" ]]; }

# Logging function
log_message() {
	local level="$1"
	local message="$2"

	[[ ! -f "$LOG_FILE" ]] && touch "$LOG_FILE"
	echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] $message" >>"$LOG_FILE"
	[[ "$level" == "ERROR" ]] && return 1
}

get_battery_status() {
	local battery_status
	if [[ -f /sys/class/power_supply/BAT1/status ]]; then
		battery_status=$(</sys/class/power_supply/BAT1/status)
		echo "$battery_status"
	fi
}

# Determine wallpaper directory based on battery status
get_wallpaper_dir() {
	local battery_status
	battery_status=$(get_battery_status)

	case "$battery_status" in
	"Discharging")
		echo "$STATIC_WALLPAPER_DIR"
		;;
	"Charging")
		echo "$DYNAMIC_WALLPAPER_DIR"
		;;
	*)
		echo "$STATIC_WALLPAPER_DIR"
		;;
	esac
}

# Set wallpaper with different tools
set_wallpaper() {
	local tool="$1"
	local img="$2"

	log_message "INFO" "set_wallpaper: [img: $img tool: $tool]"

	if command -v "$tool" &>/dev/null; then
		case "$tool" in
		feh) feh --bg-fill "$img" ;;
		xwallpaper) xwallpaper --zoom "$img" ;;
		swaybg) swaybg -i "$img" ;;
		matugen) matugen image "$img" ;;
		wal) wal -ei "$img" ;;
		swww)
			[[ -z "$(pgrep -f swww-daemon)" ]] && swww-daemon &

			swww img "$img" --transition-type=any --transition-duration="$TRANSITION_DURATION"
			;;
		*) log_message "ERROR" "Unsupported wallpaper tool: $tool" ;;
		esac
		# shellcheck disable=SC2181
		if [[ $? -eq 0 ]]; then
			# TODO: temp disable feh logging
			[[ "$tool" != "feh" ]] && log_message "INFO" "Wallpaper set using $tool: $img"
			return 0
		else
			log_message "ERROR" "Failed to set wallpaper using $tool: $img"
		fi
	fi
	return 1
}

# Handle fallback wallpaper tools
set_wallpaper_fallback() {
	local img="$1"

	if is_wayland; then
		set_wallpaper "swww" "$img" ||
			set_wallpaper "wal" "$img" ||
			set_wallpaper "matugen" "$img" ||
			set_wallpaper "swaybg" "$img" ||
			log_message "ERROR" "No suitable wallpaper tool found for: $img"
	elif is_xorg; then
		set_wallpaper "wal" "$img" ||
			set_wallpaper "feh" "$img" ||
			log_message "ERROR" "No suitable wallpaper tool found for: $img"
	else
		log_message "ERROR" "Unsupported session type"
	fi
}

# Calculate GIF speed from metadata
calculate_gif_speed() {
	local gif="$1"
	local speed
	speed=$(identify -format "%T\n" "$gif" 2>/dev/null | awk '{sum += $1} END {if (NR > 0) print sum / NR / 100; else print ""}')
	if [[ -n "$speed" && $(echo "$speed > 0" | bc -l) -eq 1 ]]; then
		echo "$speed"
	else
		log_message "WARNING" "Unable to determine speed for $gif. Falling back to default: $DEFAULT_GIF_SPEED"
		echo "$DEFAULT_GIF_SPEED"
	fi
}

# Set gif as wallpaper in Wayland
animate_gif_wayland() {
	local gif="$1"

	pkill -f "mpvpaper"

	if [[ -n "$gif" ]]; then
		if mpvpaper ALL "$gif" -o loop -f; then
			log_message "INFO" "Starting mpvpaper for: $gif"
		elif set_wallpaper "$gif" "swww"; then
			log_message "INFO" "Falling back to swww for: $gif"
		else
			log_message "ERROR" "No suitable tool available for animated wallpaper: $gif"
		fi
	fi
}

# Set gif as wallpaper in Xorg
animate_gif_xorg() {
	local gif="$1"
	local hash
	hash=$(md5sum "$gif" | cut -f1 -d" ")
	local gif_dir="$TMP_DIR/$hash"

	# Extract frames if not already done
	if [[ ! -d "$gif_dir" ]]; then
		mkdir -p "$gif_dir"
		log_message "INFO" "Splitting frames for $gif..."
		magick "$gif" -coalesce "$gif_dir/frame_%04d.png"
	fi

	# Calculate GIF speed
	local speed
	speed=$(calculate_gif_speed "$gif")
	[[ -z "$speed" ]] && speed=$DEFAULT_GIF_SPEED

	# Animate the GIF frames as wallpaper
	while :; do
		for frame in "$gif_dir"/*.png; do
			set_wallpaper "$frame" "feh"
			sleep "$speed"
		done
	done
}

# Animate GIF wallpaper based on session type
animate_gif_wallpaper() {
	if is_wayland; then
		animate_gif_wayland "$1"
	elif is_xorg; then
		animate_gif_xorg "$1"
	else
		log_message "ERROR" "Unsupported session type"
	fi
}

# Main wallpaper loop
start_slideshow() {
	while true; do
		local dir
		dir=$(get_wallpaper_dir)
		if [[ ! -d "$dir" ]]; then
			log_message "ERROR" "Wallpaper directory not found: $dir"
			exit 1
		fi

		local img
		img=$(find "$dir" -type f | shuf -n 1)
		if [[ -z "$img" ]]; then
			log_message "ERROR" "No images found in $dir"
			sleep "$CHANGE_INTERVAL"
			continue
		fi

		if [[ "$img" == *.gif ]]; then
			log_message "INFO" "Animating GIF wallpaper: $img"
			animate_gif_wallpaper "$img"
		else
			log_message "INFO" "Setting static wallpaper: $img"
			set_wallpaper_fallback "$img"
		fi
		SLIDESHOW_STATUS="running"

		sleep "$CHANGE_INTERVAL"
	done &
	SLIDESHOW_PID=$!
}

# Log environment variables
log_env() {
	log_message "INFO" "----------------------------------------"
	log_message "INFO" "Environment:"
	log_message "INFO" "XDG_SESSION_TYPE: $XDG_SESSION_TYPE"
	log_message "INFO" "STATIC_WALLPAPER_DIR: $STATIC_WALLPAPER_DIR"
	log_message "INFO" "DYNAMIC_WALLPAPER_DIR: $DYNAMIC_WALLPAPER_DIR"
	log_message "INFO" "CHANGE_INTERVAL: $CHANGE_INTERVAL"
	log_message "INFO" "TRANSITION_DURATION: $TRANSITION_DURATION"
	log_message "INFO" "LOG_FILE: $LOG_FILE"
	log_message "INFO" "TMP_DIR: $TMP_DIR"
	log_message "INFO" "CURRENT WALLPAPER DIR: $(get_wallpaper_dir)"
	log_message "INFO" "----------------------------------------"
}

set_selected_wallpaper() {
	local wallpaper_dir
	wallpaper_dir="$(get_wallpaper_dir)"
	if [ -z "$wallpaper_dir" ]; then
		echo "Wallpaper directory not found."
		return 1
	fi

	# Use fzf to select a wallpaper
	local selected_wallpaper
	selected_wallpaper="$(find "$wallpaper_dir" -type f | fzf)"

	if [ -n "$selected_wallpaper" ]; then
		# Stop the slideshow and set the selected wallpaper
		stop_slideshow
		if [[ "$selected_wallpaper" == *.gif ]]; then
			log_message "INFO" "Animating GIF wallpaper: $selected_wallpaper"
			animate_gif_wallpaper "$selected_wallpaper"
		else
			log_message "INFO" "Setting static wallpaper: $selected_wallpaper"
			set_wallpaper_fallback "$selected_wallpaper"
		fi
		SLIDESHOW_STATUS="paused"
		log_message "INFO" "Selected wallpaper set: $selected_wallpaper"
	else
		log_message "WARNING" "No wallpaper selected."
	fi
}

stop_slideshow() {
	if [ "$SLIDESHOW_STATUS" != "stopped" ] && [ -n "$SLIDESHOW_PID" ] && kill -0 "$SLIDESHOW_PID" 2>/dev/null; then
		kill "$SLIDESHOW_PID"
		unset SLIDESHOW_PID
		SLIDESHOW_STATUS="stopped"
		log_message "INFO" "Slideshow stopped."
	else
		log_message "WARNING" "Slideshow not running, status: $SLIDESHOW_STATUS"
	fi
}

resume_slideshow() {
	log_message "INFO" "Resuming slideshow..."
	if [ "$SLIDESHOW_STATUS" == "paused" ]; then
		start_slideshow
		SLIDESHOW_STATUS="running"
	else
		log_message "WARNING" "Slideshow not paused, status: $SLIDESHOW_STATUS"
	fi
}

export -f set_selected_wallpaper stop_slideshow resume_slideshow

# Main function
main() {
	[[ -f "$LOG_FILE" ]] && rm -f "$LOG_FILE"

	log_env
	start_slideshow
}

main
