#!/usr/bin/env bash
# hypr-wallshow.sh - Professional Wallpaper Manager for Wayland/X11
# Version: 2.0.0
# License: MIT
# Requires: bash 5.0+, jq, flock

set -euo pipefail
IFS=$'\n\t'

# ============================================================================
# CONSTANTS & CONFIGURATION
# ============================================================================

declare -r SCRIPT_NAME="hypr-wallshow"
declare -r VERSION="2.0.0"
declare -r SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
declare -r SCRIPT_DIR="$(dirname "${SCRIPT_PATH}")"

# XDG Base Directory compliance
declare -r XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
declare -r XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
declare -r XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
declare -r XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

# Application directories
declare -r CONFIG_DIR="${XDG_CONFIG_HOME}/${SCRIPT_NAME}"
declare -r STATE_DIR="${XDG_STATE_HOME}/${SCRIPT_NAME}"
declare -r CACHE_DIR="${XDG_CACHE_HOME}/${SCRIPT_NAME}"
declare -r RUNTIME_DIR="${XDG_RUNTIME_DIR}/${SCRIPT_NAME}"

# Critical files
declare -r CONFIG_FILE="${CONFIG_DIR}/config.json"
declare -r STATE_FILE="${STATE_DIR}/state.json"
declare -r LOCK_FILE="${RUNTIME_DIR}/instance.lock"
declare -r SOCKET_FILE="${RUNTIME_DIR}/control.sock"
declare -r PID_FILE="${RUNTIME_DIR}/daemon.pid"
declare -r LOG_FILE="${STATE_DIR}/wallpaper.log"

# Default configuration
declare -r DEFAULT_CONFIG='{
  "wallpaper_dirs": {
    "static": "~/Pictures/wallpapers",
    "animated": "~/Pictures/wallpapers/animated"
  },
  "intervals": {
    "change_seconds": 300,
    "transition_ms": 300,
    "gif_frame_ms": 50
  },
  "behavior": {
    "shuffle": true,
    "exclude_patterns": ["*.tmp", ".*"],
    "battery_optimization": true,
    "max_cache_size_mb": 500,
    "max_log_size_kb": 1024,
    "debug": false
  },
  "tools": {
    "preferred_static": "auto",
    "preferred_animated": "auto",
    "fallback_chain": ["swww", "swaybg", "feh", "xwallpaper"]
  }
}'

# Exit codes
declare -ri E_SUCCESS=0
declare -ri E_GENERAL=1
declare -ri E_USAGE=2
declare -ri E_NOPERM=3
declare -ri E_NOTFOUND=4
declare -ri E_LOCKED=5
declare -ri E_CONFIG=6
declare -ri E_STATE=7
declare -ri E_DEPENDENCY=8

# Logging levels
declare -ri LOG_ERROR=0
declare -ri LOG_WARN=1
declare -ri LOG_INFO=2
declare -ri LOG_DEBUG=3

# Global state (minimal, most state in JSON)
declare -g LOCK_FD=""
declare -g LOG_LEVEL="${LOG_INFO}"
declare -g IS_DAEMON=false
declare -g CLEANUP_DONE=false

# ============================================================================
# INITIALIZATION & CLEANUP
# ============================================================================

init_directories() {
    local dir
    for dir in "${CONFIG_DIR}" "${STATE_DIR}" "${CACHE_DIR}" "${RUNTIME_DIR}"; do
        if [[ ! -d "${dir}" ]]; then
            mkdir -p "${dir}" || die "Failed to create directory: ${dir}"
            chmod 700 "${dir}"
        fi
    done
}

init_config() {
    if [[ ! -f "${CONFIG_FILE}" ]]; then
        log_info "Creating default configuration at ${CONFIG_FILE}"
        echo "${DEFAULT_CONFIG}" | jq '.' > "${CONFIG_FILE}" || die "Failed to create config file"
        chmod 600 "${CONFIG_FILE}"
    fi

    # Validate config
    if ! jq -e '.' "${CONFIG_FILE}" >/dev/null 2>&1; then
        die "Invalid JSON in config file: ${CONFIG_FILE}"
    fi
}

init_state() {
    local default_state='{
        "version": "'"${VERSION}"'",
        "status": "stopped",
        "current_wallpaper": null,
        "history": [],
        "stats": {
            "changes_count": 0,
            "last_change": null,
            "uptime_seconds": 0
        },
        "cache": {
            "file_list": [],
            "last_scan": null
        },
        "processes": {
            "main_pid": null,
            "animation_pid": null
        }
    }'

    if [[ ! -f "${STATE_FILE}" ]]; then
        echo "${default_state}" | jq '.' > "${STATE_FILE}" || die "Failed to create state file"
        chmod 600 "${STATE_FILE}"
    else
        # Validate existing state
        if ! jq -e '.' "${STATE_FILE}" >/dev/null 2>&1; then
            log_warn "Corrupted state file, recreating..."
            echo "${default_state}" | jq '.' > "${STATE_FILE}"
        fi
    fi
}

