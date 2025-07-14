#!/bin/bash

# Directory containing GIF wallpapers
INPUT_DIR="/home/utsav/Pictures/wallpapers/gifs"
OUTPUT_DIR="/home/utsav/Pictures/wallpapers/gifs_resized"
TARGET_RESOLUTION="1920x1080"
TMP_DIR="/tmp/gif_resize"

# Ensure the temporary directory exists
mkdir -p "$TMP_DIR"

# Function to process a single file
resize_gif() {
	local input_file="$1"
	# shellcheck disable=SC2155
	local output_file="$OUTPUT_DIR/$(basename "$input_file")"
	local resolution
	local tmp_file

	# Get the resolution of the input file
	resolution=$(ffmpeg -i "$input_file" 2>&1 | grep Video: | grep -Po '\d{3,5}x\d{3,5}')
	tmp_file="$(mktemp -p "$TMP_DIR" --suffix=".gif")"

	# Check if the resolution is greater than the target resolution
	if [[ $resolution =~ ^([0-9]+)x([0-9]+)$ ]]; then
		width="${BASH_REMATCH[1]}"
		height="${BASH_REMATCH[2]}"
		target_width="${TARGET_RESOLUTION%x*}"
		target_height="${TARGET_RESOLUTION#*x}"

		if ((width < target_width || height < target_height)); then
			echo "Resizing: $input_file"
			ffmpeg -i "$input_file" -vf "scale=$TARGET_RESOLUTION:flags=lanczos" -y "$tmp_file" >/dev/null 2>&1
			# shellcheck disable=SC2181
			if [ $? -eq 0 ]; then
				mv "$tmp_file" "$output_file"
				echo "Successfully resized: $input_file"
			else
				echo "Failed to resize: $input_file"
				rm -f "$tmp_file"
			fi
		else
			echo "Skipping (resolution is greater or equal): $input_file"
		fi
	else
		echo "Could not determine resolution for: $input_file"
	fi
}

export -f resize_gif
export INPUT_DIR OUTPUT_DIR TMP_DIR TARGET_RESOLUTION

# Use GNU Parallel to process files concurrently
find "$INPUT_DIR" -type f -name "*.gif" | parallel resize_gif {}

# Clean up temporary directory
rm -rf "$TMP_DIR"
