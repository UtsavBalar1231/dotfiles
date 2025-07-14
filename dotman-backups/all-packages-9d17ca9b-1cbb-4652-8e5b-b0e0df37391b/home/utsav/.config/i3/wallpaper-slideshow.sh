#!/usr/bin/env bash
# shellcheck disable=SC2181

# Configuration
BATTERY_THRESHOLD=25
STATIC_WALLPAPER_DIR="$HOME/Pictures/wallpapers"
DYNAMIC_WALLPAPER_DIR="$HOME/Pictures/wallpapers/gifs"
CHANGE_INTERVAL=2
TRANSITION_DURATION=0.694
LOG_FILE="$HOME/.cache/wallpaper_changer.log"
TMP_DIR=$(mktemp -d)
DEFAULT_GIF_SPEED=0.010

# Check if session is Xorg
is_xorg() {
	[[ "$XDG_SESSION_TYPE" == "x11" ]]
}

# Check if session is Wayland
is_wayland() {
	[[ "$XDG_SESSION_TYPE" == "wayland" ]]
}

# Logging function
log_message() {
	local level="$1"
	local message="$2"

	if [[ ! -f "$LOG_FILE" ]]; then
		touch "$LOG_FILE"
	fi

	echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] $message" >>"$LOG_FILE"
	if [[ "$level" == "ERROR" ]]; then
		return 1
	fi
}

# Determine wallpaper directory based on battery status
get_wallpaper_dir() {
	local battery_level
	if [[ -f /sys/class/power_supply/BAT1/capacity ]]; then
		battery_level=$(</sys/class/power_supply/BAT1/capacity)
		if [[ "$battery_level" -lt $BATTERY_THRESHOLD ]]; then
			echo "$STATIC_WALLPAPER_DIR"
			return
		fi
	fi
	echo "$DYNAMIC_WALLPAPER_DIR"
}

# Set wallpaper with mpvpaper
set_wallpaper_mpvpaper() {
	local img="$1"
	if command -v mpvpaper &>/dev/null; then
		# Ensure no other mpvpaper instance is running
		pkill -f mpvpaper 2>/dev/null
		mpvpaper ALL "$img" -o loop &
		if [[ $? -eq 0 ]]; then
			log_message "INFO" "Wallpaper set using mpvpaper: $img"
			return 0
		else
			log_message "ERROR" "Failed to set wallpaper using mpvpaper: $img"
		fi
	fi
	return 1
}

# Set wallpaper with different tools
set_wallpaper() {
	local img="$1"
	local tool="$2"
	if command -v "$tool" &>/dev/null; then
		case "$tool" in
		feh) feh --bg-fill "$img" ;;
		xwallpaper) xwallpaper --zoom "$img" ;;
		swaybg) swaybg -i "$img" ;;
		matugen) matugen image "$img" ;;
		wal) wal -ei "$img" ;;
		swww) swww --transition-type any --transition-duration "$TRANSITION_DURATION" "$img" ;;
		*) log_message "ERROR" "Unsupported wallpaper tool: $tool" ;;
		esac
		if [[ $? -eq 0 ]]; then
			if [[ "$tool" != "feh" ]]; then
				log_message "INFO" "Wallpaper set using $tool: $img"
			fi
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
		set_wallpaper "swww" img "$img" --transition-type any --transition-duration "$TRANSITION_DURATION" ||
			set_wallpaper "wal" -ei "$img" ||
			set_wallpaper "matugen" image "$img" ||
			set_wallpaper "swaybg" -i "$img" ||
			log_message "ERROR" "No suitable wallpaper tool found for: $img"
	elif is_xorg; then
		set_wallpaper "wal" -ei "$img" ||
			set_wallpaper "feh" --bg-fill "$img" ||
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
	set_wallpaper_mpvpaper "$gif" || set_wallpaper "swww"
	if [[ $? -ne 0 ]]; then
		log_message "ERROR" "Failed to set wallpaper using mpvpaper or swww: $gif"
		exit 1
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
	if [[ -z "$speed" ]]; then
		speed=$DEFAULT_GIF_SPEED
	fi

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
wallpaper_loop() {
	local dir="$1"
	while true; do
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
			wait
		else
			log_message "INFO" "Setting static wallpaper: $img"
			set_wallpaper_fallback "$img"
		fi
		sleep "$CHANGE_INTERVAL"
	done
}

# Log environment variables
log_env() {
	log_message "INFO" "----------------------------------------"
	log_message "INFO" "Environment:"
	log_message "INFO" "XDG_SESSION_TYPE: $XDG_SESSION_TYPE"
	log_message "INFO" "BATTERY_THRESHOLD: $BATTERY_THRESHOLD"
	log_message "INFO" "STATIC_WALLPAPER_DIR: $STATIC_WALLPAPER_DIR"
	log_message "INFO" "DYNAMIC_WALLPAPER_DIR: $DYNAMIC_WALLPAPER_DIR"
	log_message "INFO" "CHANGE_INTERVAL: $CHANGE_INTERVAL"
	log_message "INFO" "TRANSITION_DURATION: $TRANSITION_DURATION"
	log_message "INFO" "LOG_FILE: $LOG_FILE"
	log_message "INFO" "TMP_DIR: $TMP_DIR"
	log_message "INFO" "----------------------------------------"
}

# Main function
main() {
	local wallpaper_dir
	wallpaper_dir=$(get_wallpaper_dir)

	if [[ ! -d "$wallpaper_dir" ]]; then
		log_message "ERROR" "Wallpaper directory not found: $wallpaper_dir"
		exit 1
	fi

	log_env 

	wallpaper_loop "$wallpaper_dir"
}

main
