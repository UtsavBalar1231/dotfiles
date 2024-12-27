#!/usr/bin/env bash

color=$(hyprpicker --format=hex)

if command -v clip &>/dev/null; then
	echo "$color" | clip
else
	echo "$color" | wl-copy
fi

notify-send -i "color-picker" "Hyprpicker" "Color copied: $color"
