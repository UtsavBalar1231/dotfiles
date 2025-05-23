#!/usr/bin/env bash

set -euo pipefail

command -v powerprofilesctl &>/dev/null && has_power_profiles=true || has_power_profiles=false

if [[ -f "$HOME/.cache/perfmode" ]]; then
	notify-send "󰾆  Perfmode deactivated!" "Animations and blur enabled."
	hyprctl reload
	rm "$HOME/.cache/perfmode"

	if [[ $has_power_profiles == true ]]; then
		powerprofilesctl set balanced
	fi

	# Reload waybar
	"$HOME/.config/hypr/scripts/reload.sh"
else
	notify-send "󰓅  Perfmode activated!" "Animations and blur disabled."

	# Activate perfmode
	hyprctl --batch "\
    keyword animations:enabled 0;\
    keyword decoration:drop_shadow 0;\
    keyword decoration:blur:enabled 0;\
    keyword general:gaps_in 0;\
    keyword general:gaps_out 0;\
    keyword general:border_size 0;\
    keyword decoration:rounding 0"

	touch "$HOME/.cache/perfmode"

	if [[ $has_power_profiles == true ]]; then
		powerprofilesctl set performance
	fi

	# Reload waybar
	"$HOME/.config/hypr/scripts/reload.sh"
fi
