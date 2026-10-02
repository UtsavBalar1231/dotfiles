#!/usr/bin/env bash

kill_process() {
	if ! command -v fzf &>/dev/null; then
		echo "Error: 'fzf' is not installed. Please install it to use this script."
		return 1
	fi

	local process_name selected_process process_list pid confirm

	if [[ -n "${1:-}" ]]; then
		process_name="$1"
		# shellcheck disable=SC2009
		process_list="$(ps -eo pid,command | grep -i "$process_name" | grep -v grep)"

		if [[ -z "$process_list" ]]; then
			echo "No matching processes found for: $process_name"
			return 1
		fi

		selected_process="$(echo "$process_list" | fzf --ansi --preview 'echo {}' --height ~20%)"
	else
		selected_process="$(ps -eo pid,command --no-headers | fzf --height 20% --preview 'echo {}' --prompt="Select a process to kill: ")"
	fi

	if [[ -z "$selected_process" ]]; then
		echo "No process selected. Exiting."
		return 1
	fi

	pid="$(echo "$selected_process" | awk '{print $1}')"

	echo "Selected process:"
	echo "$selected_process"
	read -r -p "Are you sure you want to kill this process? ([Y]/n): " confirm

	confirm=${confirm:-Y}

	if [[ "$confirm" =~ ^[Yy]$ ]]; then
		kill -9 "$pid" 2>/dev/null && echo "Process $pid killed successfully." || echo "Failed to kill process $pid. You might need additional permissions."
	else
		echo "Process not killed."
	fi
}

kill_process "$@"
