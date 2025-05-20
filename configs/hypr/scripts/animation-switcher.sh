#!/bin/bash

# Animation switcher script for Hyprland

CONFIG_FILE="$HOME/.config/hypr/hyprland.conf"
BACKUP_FILE="$HOME/.config/hypr/hyprland.conf.bak"

# Create backup if it doesn't exist
if [ ! -f "$BACKUP_FILE" ]; then
    cp "$CONFIG_FILE" "$BACKUP_FILE"
fi

show_help() {
    echo "Hyprland Animation Switcher"
    echo "Usage: $0 [preset]"
    echo ""
    echo "Available presets:"
    echo "  default   - macOS-like animations"
    echo "  minimal   - Ultra-fast minimal animations"
    echo "  fluid     - Smooth fluid animations"
    echo "  subtle    - Subtle, barely visible animations"
    echo "  dynamic   - Dynamic animations with bounce effects"
    echo "  material3 - Material Design 3 inspired animations"
    echo "  ios18     - iOS 18 inspired animations"
    echo "  clean     - Clean, minimal animations with inheritance"
    echo ""
    echo "Example: $0 fluid"
}

if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    show_help
    exit 0
fi

switch_animation() {
    local preset=$1
    local preset_file="animations.conf"
    
    case $preset in
        minimal)
            preset_file="animations_minimal.conf"
            ;;
        fluid)
            preset_file="animations_fluid.conf"
            ;;
        subtle)
            preset_file="animations_subtle.conf"
            ;;
        dynamic)
            preset_file="animations_dynamic.conf"
            ;;
        material3)
            preset_file="animations_material3.conf"
            ;;
        ios18)
            preset_file="animations_ios18.conf"
            ;;
        clean)
            preset_file="animations_clean.conf"
            ;;
        default)
            preset_file="animations.conf"
            ;;
        *)
            echo "Unknown preset: $preset"
            show_help
            exit 1
            ;;
    esac
    
    # Create a temporary file
    TMP_FILE=$(mktemp)
    
    # Use sed to uncomment the selected preset and comment out the others
    sed -E "s/^(#)? ?source = ~\/.config\/hypr\/conf\/animations(_[a-z0-9]+)?.conf.*$/# source = ~\/.config\/hypr\/conf\/animations\2.conf/" "$CONFIG_FILE" > "$TMP_FILE"
    sed -i "s|# source = ~/.config/hypr/conf/${preset_file}.*|source = ~/.config/hypr/conf/${preset_file}      # Selected animation preset|" "$TMP_FILE"
    
    # Replace the config file with our modified version
    mv "$TMP_FILE" "$CONFIG_FILE"
    
    echo "Switched to $preset animation preset"
    echo "Restart Hyprland for changes to take effect (hyprctl reload)"
}

if [ $# -eq 0 ]; then
    show_help
    exit 0
else
    switch_animation "$1"
fi

# Reload Hyprland configuration
hyprctl reload 