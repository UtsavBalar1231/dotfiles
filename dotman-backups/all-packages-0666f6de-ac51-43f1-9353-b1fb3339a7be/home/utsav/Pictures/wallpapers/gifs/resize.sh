#!/usr/bin/env bash
# shellcheck disable=SC1083
set -euo pipefail

# --------------------------
# Configuration with Smart Defaults
# --------------------------
readonly INPUT_DIR="/home/utsav/Pictures/wallpapers/gifs/"
readonly OUTPUT_DIR="/home/utsav/Pictures/wallpapers/gifs_optimized/"
readonly MAX_SIZE=$((16 * 1024 * 1024)) # 10MB
readonly TARGET_RESOLUTION="1920:1080"
readonly MIN_FPS=8
readonly MAX_FPS=12
readonly QUALITY_STEP=3
readonly MIN_QUALITY=15
readonly MAX_COLORS=128
readonly COLOR_REDUCTION_STEP=32

# --------------------------
# Dependency Checks
# --------------------------
check_dependencies() {
	local deps=("ffmpeg" "ffprobe" "parallel")
	for dep in "${deps[@]}"; do
		if ! command -v "$dep" &>/dev/null; then
			echo "Error: Missing required dependency - $dep" >&2
			exit 1
		fi
	done
}

# --------------------------
# Intelligent Metadata Analysis
# --------------------------
analyze_gif() {
	local input_file="$1"
	local -n __meta_ref="$2"

	__meta_ref=(
		[width]=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$input_file")
		[height]=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$input_file")
		[fps]=$(ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of csv=p=0 "$input_file" | bc -l | awk '{printf "%.1f", $0}')
		[duration]=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$input_file")
		[frames]=$(ffprobe -v error -select_streams v:0 -count_packets -show_entries stream=nb_read_packets -of csv=p=0 "$input_file")
		[colors]=$(ffprobe -v error -select_streams v:0 -show_entries stream=nb_read_packets -of csv=p=0 "$input_file")
		[original_size]=$(stat -c%s "$input_file")
	)
}

# --------------------------
# Adaptive Compression Engine
# --------------------------
optimize_gif() {
	local input_file="$1"
	local output_file="$2"
	local temp_file
	temp_file=$(mktemp)

	declare -A meta
	analyze_gif "$input_file" meta

	# Initial check for already compliant files
	if ((meta[original_size] <= MAX_SIZE)); then
		mv "$input_file" "$output_file"
		echo "Copy: Already optimized ${input_file##*/} (${meta[original_size]} bytes)"
		return 0
	fi

	# Dynamic quality adjustment based on file size
	local quality=$((50 - (meta[original_size] / (MAX_SIZE * 20))))
	quality=$((quality > MIN_QUALITY ? quality : MIN_QUALITY))
	quality=$((quality < 50 ? quality : 50))

	# Adaptive FPS calculation
	local target_fps
	target_fps=$(printf "%.1f" "$(awk -v f="${meta[fps]}" -v min="$MIN_FPS" 'BEGIN {print (f > min) ? f : min}')")
	target_fps=$(awk -v f="$target_fps" -v max="$MAX_FPS" 'BEGIN {print (f < max) ? f : max}')

	# Smart resolution scaling
	local scale_filter=""
	if ((meta[width] > ${TARGET_RESOLUTION%:*} || meta[height] > ${TARGET_RESOLUTION#*:})); then
		scale_filter="scale=w=${TARGET_RESOLUTION%:*}:h=${TARGET_RESOLUTION#*:}:flags=lanczos,"
	fi

	# Tiered optimization attempts
	local optimization_tiers=(
		# Tier 1: Lossless optimizations
		"-vf ${scale_filter}split[a][b];[a]palettegen=stats_mode=diff[p];[b][p]paletteuse=dither=none -compression_level 0"

		# Tier 2: Mild compression
		"-vf ${scale_filter}split[a][b];[a]palettegen=stats_mode=diff:max_colors=${MAX_COLORS}[p];[b][p]paletteuse=dither=bayer:bayer_scale=1 -compression_level ${quality}"

		# Tier 3: Aggressive compression
		"-vf ${scale_filter}fps=${target_fps},split[a][b];[a]palettegen=stats_mode=diff:max_colors=$((MAX_COLORS - COLOR_REDUCTION_STEP))[p];[b][p]paletteuse=dither=bayer:bayer_scale=2 -compression_level $((quality + QUALITY_STEP))"

		# Tier 4: Resolution reduction
		"-vf scale=iw/2:ih/2:flags=lanczos,fps=${MIN_FPS},split[a][b];[a]palettegen=stats_mode=diff:max_colors=$((MAX_COLORS - COLOR_REDUCTION_STEP * 2))[p];[b][p]paletteuse=dither=bayer:bayer_scale=3 -compression_level $((quality + QUALITY_STEP * 2))"
	)

	for tier in "${optimization_tiers[@]}"; do
		if ffmpeg -v error -i "$input_file" "$tier" -y "$temp_file" 2>/dev/null; then
			local current_size
			current_size=$(stat -c%s "$temp_file")
			if ((current_size <= MAX_SIZE)); then
				mv "$temp_file" "$output_file"
				echo "Optimized: ${input_file##*/} (${current_size} bytes)"
				return 0
			fi
		fi
	done

	# Fallback to smallest possible
	ffmpeg -v error -i "$input_file" \
		-vf "scale=iw/4:ih/4:flags=lanczos,fps=$MIN_FPS,split[a][b];[a]palettegen=stats_mode=diff:max_colors=64[p];[b][p]paletteuse=dither=bayer:bayer_scale=5" \
		-compression_level $((quality + QUALITY_STEP * 4)) \
		-y "$output_file"

	local final_size
	final_size=$(stat -c%s "$output_file")
	((final_size > MAX_SIZE)) && echo "Warning: Failed to optimize ${input_file##*/} below size limit" >&2
	echo "Final attempt: ${input_file##*/} (${final_size} bytes)"
	return 0
}

# --------------------------
# Main Execution
# --------------------------
main() {
	check_dependencies
	mkdir -p "$OUTPUT_DIR"

	echo "Starting adaptive GIF optimization..."
	find "$INPUT_DIR" -type f -iname "*.gif" -print0 |
		parallel -0 --bar --jobs "$(($(nproc) / 2))" \
			optimize_gif {} "$OUTPUT_DIR/"{/}

	echo -e "\nOptimization complete. Output directory: $OUTPUT_DIR"
}

export -f optimize_gif analyze_gif check_dependencies
export INPUT_DIR OUTPUT_DIR MAX_SIZE TARGET_RESOLUTION MIN_FPS MAX_FPS \
	QUALITY_STEP MIN_QUALITY MAX_COLORS COLOR_REDUCTION_STEP

main