cleanup() {
    if [[ "${CLEANUP_DONE}" == "true" ]]; then
        return
    fi
    CLEANUP_DONE=true

    log_debug "Running cleanup..."

    # Update state before exit
    if [[ -f "${STATE_FILE}" ]]; then
        update_state '.status = "stopped" | .processes.main_pid = null'
    fi

    # Release lock
    if [[ -n "${LOCK_FD}" ]]; then
        flock -u "${LOCK_FD}" 2>/dev/null || true
        exec {LOCK_FD}>&- 2>/dev/null || true
    fi

    # Clean runtime files
    rm -f "${SOCKET_FILE}" "${PID_FILE}" 2>/dev/null || true

    log_info "Cleanup completed"
}

# ============================================================================
# LOGGING
# ============================================================================

log() {
    local level=$1
    local message=$2
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    local level_str
    case ${level} in
        ${LOG_ERROR}) level_str="ERROR" ;;
        ${LOG_WARN})  level_str="WARN " ;;
        ${LOG_INFO})  level_str="INFO " ;;
        ${LOG_DEBUG}) level_str="DEBUG" ;;
        *) level_str="UNKN " ;;
    esac

    if [[ ${level} -le ${LOG_LEVEL} ]]; then
        local log_line="[${timestamp}] [${level_str}] ${message}"

        # Console output - always to stderr to avoid polluting function output
        if [[ "${IS_DAEMON}" == "false" ]]; then
            echo "${log_line}" >&2
        fi

        # File output
        if [[ -f "${LOG_FILE}" ]]; then
            echo "${log_line}" >> "${LOG_FILE}"

            # Rotate if needed
            local max_size
            max_size=$(get_config '.behavior.max_log_size_kb' '1024')
            local current_size
            current_size=$(du -k "${LOG_FILE}" | cut -f1)

            if [[ ${current_size} -gt ${max_size} ]]; then
                mv "${LOG_FILE}" "${LOG_FILE}.old"
                touch "${LOG_FILE}"
            fi
        fi
    fi
}

log_error() { log ${LOG_ERROR} "$1"; }
log_warn()  { log ${LOG_WARN} "$1"; }
log_info()  { log ${LOG_INFO} "$1"; }
log_debug() { log ${LOG_DEBUG} "$1"; }

die() {
    log_error "$1"
    exit "${2:-${E_GENERAL}}"
}

# ============================================================================
# INSTANCE LOCKING
# ============================================================================

acquire_lock() {
    local timeout=${1:-0}

    # Create lock file if it doesn't exist
    touch "${LOCK_FILE}" || die "Cannot create lock file" ${E_NOPERM}

    # Open lock file and get file descriptor
    exec {LOCK_FD}<>"${LOCK_FILE}"

    # Try to acquire exclusive lock
    if [[ ${timeout} -gt 0 ]]; then
        if ! flock -w "${timeout}" -x "${LOCK_FD}"; then
            log_error "Another instance is running (timeout after ${timeout}s)"
            exit ${E_LOCKED}
        fi
    else
        if ! flock -n -x "${LOCK_FD}"; then
            log_error "Another instance is running"
            exit ${E_LOCKED}
        fi
    fi

    # Write our PID to lock file
    echo $$ > "${LOCK_FILE}"

    log_debug "Lock acquired (PID: $$)"
    return 0
}

release_lock() {
    if [[ -n "${LOCK_FD}" ]]; then
        flock -u "${LOCK_FD}" 2>/dev/null || true
        exec {LOCK_FD}>&- 2>/dev/null || true
        LOCK_FD=""
        log_debug "Lock released"
    fi
}

check_instance() {
    if [[ -f "${PID_FILE}" ]]; then
        local pid
        pid=$(<"${PID_FILE}")
        if kill -0 "${pid}" 2>/dev/null; then
            return 0  # Instance is running
        else
            log_debug "Stale PID file found, cleaning up"
            rm -f "${PID_FILE}"
        fi
    fi
    return 1  # No instance running
}

# ============================================================================
# STATE MANAGEMENT
# ============================================================================

read_state() {
    local query="${1:-.}"

    if [[ ! -f "${STATE_FILE}" ]]; then
        init_state
    fi

    jq -r "${query}" "${STATE_FILE}" 2>/dev/null || {
        log_error "Failed to read state with query: ${query}"
        echo "null"
    }
}

