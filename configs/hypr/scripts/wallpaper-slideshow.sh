#!/usr/bin/env bash

# ========================
# Configuration & State
# ========================

declare -gr BATTERY_SYSFS="/sys/class/power_supply/BAT1/status"
declare -ga TOOLS=("feh" "xwallpaper" "swaybg" "matugen" "swww" "mpvpaper" "swww-daemon" "viu" "chafa")
declare -gA PATHS=(
	[static]="${HOME}/Pictures/wallpapers"
	[dynamic]="${HOME}/Pictures/wallpapers/gifs"
	[log]="${HOME}/.cache/wallpaper_changer.log"
	[state_dir]="${HOME}/.cache/wallpaper-slideshow"
)

declare -gA DURATION=(
	[change]=540
	[transition]=0.694
	[gif_speed]=0.010
)

declare -gA STATE=(
	[status]="stopped"
	[battery]="$([[ -f "${BATTERY_SYSFS}" ]] && tr '[:upper:]' '[:lower:]' <"${BATTERY_SYSFS}" || echo "unknown")"
	[pid]=""
	[animation_pid]=""
	[tool]=""
	[current_wallpaper]=""
)

# ========================
# Core Functions
# ========================

create_state_paths() {
	if [[ ! -d "${PATHS[state_dir]}" ]]; then
		mkdir -p "${PATHS[state_dir]}" || {
			echo "Failed to create state directory"
			exit 1
		}
	fi

	if [[ ! -f "${PATHS[log]}" ]]; then
		touch "${PATHS[log]}" || {
			echo "Failed to create log file"
			exit 1
		}
	fi
}

init() {
	create_state_paths || {
		echo "Failed to initialize - check permissions on ${PATHS[state_dir]}"
		exit 1
	}
	get_pids
}

