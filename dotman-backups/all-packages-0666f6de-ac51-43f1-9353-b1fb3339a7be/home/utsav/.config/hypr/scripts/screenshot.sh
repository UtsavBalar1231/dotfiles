#!/usr/bin/env bash

SCREENSHOT_DIR="$(xdg-user-dir PICTURES)/Screenshots"
mkdir -p "$SCREENSHOT_DIR"

generate_filename() {
	printf "%s/screenshot_%(%Y-%m-%d_%H-%M-%S)T.png" "$SCREENSHOT_DIR" -1
}

notify() {
	local file="$1"
	notify-send "Screenshot saved" "$file" --icon=dialog-information
}

copy_to_clipboard_x11() {
	local file="$1"
	xclip -selection clipboard -t image/png -i "$file"
}

copy_to_clipboard_wayland() {
	local file="$1"
	wl-copy <"$file"
}

capture_entire() {
	local file
	file="$(generate_filename)"

	if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
		grim "$file"
		copy_to_clipboard_wayland "$file"
	elif [[ -n "${DISPLAY:-}" ]]; then
		import -window root "$file"
		copy_to_clipboard_x11 "$file"
	else
		printf "No compatible display server found.\n"
		exit 1
	fi

	notify "$file"
}

capture_partial() {
	local file
	file="$(generate_filename)"

	if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
		grim -g "$(slurp)" "$file"
		copy_to_clipboard_wayland "$file"
	elif [[ -n "${DISPLAY:-}" ]]; then
		import "$file"
		copy_to_clipboard_x11 "$file"
	else
		printf "No compatible display server found.\n"
		exit 1
	fi

	notify "$file"
}

main() {
	if [[ $# -ne 1 ]]; then
		printf "Usage: %s [entire|partial]\n" "$0"
		exit 1
	fi

	case "$1" in
	entire)
		capture_entire
		;;
	partial)
		capture_partial
		;;
	*)
		printf "Invalid option: %s\n" "$1"
		printf "Usage: %s [entire|partial]\n" "$0"
		exit 1
		;;
	esac
}

main "$@"
