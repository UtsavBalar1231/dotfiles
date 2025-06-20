#!/bin/bash

# Directory containing the shaders
SHADER_DIR="$HOME/.config/hypr/shaders"

# Get the list of shaders (only .glsl files)
shaders=("$SHADER_DIR"/*.glsl)

# Extract just the filenames without the path and extension
shader_names=()
for shader in "${shaders[@]}"; do
    shader_name=$(basename "$shader" .glsl)
    shader_names+=("$shader_name")
done

# Use Rofi to select a shader
selected_shader=$(printf '%s\n' "${shader_names[@]}" | rofi -dmenu -i -p "Select Shader")

# Check if a shader was selected
if [[ -n "$selected_shader" ]]; then
    # Toggle the selected shader using hyprshade
    hyprshade toggle "$selected_shader"
else
    echo "No shader selected."
fi