cleanup() {
	rm -rf "${PATHS[state_dir]}"/*.pid
}

log() {
	local level="$1" msg="$2"
	[[ ! -e "${PATHS[log]}" ]] && touch "${PATHS[log]}"
	printf "%(%Y-%m-%d %H:%M:%S)T [%s] %s\n" -1 "${level}" "${msg}" >>"${PATHS[log]}" 2>/dev/null || {
		printf "[%s] %s\n" "${level}" "${msg}" >&2
	}
}

# ========================
# System Checks
# ========================

is_xorg() { [[ "${XDG_SESSION_TYPE}" == "x11" ]]; }
is_wayland() { [[ "${XDG_SESSION_TYPE}" == "wayland" ]]; }

# ========================
# Wallpaper Management
# ========================

set_wall() {
	local tool="$1" img="$2"
	command -v "${tool}" || {
		log ERROR "${tool} not found"
		return 1
	}

	case "${tool}" in
	"feh") feh --bg-fill "${img}" ;;
	"xwallpaper") xwallpaper --zoom "${img}" ;;
	"swaybg") swaybg -i "${img}" ;;
	"matugen") matugen image "${img}" ;;
	"wal") wal -ei "${img}" ;;
	"swww")
		! pgrep -f "swww-daemon" &>/dev/null && swww-daemon &>/dev/null && sleep 0.5
		swww img "${img}" --transition-duration="${DURATION[transition]}"
		;;
	*)
		log ERROR "Unsupported tool: ${tool}"
		return 1
		;;
	esac && {
		STATE[tool]="${tool}"
		# TEMP: disable feh logging for dynamic wallpapers (spams log file)
		[[ "$tool" != "feh" || "${STATE[battery]}" == "discharging" ]] && set_current_wallpaper "${img}"
	}
}

wallpaper_dir() {
	case "${STATE[battery]}" in
	"discharging") echo "${PATHS[static]}" ;;
	"charging" | "full") echo "${PATHS[dynamic]}" ;;
	*) echo "${PATHS[static]}" ;;
	esac
}

# ========================
# GIF Handling
# ========================

gif_speed() {
	local gif="$1"
	identify -format "%T\n" "${gif}" 2>/dev/null |
		awk '{sum+=$1} END{printf "%.3f", (sum/NR)/100}' ||
		echo "${DURATION[gif_speed]}"
}

set_gif() {
	local gif="$1"
	[[ -f "${gif}" ]] || {
		log ERROR "GIF not found: ${gif}"
		return 1
	}

	# Clear previous animation PID
	set_animation_pid ""

	if is_wayland; then
		kill_tools
		mpvpaper -p "-o loop" ALL "${gif}" >/dev/null &
		set_animation_pid $!
		disown $!
	else
		local hash
		hash="$(md5sum "${gif}" | cut -d' ' -f1)"
		local frame_dir="${PATHS[state_dir]}/${hash}"

		mkdir -p "${frame_dir}"
		magick "${gif}" -coalesce "${frame_dir}/frame_%04d.png" || return

		(
			while :; do for frame in "${frame_dir}"/*.png; do
				set_wall feh "${frame}"
				sleep "$(gif_speed "${gif}")"
			done; done
		) &
		STATE[animation_pid]="$!"
	fi

	set_current_wallpaper "${gif}"
	log INFO "Animating GIF: ${gif} (PID: ${STATE[animation_pid]})"
}

# ========================
# Fallback Mechanism
# ========================

set_wall_fallback() {
	local img="${1}"
	local success=0

	if is_wayland; then
		set_wall "swww" "${img}" ||
			set_wall "wal" "${img}" ||
			set_wall "matugen" "${img}" ||
			set_wall "swaybg" "${img}" && success=1
	else
		set_wall "wal" "${img}" ||
			set_wall "feh" "${img}" ||
			set_wall "xwallpaper" "${img}" && success=1
	fi

	if ((success)); then
		# Clear animation PID when static wallpaper is set
		set_animation_pid ""
		return 0
	else
		log ERROR "All wallpaper tools failed for: ${img}"
		return 1
	fi
}

# ========================
# Slideshow Control
# ========================

slideshow() {
	log DEBUG "Starting slideshow"
	[[ "$(get_status)" == "running" ]] && {
		log WARNING "Slideshow already running"
		return
	}
	stop
	set_status running

	(
		while [[ -f "${PATHS[state_dir]}/status" && "$(<"${PATHS[state_dir]}/status")" == "running" ]]; do
			local dir img

			dir="$(wallpaper_dir)"
			[[ -d "${dir}" ]] || {
				log ERROR "Missing directory: ${dir}"
				sleep "${DURATION[change]}"
				continue
			}

			img="$(find "${dir}" -type f \( -iname "*.jpg" -o -iname "*.jpeg" \
				-o -iname "*.png" -o -iname "*.gif" \) | shuf -n1)"
			[[ "${img}" ]] || {
				log WARNING "No images found in ${dir}"
				sleep "${DURATION[change]}"
				continue
			}

			if [[ "${img}" == *.gif ]]; then
				set_gif "${img}"
			else
				set_wall_fallback "${img}"
			fi
			sleep "${DURATION[change]}"
		done
	) >/dev/null 2>&1 &

	set_pid $!
	disown $!
	log INFO "Slideshow started (PID: ${STATE[pid]})"
}

kill_tools() {
	for tool in "${TOOLS[@]}"; do
		if pgrep -f "${tool}" >/dev/null; then
			pkill -f "${tool}"
			log INFO "Killed ${tool}"
		fi
	done
}

stop() {
	get_pids # Load saved PIDs

	# Kill main process
	[[ -n "${STATE[pid]}" ]] && {
		kill -TERM "${STATE[pid]}" 2>/dev/null
		rm -f "${PATHS[state_dir]}/pid"
	}

	# Kill animation process
	[[ -n "${STATE[animation_pid]}" ]] && {
		kill -TERM "${STATE[animation_pid]}" 2>/dev/null
		rm -f "${PATHS[state_dir]}/animation_pid"
	}

	[[ -f "${PATHS[state_dir]}/current_wallpaper" ]] && rm -f "${PATHS[state_dir]}/current_wallpaper"

	kill_tools
	set_status stopped
	log INFO "Slideshow stopped"
}

pause() {
	get_pids

	[[ "$(get_status)" != "running" ]] && {
		log ERROR "Cannot pause - not running"
		return 1
	}
	[[ -n "${STATE[pid]}" ]] && kill -STOP "${STATE[pid]}"
	[[ -n "${STATE[animation_pid]}" ]] && kill -STOP "${STATE[animation_pid]}"
	set_status paused
	log INFO "Slideshow paused"
}

resume() {
	get_pids

	[[ "$(get_status)" != "paused" ]] && {
		log ERROR "Cannot resume - not paused"
		return 1
	}
	[[ -n "${STATE[pid]}" ]] && kill -CONT "${STATE[pid]}"
	[[ -n "${STATE[animation_pid]}" ]] && kill -CONT "${STATE[animation_pid]}"
	set_status running
	log INFO "Slideshow resumed"
}

set_status() {
	STATE[status]="$1"
	echo "${STATE[status]}" >"${PATHS[state_dir]}/status"
	log INFO "Slideshow status updated: $(get_status)"
}

set_pid() {
	echo "$1" >"${PATHS[state_dir]}/pid"
	STATE[pid]="$1"
}

set_animation_pid() {
	echo "$1" >"${PATHS[state_dir]}/animation_pid"
	STATE[animation_pid]="$1"
}

get_pids() {
	[[ -f "${PATHS[state_dir]}/pid" ]] && STATE[pid]=$(<"${PATHS[state_dir]}/pid")
	[[ -f "${PATHS[state_dir]}/animation_pid" ]] && STATE[animation_pid]=$(<"${PATHS[state_dir]}/animation_pid")
}

get_status() {
	[[ -f "${PATHS[state_dir]}/status" ]] &&
		echo "$(<"${PATHS[state_dir]}/status")" ||
		echo "stopped"
}

set_current_wallpaper() {
	STATE[current_wallpaper]="${1}"
	echo "${STATE[current_wallpaper]}" >"${PATHS[state_dir]}/current_wallpaper"
	log INFO "Current wallpaper: ${STATE[current_wallpaper]}"
}

get_wallpaper() {
	[[ -f "${PATHS[state_dir]}/current_wallpaper" ]] &&
		echo "Current wallpaper: $(<"${PATHS[state_dir]}/current_wallpaper")" ||
		echo "Current wallpaper: none"
}

# ========================
# Manual Wallpaper Selection
# ========================

manual_set() {
	local wall_dir

	wall_dir="$(wallpaper_dir)"
	[[ -d "${wall_dir}" ]] || {
		log ERROR "Wallpaper directory not found: ${wall_dir}"
		return 1
	}

	! command -v fzf >/dev/null && {
		log ERROR "fzf required for manual selection"
		return 1
	}

	local preview_cmd
	if [[ -n $KITTY_WINDOW_ID && "${STATE[battery]}" == "discharging" ]]; then
		preview_cmd="kitty icat --clear --transfer-mode=memory --unicode-placeholder --stdin=no --place=\${FZF_PREVIEW_COLUMNS}x\${FZF_PREVIEW_LINES}@0x0 {}"
	elif command -v chafa >/dev/null; then
		preview_cmd="chafa --animate off --clear -s \${FZF_PREVIEW_COLUMNS}x\${FZF_PREVIEW_LINES} {}"
	elif command -v viu >/dev/null; then
		preview_cmd="viu {}"
	else
		log WARNING "No image preview tool (kitty icat, viu, or chafa) is installed. Preview will not be available."
		preview_cmd="echo 'Preview not available {}'"
	fi

	local selected
	selected="$(find "${wall_dir}" -type f \( -iname "*.jpg" -o -iname "*.jpeg" \
		-o -iname "*.png" -o -iname "*.gif" \) | fzf --preview "${preview_cmd}" --preview-window=bottom:75%:wrap)"

	[[ -z "${selected}" ]] && {
		echo "No wallpaper selected. Exiting..."
		return
	}

	log INFO "Manual wallpaper selection: ${selected}"

	# Stop any existing slideshow or manual set process
	stop

	# Set the wallpaper
	if [[ "${selected}" == *.gif ]]; then
		set_gif "${selected}"
	else
		set_wall_fallback "${selected}"
	fi

	set_status running
	log INFO "Manual wallpaper set started (PID: ${STATE[pid]})"
}

# ========================
# Environment Logger
# ========================

log_environment() {
	printf "\033[1;36m========================================\n"
	printf "WALLPAPER MANAGER STATUS\n"
	printf "========================================\033[0m\n\n"

	printf "\033[1;33m%-20s\033[0m %s\n" "Session Type:" "${XDG_SESSION_TYPE:-none}"
	printf "\033[1;33m%-20s\033[0m %s\n" "Battery Status:" "${STATE[battery]:-none}"
	printf "\033[1;33m%-20s\033[0m %s\n" "Current Status:" "${STATE[status]:-none}"
	printf "\033[1;33m%-20s\033[0m %s\n" "Current Wallpaper:" "${STATE[current_wallpaper]:-none}"

	printf "\n\033[1;36m========================================\n"
	printf "PROCESSES\n"
	printf "========================================\033[0m\n"
	printf "\033[1;33m%-20s\033[0m %s\n" "Main PID:" "${STATE[pid]:-none}"
	printf "\033[1;33m%-20s\033[0m %s\n" "Animation PID:" "${STATE[animation_pid]:-none}"
	# Check for active tools
	local active_tools=()
	for tool in "${TOOLS[@]}"; do
		if pgrep -x "$tool" >/dev/null; then
			active_tools+=("$tool")
		fi
	done
	printf "\033[1;33m%-20s\033[0m %s\n" "Active Tools:" "${active_tools[*]:-none}"

	printf "\n\033[1;36m========================================\n"
	printf "CONFIGURATION\n"
	printf "========================================\033[0m\n"
	printf "\033[1;33m%-20s\033[0m %s\n" "Static Directory:" "${PATHS[static]:-none}"
	printf "\033[1;33m%-20s\033[0m %s\n" "Dynamic Directory:" "${PATHS[dynamic]:-none}"
	printf "\033[1;33m%-20s\033[0m %d\n" "Change Interval:" "${DURATION[change]:-0}"
	printf "\033[1;33m%-20s\033[0m %.3f\n" "Transition Duration:" "${DURATION[transition]:-0}"

	# Recent Logs
	if [[ -f "${PATHS[log]}" ]]; then
		printf "\n\033[1;36m========================================\n"
		printf "RECENT LOGS (last 5 entries)\n"
		printf "========================================\033[0m\n"
		tail -n5 "${PATHS[log]}" || printf "%s\n" "none"
	fi
}

# ========================
# Time Until Next Change
# ========================

time_until_next_change() {
	local log_file="${PATHS[log]}" status_file="${PATHS[state_dir]}/status"

	# Check slideshow status
	[[ ! -f "$status_file" || "$(cat "$status_file")" != "running" ]] && {
		echo "Slideshow not active"
		return
	}

	# Get last change timestamp
	local last_ts
	last_ts=$(tac "$log_file" | awk '
        /Set wallpaper:|Animating GIF:/ {
            split($1, date_parts, "-")
            split($2, time_parts, ":")
            ts = mktime(date_parts[1] " " \
                        date_parts[2] " " \
                        date_parts[3] " " \
                        time_parts[1] " " \
                        time_parts[2] " " \
                        time_parts[3])
            print ts
            exit
        }
    ')

	local current_time
	current_time=$(date +%s)
	local remaining=$((DURATION[change] - (current_time - last_ts)))
	((remaining < 0)) && remaining=0

	printf "Next change in: %d min %d secs\n" $((remaining / 60)) $((remaining % 60))
}

# ========================
# Command Line Interface
# ========================

usage() {

	printf "Usage: %s {option}\n" "$0"
	printf "Options:\n"
	printf "  env     Log environment information\n"
	printf "  pause   Pause the wallpaper slideshow\n"
	printf "  resume  Resume the wallpaper slideshow\n"
	printf "  set     Manually set a wallpaper\n"
	printf "  start   Start the wallpaper slideshow\n"
	printf "  status  Get the current status of the slideshow\n"
	printf "  stop    Stop the wallpaper slideshow\n"
	printf "  time    Get the time until the next wallpaper change\n"
	printf "  current  Get the current wallpaper\n"
	printf "\n"
}

# ========================
# Main Execution
# ========================
init
[[ "$#" -ne 1 ]] && usage && exit 1

case "$1" in
env) log_environment ;;
pause) pause ;;
resume) resume ;;
set) manual_set ;;
start) slideshow ;;
status)
	status=$(get_status)
	printf "Slideshow status: %s\n" "${status}"
	;;
stop) stop ;;
time) time_until_next_change ;;
current) get_wallpaper ;;
*)
	usage && exit 1
	;;
esac
