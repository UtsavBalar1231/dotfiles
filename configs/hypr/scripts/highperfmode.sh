#!/bin/bash

# Check if power-profiles-daemon is installed
if command -v powerprofilesctl &>/dev/null; then
	has_power_profiles=true
else
	has_power_profiles=false
fi

if [ -f ~/.cache/perfmode ]; then
	notify-send -i "" "Hyprland" "Perfmode deactivated! Animations and blur enabled."
	# Deactivate perfmode
	hyprctl reload
	rm ~/.cache/perfmode

	# Set power profile to balanced
	if $has_power_profiles; then
		powerprofilesctl set balanced
	fi

	# Reload waybar
	~/.config/hypr/scripts/reload.sh
else
	notify-send -i "" "Hyprland" "Perfmode activated! Animations and blur disabled."

	# Activate perfmode
	hyprctl --batch "\
    keyword animations:enabled 0;\
    keyword decoration:drop_shadow 0;\
    keyword decoration:blur:enabled 0;\
    keyword general:gaps_in 0;\
    keyword general:gaps_out 0;\
    keyword general:border_size 1;\
    keyword decoration:rounding 0"
	touch ~/.cache/perfmode

	# Set power profile to performance
	if $has_power_profiles; then
		powerprofilesctl set performance
	fi

	# Reload waybar
	~/.config/hypr/scripts/reload.sh
fi
