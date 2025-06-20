#!/usr/bin/env bash

readonly PROCESS_NAME="hypridle"
readonly LOCK_CMD="hyprlock"  # Replace with your actual lock command

main() {
    local action="${1:-}"
    
    case "${action}" in
        status)
            get_status
            ;;
        toggle)
            toggle_inhibitor
            ;;
        lock)
            lock_screen
            ;;
        *)
            show_help
            exit 1
            ;;
    esac
}

get_status() {
    sleep 0.2  # Allow time for state changes
    if process_running; then
        local status='{"text": "󰍛", "class": "inactive", "tooltip": "Auto-suspend ACTIVE\nLeft: Disable\nRight: Lock"}'
    else
        local status='{"text": "󰍜", "class": "active", "tooltip": "Auto-suspend INACTIVE\nLeft: Enable\nRight: Lock"}'
    fi
    echo "${status}"
}

toggle_inhibitor() {
    if process_running; then
        pkill -x "${PROCESS_NAME}"
    else
        if ! command -v "${PROCESS_NAME}" >/dev/null; then
            echo "Error: ${PROCESS_NAME} not found" >&2
            exit 2
        fi
        "${PROCESS_NAME}" &
    fi
}

lock_screen() {
    if ! command -v "${LOCK_CMD}" >/dev/null; then
        echo "Error: ${LOCK_CMD} not found" >&2
        exit 3
    fi
    "${LOCK_CMD}"
}

process_running() {
    pgrep -x "${PROCESS_NAME}" >/dev/null
}

show_help() {
    cat <<EOF
Usage: ${0##*/} [COMMAND]

Commands:
  status    Get current inhibitor status (for Waybar)
  toggle    Enable/disable auto-suspend
  lock      Lock the screen

EOF
}

main "$@"
