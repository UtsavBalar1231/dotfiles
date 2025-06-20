#!/usr/bin/env bash

get_option() {
	local opt="$1"
	hyprctl getoption "decoration:$opt" | awk 'NR==1{print $2}'
}

set_opacity() {
	local opacity="$1"
	hyprctl --batch "\
        keyword decoration:active_opacity $opacity;\
        keyword decoration:inactive_opacity $opacity"
}

toggle_blur() {
	local state="$1"
	hyprctl keyword "decoration:blur:enabled" "$state"
}

main() {
	local active_opacity inactive_opacity blur_enabled

	active_opacity="$(get_option active_opacity)"
	inactive_opacity="$(get_option inactive_opacity)"
	blur_enabled="$(hyprctl getoption decoration:blur:enabled | awk 'NR==2{print $2}')"

	if [[ "$active_opacity" == "1.000000" && "$inactive_opacity" == "1.000000" ]]; then
		[[ "$blur_enabled" == "true" ]] && toggle_blur no
		set_opacity 0
	else
		[[ "$blur_enabled" == "true" ]] && toggle_blur yes
		set_opacity 1
	fi
}

main "$@"
