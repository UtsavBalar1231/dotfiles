#!/bin/bash

# Directory containing GIF wallpapers
INPUT_DIR="/home/utsav/Pictures/wallpapers/gifs"
OUTPUT_DIR="/home/utsav/Pictures/wallpapers/gifs_resized"

# Maximum allowed size in bytes (10MB)
MAX_SIZE=$((10 * 1024 * 1024))
# Target resolution and minimum FPS
TARGET_RESOLUTION="1920:1080"
MIN_FPS=12

# Ensure dependencies are installed
if ! command -v ffmpeg &>/dev/null || ! command -v stat &>/dev/null; then
	echo "Error: Required tools (ffmpeg, stat) are not installed."
	exit 1
fi

# Check input directory
if [ ! -d "$INPUT_DIR" ]; then
	echo "Error: Input directory '$INPUT_DIR' not found."
	exit 1
fi

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Function to process a single GIF
process_gif() {
	local input_file="$1"
	local output_file="$2"

	# Step 1: Resize and set FPS
	ffmpeg -i "$input_file" -vf "[0:v] scale=$TARGET_RESOLUTION:flags=lanczos,split [a][b]; [a] palettegen=reserve_transparent=on:transparency_color=ffffff [p]; [b][p] paletteuse; fps=$MIN_FPS" -y "$output_file" >/dev/null 2>&1

	# Step 2: Check size and adjust quality if needed
	local file_size
	file_size=$(stat -c%s "$output_file")
	local quality=8

	while [ "$file_size" -gt $MAX_SIZE ]; do
		quality=$((quality - 1))
		if [ $quality -le 5 ]; then
			echo "Warning: Cannot compress $input_file further without significant quality loss."
			break
		fi

		ffmpeg -i "$input_file" -vf "[0:v] scale=$TARGET_RESOLUTION:flags=lanczos,split [a][b]; [a] palettegen=reserve_transparent=on:transparency_color=ffffff [p]; [b][p] paletteuse; fps=$quality" -y "$output_file" >/dev/null 2>&1

		file_size=$(stat -c%s "$output_file")
	done

	echo "Processed: $input_file -> $output_file (Size: $((file_size / 1024)) KB)"
}

export -f process_gif
export TARGET_RESOLUTION MIN_FPS MAX_SIZE

# Use GNU Parallel to process GIFs in parallel
find "$INPUT_DIR" -type f -name "*.gif" | parallel --bar process_gif {} "$OUTPUT_DIR/{/}"

echo "All GIFs have been processed and saved to $OUTPUT_DIR."