update_state() {
    local update="$1"
    local temp_file
    temp_file=$(mktemp "${STATE_FILE}.XXXXXX")

    if jq "${update}" "${STATE_FILE}" > "${temp_file}" 2>/dev/null; then
        mv -f "${temp_file}" "${STATE_FILE}"
        chmod 600 "${STATE_FILE}"
        log_debug "State updated: ${update}"
    else
        rm -f "${temp_file}"
        log_error "Failed to update state: ${update}"
        return 1
    fi
}

update_state_atomic() {
    local max_retries=5
    local retry=0

    while [[ ${retry} -lt ${max_retries} ]]; do
        if update_state "$1"; then
            return 0
        fi
        retry=$((retry + 1))
        sleep 0.1
    done

    log_error "Failed to update state after ${max_retries} retries"
    return 1
}

add_to_history() {
    local wallpaper="$1"
    local max_history=100

    update_state_atomic "
        .history = ([\"${wallpaper}\"] + .history | unique | .[0:${max_history}]) |
        .stats.last_change = \"$(date -Iseconds)\" |
        .stats.changes_count += 1
    "
}

# ============================================================================
# CONFIGURATION MANAGEMENT
# ============================================================================

get_config() {
    local query="$1"
    local default="${2:-}"

    if [[ ! -f "${CONFIG_FILE}" ]]; then
        init_config
    fi

    local result
    result=$(jq -r "${query}" "${CONFIG_FILE}" 2>/dev/null || echo "null")

    if [[ "${result}" == "null" || -z "${result}" ]]; then
        echo "${default}"
    else
        echo "${result}"
    fi
}

reload_config() {
    log_info "Reloading configuration..."

    # Validate config file
    if ! jq -e '.' "${CONFIG_FILE}" >/dev/null 2>&1; then
        log_error "Invalid configuration file, keeping current config"
        return 1
    fi

    # Update log level if changed
    if [[ "$(get_config '.behavior.debug' 'false')" == "true" ]]; then
        LOG_LEVEL=${LOG_DEBUG}
    else
        LOG_LEVEL=${LOG_INFO}
    fi

    log_info "Configuration reloaded"
    return 0
}

# ============================================================================
# PATH VALIDATION & SECURITY
# ============================================================================

validate_path() {
    local path="$1"
    local base_dir="$2"

    # Expand tilde and resolve path
    path="${path/#\~/$HOME}"
    local resolved
    resolved=$(readlink -f "${path}" 2>/dev/null) || return 1

    # Ensure path exists
    [[ -e "${resolved}" ]] || return 1

    # If base_dir provided, ensure path is within it
    if [[ -n "${base_dir}" ]]; then
        base_dir="${base_dir/#\~/$HOME}"
        base_dir=$(readlink -f "${base_dir}" 2>/dev/null) || return 1

        # Check if resolved path starts with base_dir
        [[ "${resolved}" == "${base_dir}"/* || "${resolved}" == "${base_dir}" ]] || return 1
    fi

    echo "${resolved}"
    return 0
}

sanitize_filename() {
    local filename="$1"
    # Remove path components and dangerous characters
    basename "${filename}" | tr -d '\0' | sed 's/[^a-zA-Z0-9._-]/_/g'
}

# ============================================================================
# PROCESS MANAGEMENT
# ============================================================================

daemonize() {
    log_info "Starting in daemon mode..."

    # Check if already running
    if check_instance; then
        die "Daemon already running" ${E_LOCKED}
    fi

    # Fork and exit parent
    if [[ "${IS_DAEMON}" == "false" ]]; then
        IS_DAEMON=true

        # Redirect output
        exec 1>"${STATE_DIR}/daemon.out"
        exec 2>"${STATE_DIR}/daemon.err"
        exec 0</dev/null

        # Start daemon in background
        (
            # Create new session
            setsid 2>/dev/null || true

            # Write PID
            echo $$ > "${PID_FILE}"

            # Set up signal handlers
            trap 'handle_signal TERM' TERM
            trap 'handle_signal INT' INT
            trap 'handle_signal HUP' HUP
            trap 'cleanup' EXIT

            # Run main loop
            main_loop
        ) &

        local daemon_pid=$!
        log_info "Daemon started with PID: ${daemon_pid}"
        echo "Daemon started with PID: ${daemon_pid}"
        exit 0
    fi
}

handle_signal() {
    local signal="$1"
    log_info "Received signal: ${signal}"

    case "${signal}" in
        TERM|INT)
            log_info "Shutting down gracefully..."
            update_state '.status = "stopping"'
            cleanup
            exit 0
            ;;
        HUP)
            log_info "Reloading configuration..."
            reload_config
            ;;
        *)
            log_warn "Unhandled signal: ${signal}"
            ;;
    esac
}

# ============================================================================
# WALLPAPER DISCOVERY & CACHING
# ============================================================================

discover_wallpapers() {
    local dir="$1"
    local cache_key="$2"
    local force_refresh="${3:-false}"

    # Validate directory
    dir=$(validate_path "${dir}" "") || {
        log_error "Invalid directory: ${dir}"
        return 1
    }

    # Check cache
    local cached_list
    local last_scan
    cached_list=$(jq -r ".cache.${cache_key}.files // []" "${STATE_FILE}" 2>/dev/null || echo "[]")
    last_scan=$(jq -r ".cache.${cache_key}.last_scan // 0" "${STATE_FILE}" 2>/dev/null || echo "0")

    local now
    now=$(date +%s)
    local cache_age=$((now - last_scan))
    local max_age=3600  # 1 hour

    if [[ "${force_refresh}" == "false" && ${cache_age} -lt ${max_age} && "${cached_list}" != "[]" ]]; then
        log_debug "Using cached wallpaper list for ${cache_key}"
        echo "${cached_list}"
        return 0
    fi

    log_info "Scanning directory: ${dir}"

    # Build exclude pattern arguments as an array
    local -a exclude_args=()
    local exclude_patterns
    # Get exclude patterns as a JSON array then extract values
    exclude_patterns=$(jq -r '.behavior.exclude_patterns[]?' "${CONFIG_FILE}" 2>/dev/null || echo "")

    if [[ -n "${exclude_patterns}" ]]; then
        while IFS= read -r pattern; do
            if [[ -n "${pattern}" ]]; then
                exclude_args+=("!" "-name" "${pattern}")
            fi
        done <<< "${exclude_patterns}"
    fi

    # Execute find and build JSON array
    local files_json="[]"
    local count=0

    while IFS= read -r file; do
        [[ -z "${file}" ]] && continue
        # Escape special characters for JSON
        local escaped_file
        escaped_file=$(printf '%s' "${file}" | jq -Rs .)
        files_json=$(echo "${files_json}" | jq ". += [${escaped_file}]")
        count=$((count + 1))
    done < <(find "${dir}" -type f \( \
        -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \
        -o -iname "*.webp" -o -iname "*.gif" -o -iname "*.bmp" \
        \) "${exclude_args[@]}" 2>/dev/null)

    log_info "Found ${count} wallpapers in ${dir}"

    # Update cache
    update_state ".cache.${cache_key} = {
        \"files\": ${files_json},
        \"last_scan\": ${now},
        \"count\": ${count}
    }"

    echo "${files_json}"
}

get_wallpaper_list() {
    local use_animated="${1:-false}"
    local wallpaper_dir

    if [[ "${use_animated}" == "true" ]]; then
        wallpaper_dir=$(get_config '.wallpaper_dirs.animated' '~/Pictures/wallpapers/animated')
        wallpaper_dir="${wallpaper_dir/#\~/$HOME}"
        discover_wallpapers "${wallpaper_dir}" "animated" "false"
    else
        wallpaper_dir=$(get_config '.wallpaper_dirs.static' '~/Pictures/wallpapers')
        wallpaper_dir="${wallpaper_dir/#\~/$HOME}"
        discover_wallpapers "${wallpaper_dir}" "static" "false"
    fi
}

select_random_wallpaper() {
    local use_animated="${1:-false}"
    local wallpapers
    wallpapers=$(get_wallpaper_list "${use_animated}")

    if [[ "${wallpapers}" == "[]" || -z "${wallpapers}" ]]; then
        log_error "No wallpapers found"
        return 1
    fi

    # Select random wallpaper
    local selected
    selected=$(echo "${wallpapers}" | jq -r '.[] | select(. != null)' | shuf -n1)

    if [[ -z "${selected}" ]]; then
        log_error "Failed to select wallpaper"
        return 1
    fi

    echo "${selected}"
}

# ============================================================================
# TOOL DETECTION & WALLPAPER SETTING
# ============================================================================

detect_display_server() {
    if [[ -n "${WAYLAND_DISPLAY}" ]]; then
        echo "wayland"
    elif [[ -n "${DISPLAY}" ]]; then
        echo "x11"
    else
        echo "unknown"
    fi
}

detect_available_tools() {
    local tools=()
    local tool_commands=("swww" "swaybg" "hyprpaper" "mpvpaper" "feh" "xwallpaper" "nitrogen")

    for tool in "${tool_commands[@]}"; do
        if command -v "${tool}" &>/dev/null; then
            tools+=("${tool}")
            log_debug "Found wallpaper tool: ${tool}"
        fi
    done

    printf '%s\n' "${tools[@]}"
}

set_wallpaper_swww() {
    local image="$1"
    local transition_ms
    transition_ms=$(get_config '.intervals.transition_ms' '300')

    # Ensure daemon is running
    if ! pgrep -x "swww-daemon" &>/dev/null; then
        log_debug "Starting swww-daemon"
        swww-daemon --format xrgb &
        sleep 0.5  # Give daemon time to start
    fi

    # Set wallpaper
    if swww img "${image}" \
        --transition-type random \
        --transition-duration "$((transition_ms / 1000)).${transition_ms:(-3)}" \
        2>/dev/null; then
        log_debug "Set wallpaper with swww: ${image}"
        return 0
    fi

    return 1
}

set_wallpaper_swaybg() {
    local image="$1"

    # Kill existing swaybg instances spawned by us
    local our_pids
    our_pids=$(read_state '.processes.swaybg_pids // []' | jq -r '.[]')
    if [[ -n "${our_pids}" ]]; then
        while IFS= read -r pid; do
            kill "${pid}" 2>/dev/null || true
        done <<< "${our_pids}"
    fi

    # Start new instance
    swaybg -i "${image}" -m fill &
    local new_pid=$!

    # Update state with new PID
    update_state ".processes.swaybg_pids = [${new_pid}]"

    log_debug "Set wallpaper with swaybg: ${image}"
    return 0
}

set_wallpaper_feh() {
    local image="$1"

    if feh --bg-fill "${image}" 2>/dev/null; then
        log_debug "Set wallpaper with feh: ${image}"
        return 0
    fi

    return 1
}

set_wallpaper_xwallpaper() {
    local image="$1"

    if xwallpaper --zoom "${image}" 2>/dev/null; then
        log_debug "Set wallpaper with xwallpaper: ${image}"
        return 0
    fi

    return 1
}

set_wallpaper() {
    local image="$1"

    # Validate image path
    image=$(validate_path "${image}" "") || {
        log_error "Invalid image path: ${image}"
        return 1
    }

    # Check if file exists and is readable
    if [[ ! -r "${image}" ]]; then
        log_error "Cannot read image: ${image}"
        return 1
    fi

    local display_server
    display_server=$(detect_display_server)
    log_debug "Display server: ${display_server}"

    # Get preferred tool from config
    local preferred_tool
    preferred_tool=$(get_config '.tools.preferred_static' 'auto')

    # Try preferred tool first if specified
    if [[ "${preferred_tool}" != "auto" ]] && command -v "${preferred_tool}" &>/dev/null; then
        case "${preferred_tool}" in
            swww) set_wallpaper_swww "${image}" && return 0 ;;
            swaybg) set_wallpaper_swaybg "${image}" && return 0 ;;
            feh) set_wallpaper_feh "${image}" && return 0 ;;
            xwallpaper) set_wallpaper_xwallpaper "${image}" && return 0 ;;
        esac
    fi

    # Fallback chain based on display server
    if [[ "${display_server}" == "wayland" ]]; then
        set_wallpaper_swww "${image}" && return 0
        set_wallpaper_swaybg "${image}" && return 0
    else
        set_wallpaper_feh "${image}" && return 0
        set_wallpaper_xwallpaper "${image}" && return 0
    fi

    # Last resort: try all available tools
    local available_tools
    available_tools=$(detect_available_tools)

    while IFS= read -r tool; do
        case "${tool}" in
            swww) set_wallpaper_swww "${image}" && return 0 ;;
            swaybg) set_wallpaper_swaybg "${image}" && return 0 ;;
            feh) set_wallpaper_feh "${image}" && return 0 ;;
            xwallpaper) set_wallpaper_xwallpaper "${image}" && return 0 ;;
        esac
    done <<< "${available_tools}"

    log_error "Failed to set wallpaper with any available tool"
    return 1
}

# ============================================================================
# BATTERY DETECTION
# ============================================================================

get_battery_status() {
    local battery_status="unknown"

    # Try multiple battery paths
    local battery_paths=(
        "/sys/class/power_supply/BAT0/status"
        "/sys/class/power_supply/BAT1/status"
        "/sys/class/power_supply/BATT/status"
    )

    for path in "${battery_paths[@]}"; do
        if [[ -r "${path}" ]]; then
            battery_status=$(tr '[:upper:]' '[:lower:]' < "${path}")
            log_debug "Battery status from ${path}: ${battery_status}"
            break
        fi
    done

    echo "${battery_status}"
}

should_use_animated() {
    local battery_optimization
    battery_optimization=$(get_config '.behavior.battery_optimization' 'true')

    if [[ "${battery_optimization}" != "true" ]]; then
        echo "true"
        return
    fi

    local battery_status
    battery_status=$(get_battery_status)

    if [[ "${battery_status}" == "discharging" ]]; then
        echo "false"
    else
        echo "true"
    fi
}

# ============================================================================
# GIF ANIMATION HANDLING
# ============================================================================

extract_gif_frames() {
    local gif_path="$1"
    local output_dir="$2"

    if ! command -v magick &>/dev/null && ! command -v convert &>/dev/null; then
        log_error "ImageMagick is required for GIF extraction"
        return 1
    fi

    log_info "Extracting frames from: ${gif_path}"

    # Use convert or magick based on availability
    local convert_cmd="convert"
    command -v magick &>/dev/null && convert_cmd="magick"

    if ${convert_cmd} "${gif_path}" -coalesce "${output_dir}/frame_%04d.png" 2>/dev/null; then
        log_info "Extracted frames to: ${output_dir}"
        return 0
    fi

    log_error "Failed to extract GIF frames"
    return 1
}

animate_gif_frames() {
    local frame_dir="$1"
    local frame_delay="$2"

    local frames=()
    while IFS= read -r frame; do
        frames+=("${frame}")
    done < <(find "${frame_dir}" -name "frame_*.png" | sort -V)

    if [[ ${#frames[@]} -eq 0 ]]; then
        log_error "No frames found in: ${frame_dir}"
        return 1
    fi

    log_info "Animating ${#frames[@]} frames with ${frame_delay}ms delay"

    # Animation loop
    local frame_index=0
    while true; do
        local current_frame="${frames[${frame_index}]}"

        if set_wallpaper "${current_frame}"; then
            log_debug "Displaying frame: ${frame_index}"
        fi

        # Check if we should stop
        local status
        status=$(read_state '.status')
        if [[ "${status}" != "running" ]]; then
            log_info "Animation stopped (status: ${status})"
            break
        fi

        # Move to next frame
        frame_index=$(( (frame_index + 1) % ${#frames[@]} ))

        # Sleep for frame delay
        sleep "0.$(printf '%03d' "${frame_delay}")"
    done
}

handle_animated_wallpaper() {
    local gif_path="$1"

    # Generate cache key from file hash
    local gif_hash
    gif_hash=$(sha256sum "${gif_path}" | cut -d' ' -f1)
    local cache_dir="${CACHE_DIR}/gifs/${gif_hash}"

    # Check if frames are already extracted
    if [[ -d "${cache_dir}" ]] && [[ -f "${cache_dir}/frame_0000.png" ]]; then
        log_info "Using cached frames for: ${gif_path}"
    else
        # Create cache directory
        mkdir -p "${cache_dir}"

        # Extract frames
        if ! extract_gif_frames "${gif_path}" "${cache_dir}"; then
            rm -rf "${cache_dir}"
            return 1
        fi
    fi

    # Get frame delay from config
    local frame_delay
    frame_delay=$(get_config '.intervals.gif_frame_ms' '50')

    # Start animation in background
    (
        animate_gif_frames "${cache_dir}" "${frame_delay}"
    ) &

    local animation_pid=$!
    update_state ".processes.animation_pid = ${animation_pid}"

    log_info "Started GIF animation (PID: ${animation_pid})"
    return 0
}

# ============================================================================
# CACHE MANAGEMENT
# ============================================================================

cleanup_cache() {
    local max_cache_mb
    max_cache_mb=$(get_config '.behavior.max_cache_size_mb' '500')
    local max_cache_bytes=$((max_cache_mb * 1024 * 1024))

    log_info "Cleaning cache (max size: ${max_cache_mb}MB)"

    # Get current cache size
    local current_size
    current_size=$(du -sb "${CACHE_DIR}" 2>/dev/null | cut -f1)

    if [[ ${current_size} -le ${max_cache_bytes} ]]; then
        log_debug "Cache size (${current_size} bytes) within limit"
        return 0
    fi

    # Remove oldest GIF frames first
    local freed_space=0
    while IFS= read -r dir; do
        local dir_size
        dir_size=$(du -sb "${dir}" 2>/dev/null | cut -f1)
        rm -rf "${dir}"
        freed_space=$((freed_space + dir_size))
        log_debug "Removed cache: ${dir} (freed ${dir_size} bytes)"

        current_size=$((current_size - dir_size))
        if [[ ${current_size} -le ${max_cache_bytes} ]]; then
            break
        fi
    done < <(find "${CACHE_DIR}/gifs" -type d -mindepth 1 -maxdepth 1 -printf '%T@ %p\n' 2>/dev/null | sort -n | cut -d' ' -f2)

    log_info "Cache cleanup completed (freed $((freed_space / 1024 / 1024))MB)"
}

# ============================================================================
# MAIN LOOP
# ============================================================================

stop_animation() {
    local animation_pid
    animation_pid=$(read_state '.processes.animation_pid // null')

    if [[ "${animation_pid}" != "null" && -n "${animation_pid}" ]]; then
        if kill -0 "${animation_pid}" 2>/dev/null; then
            kill -TERM "${animation_pid}" 2>/dev/null || true
            log_info "Stopped animation process (PID: ${animation_pid})"
        fi
        update_state '.processes.animation_pid = null'
    fi
}

change_wallpaper() {
    local use_animated
    use_animated=$(should_use_animated)

    # Stop any running animation
    stop_animation

    # Select new wallpaper
    local wallpaper
    wallpaper=$(select_random_wallpaper "${use_animated}")

    if [[ -z "${wallpaper}" ]]; then
        log_error "Failed to select wallpaper"
        return 1
    fi

    log_info "Changing wallpaper to: ${wallpaper}"

    # Check if it's an animated wallpaper
    if [[ "${wallpaper}" =~ \.(gif)$ ]]; then
        handle_animated_wallpaper "${wallpaper}"
    else
        set_wallpaper "${wallpaper}"
    fi

    # Update state
    update_state_atomic ".current_wallpaper = \"${wallpaper}\""
    add_to_history "${wallpaper}"

    return 0
}

main_loop() {
    log_info "Starting main loop..."

    # Update status
    update_state '.status = "running"'

    # Get change interval from config
    local change_interval
    change_interval=$(get_config '.intervals.change_seconds' '300')

    # Initial wallpaper change
    change_wallpaper

    # Main loop
    local last_change
    last_change=$(date +%s)
    local last_cleanup
    last_cleanup=$(date +%s)

    while true; do
        # Check status
        local status
        status=$(read_state '.status')

        case "${status}" in
            "stopping")
                log_info "Stopping main loop..."
                stop_animation
                break
                ;;
            "paused")
                sleep 1
                continue
                ;;
            "running")
                ;;
            *)
                log_warn "Unknown status: ${status}"
                sleep 1
                continue
                ;;
        esac

        # Check if it's time to change wallpaper
        local now
        now=$(date +%s)
        local elapsed=$((now - last_change))

        if [[ ${elapsed} -ge ${change_interval} ]]; then
            change_wallpaper
            last_change=${now}
        fi

        # Periodic cache cleanup (every hour)
        local cleanup_elapsed=$((now - last_cleanup))
        if [[ ${cleanup_elapsed} -ge 3600 ]]; then
            cleanup_cache
            last_cleanup=${now}
        fi

        # Sleep for a bit
        sleep 5
    done

    log_info "Main loop ended"
}

# ============================================================================
# IPC SOCKET HANDLING
# ============================================================================

create_socket() {
    if [[ -e "${SOCKET_FILE}" ]]; then
        rm -f "${SOCKET_FILE}"
    fi

    # Create socket using socat in background
    if command -v socat &>/dev/null; then
        (
            socat UNIX-LISTEN:"${SOCKET_FILE}",fork EXEC:"${SCRIPT_PATH} --socket-handler" &
            echo $! > "${RUNTIME_DIR}/socket.pid"
        ) &
        log_info "IPC socket created at: ${SOCKET_FILE}"
    else
        log_warn "socat not found, IPC socket disabled"
    fi
}

handle_socket_command() {
    local cmd
    read -r cmd

    case "${cmd}" in
        "next")
            log_info "Received command: next"
            change_wallpaper
            echo "OK: Changed wallpaper"
            ;;
        "pause")
            log_info "Received command: pause"
            update_state '.status = "paused"'
            stop_animation
            echo "OK: Paused"
            ;;
        "resume")
            log_info "Received command: resume"
            update_state '.status = "running"'
            echo "OK: Resumed"
            ;;
        "status")
            local status
            status=$(read_state '.')
            echo "${status}"
            ;;
        "reload")
            log_info "Received command: reload"
            reload_config
            echo "OK: Configuration reloaded"
            ;;
        "stop")
            log_info "Received command: stop"
            update_state '.status = "stopping"'
            echo "OK: Stopping"
            ;;
        *)
            echo "ERROR: Unknown command: ${cmd}"
            ;;
    esac
}

send_socket_command() {
    local cmd="$1"

    if [[ ! -e "${SOCKET_FILE}" ]]; then
        log_error "Socket not found: ${SOCKET_FILE}"
        return 1
    fi

    if command -v socat &>/dev/null; then
        echo "${cmd}" | socat - UNIX-CONNECT:"${SOCKET_FILE}"
    else
        log_error "socat is required for IPC communication"
        return 1
    fi
}

# ============================================================================
# CLI INTERFACE
# ============================================================================

show_usage() {
    cat << EOF
${SCRIPT_NAME} v${VERSION} - Professional Wallpaper Manager

Usage: $(basename "$0") [COMMAND] [OPTIONS]

Commands:
    start       Start wallpaper slideshow
    stop        Stop wallpaper slideshow
    restart     Restart wallpaper slideshow
    daemon      Start in daemon mode
    next        Change to next wallpaper
    pause       Pause slideshow
    resume      Resume slideshow
    status      Show current status
    info        Show detailed information
    list        List available wallpapers
    reload      Reload configuration
    clean       Clean cache
    help        Show this help message

Options:
    -d, --debug     Enable debug logging
    -c, --config    Specify config file
    -v, --version   Show version

Configuration:
    ${CONFIG_FILE}

State & Logs:
    ${STATE_FILE}
    ${LOG_FILE}

Examples:
    $(basename "$0") daemon     # Start as daemon
    $(basename "$0") next       # Change wallpaper
    $(basename "$0") status     # Check status

EOF
}

show_info() {
    echo "═══════════════════════════════════════════════════"
    echo " ${SCRIPT_NAME} v${VERSION}"
    echo "═══════════════════════════════════════════════════"
    echo
    echo "Status Information:"
    echo "──────────────────"

    local status current_wallpaper changes_count last_change
    status=$(read_state '.status // "unknown"')
    current_wallpaper=$(read_state '.current_wallpaper // "none"')
    changes_count=$(read_state '.stats.changes_count // 0')
    last_change=$(read_state '.stats.last_change // "never"')

    printf "%-20s: %s\n" "Status" "${status}"
    printf "%-20s: %s\n" "Current Wallpaper" "${current_wallpaper}"
    printf "%-20s: %s\n" "Changes Count" "${changes_count}"
    printf "%-20s: %s\n" "Last Change" "${last_change}"

    echo
    echo "System Information:"
    echo "──────────────────"

    local display_server battery_status
    display_server=$(detect_display_server)
    battery_status=$(get_battery_status)

    printf "%-20s: %s\n" "Display Server" "${display_server}"
    printf "%-20s: %s\n" "Battery Status" "${battery_status}"

    echo
    echo "Available Tools:"
    echo "───────────────"
    detect_available_tools | sed 's/^/  - /'

    echo
    echo "Cache Usage:"
    echo "───────────"
    if [[ -d "${CACHE_DIR}" ]]; then
        local cache_size
        cache_size=$(du -sh "${CACHE_DIR}" 2>/dev/null | cut -f1)
        printf "%-20s: %s\n" "Cache Size" "${cache_size}"
    fi
}

list_wallpapers() {
    echo "Static Wallpapers:"
    echo "─────────────────"
    get_wallpaper_list "false" | jq -r '.[]' | sed 's/^/  /'

    echo
    echo "Animated Wallpapers:"
    echo "───────────────────"
    get_wallpaper_list "true" | jq -r '.[]' | sed 's/^/  /'
}

# ============================================================================
# MAIN ENTRY POINT
# ============================================================================

main() {
    # Check for version flag first
    if [[ "$1" == "-v" ]] || [[ "$1" == "--version" ]]; then
        echo "${SCRIPT_NAME} v${VERSION}"
        exit 0
    fi

    # Check for socket handler
    if [[ "$1" == "--socket-handler" ]]; then
        handle_socket_command
        exit 0
    fi

    local cmd="${1:-help}"
    shift || true

    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -d|--debug)
                LOG_LEVEL=${LOG_DEBUG}
                log_debug "Debug mode enabled"
                ;;
            -c|--config)
                CONFIG_FILE="$2"
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit ${E_USAGE}
                ;;
        esac
        shift
    done

    # Initialize
    init_directories
    init_config
    init_state

    # Set up cleanup
    trap 'cleanup' EXIT

    # Handle commands
    case "${cmd}" in
        start)
            acquire_lock
            create_socket
            main_loop
            ;;
        stop)
            if send_socket_command "stop"; then
                echo "Stopping wallpaper manager..."
            else
                # Fallback: update state directly
                update_state '.status = "stopping"'
                stop_animation
            fi
            ;;
        restart)
            "$0" stop
            sleep 2
            "$0" start
            ;;
        daemon)
            acquire_lock
            create_socket
            daemonize
            ;;
        next)
            send_socket_command "next"
            ;;
        pause)
            send_socket_command "pause"
            ;;
        resume)
            send_socket_command "resume"
            ;;
        status)
            if ! send_socket_command "status"; then
                # Fallback: read state directly
                read_state '.' | jq '.'
            fi
            ;;
        info)
            show_info
            ;;
        list)
            list_wallpapers
            ;;
        reload)
            send_socket_command "reload"
            ;;
        clean)
            cleanup_cache
            ;;
        help)
            show_usage
            ;;
        *)
            log_error "Unknown command: ${cmd}"
            show_usage
            exit ${E_USAGE}
            ;;
    esac
}

# Run main if not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
