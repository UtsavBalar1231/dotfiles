#!/usr/bin/env bash

fetch_updates() {
	local pacman_updates aur_updates total_updates tooltip output

	pacman_updates="$(pacman -Qu 2>/dev/null | wc -l)"
	# If aur vercmp is not available, fallback to 0
	if command -v aur &>/dev/null; then
		aur_updates="$(pacman -Qm 2>/dev/null | aur vercmp 2>/dev/null | wc -l)"
	else
		aur_updates=0
	fi
	total_updates=$((pacman_updates + aur_updates))
	tooltip="There are $total_updates updates available."

	output="$(jq --unbuffered --compact-output \
		--arg text "$total_updates" \
		--arg tooltip "$tooltip" \
		'{text: $text, tooltip: $tooltip}')"

	echo "$output"
}

main() {
	if ! command -v jq &>/dev/null; then
		echo "Error: 'jq' is required but not installed." >&2
		exit 1
	fi

	fetch_updates
}

main
