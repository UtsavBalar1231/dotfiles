#!/usr/bin/env bash

main() {
	local color
	color="$(hyprpicker --format=hex)"

	if ! command -v wl-copy &>/dev/null; then
		notify-send -i "color-picker" "Hyprpicker" "No clipboard manager found. Install wl-clipboard for clipboard support."
	fi

	echo -n "$color" | wl-copy

	notify-send -i "color-picker" "Hyprpicker" "Color copied: $color"
}

main "$@"
