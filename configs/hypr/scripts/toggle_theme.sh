#!/usr/bin/env bash

set -euo pipefail

# Theme Toggle Script for Hyprland Environment
# Toggles between gruvbox and everforest themes across multiple applications

# Configuration paths
HYPR_CONFIG_DIR="$HOME/.config/hypr"
THEME_STATE_FILE="$HYPR_CONFIG_DIR/.theme_state"
KITTY_CONFIG="$HOME/.config/kitty/kitty.conf"
GHOSTTY_CONFIG="$HOME/.config/ghostty/config"
HYPRPANEL_CONFIG="$HOME/.config/hyprpanel/config.toml"

# Theme configuration files
HYPR_DARK_THEME="$HYPR_CONFIG_DIR/conf/themes/gruvbox.conf"
HYPR_LIGHT_THEME="$HYPR_CONFIG_DIR/conf/themes/everforest.conf"
KITTY_DARK_THEME="$HOME/.config/kitty/themes/gruvbox.conf"
KITTY_LIGHT_THEME="$HOME/.config/kitty/themes/everforest.conf"
GHOSTTY_DARK_THEME="$HOME/.config/ghostty/themes/gruvbox.conf"
GHOSTTY_LIGHT_THEME="$HOME/.config/ghostty/themes/everforest.conf"

# Icons for notifications
DARK_ICON="weather-clear-night"
LIGHT_ICON="weather-clear"

# Default to dark theme if state file doesn't exist
if [[ ! -f "$THEME_STATE_FILE" ]]; then
    echo "dark" > "$THEME_STATE_FILE"
fi

# Get current theme
current_theme=$(cat "$THEME_STATE_FILE")

# Toggle theme state
if [[ "$current_theme" == "dark" ]]; then
    new_theme="light"
    theme_icon="$LIGHT_ICON"
    notification_text="Light theme activated"
else
    new_theme="dark"
    theme_icon="$DARK_ICON"
    notification_text="Dark theme activated"
fi

# Update theme state file
echo "$new_theme" > "$THEME_STATE_FILE"

# Function to apply theme to Hyprland
apply_hyprland_theme() {
    local theme_file
    
    if [[ "$new_theme" == "dark" ]]; then
        theme_file="$HYPR_DARK_THEME"
    else
        theme_file="$HYPR_LIGHT_THEME"
    fi
    
    # Check if theme file exists
    if [[ -f "$theme_file" ]]; then
        # Create a symlink to the active theme
        ln -sf "$theme_file" "$HYPR_CONFIG_DIR/conf/themes/current.conf"
        
        # Reload Hyprland config
        hyprctl reload
    else
        echo "Error: Hyprland theme file not found: $theme_file"
    fi
}

# Function to apply theme to Kitty terminal
apply_kitty_theme() {
    local theme_file
    
    if [[ "$new_theme" == "dark" ]]; then
        theme_file="$KITTY_DARK_THEME"
    else
        theme_file="$KITTY_LIGHT_THEME"
    fi
    
    # Check if Kitty is installed and theme file exists
    if command -v kitty &>/dev/null && [[ -f "$theme_file" ]]; then
        # Update kitty config to include the theme
        if grep -q "include themes/" "$KITTY_CONFIG"; then
            sed -i "s|include themes/.*\.conf|include $theme_file|g" "$KITTY_CONFIG"
        else
            echo "include $theme_file" >> "$KITTY_CONFIG"
        fi
        
        # Reload kitty configuration for all running instances
        killall -SIGUSR1 kitty 2>/dev/null || true
    fi
}

# Function to apply theme to Ghostty terminal
apply_ghostty_theme() {
    local theme_file
    
    if [[ "$new_theme" == "dark" ]]; then
        theme_file="$GHOSTTY_DARK_THEME"
    else
        theme_file="$GHOSTTY_LIGHT_THEME"
    fi
    
    # Check if Ghostty is installed and theme file exists
    if command -v ghostty &>/dev/null && [[ -f "$theme_file" && -f "$GHOSTTY_CONFIG" ]]; then
        # Update ghostty config to include the theme
        if grep -q "include" "$GHOSTTY_CONFIG"; then
            sed -i "s|include .*themes/.*\.conf|include $theme_file|g" "$GHOSTTY_CONFIG"
        else
            echo "include $theme_file" >> "$GHOSTTY_CONFIG"
        fi
        
        # Reload ghostty if possible
        if command -v ghostty-reload &>/dev/null; then
            ghostty-reload
        fi
    fi
}

# Function to apply theme to GTK applications
apply_gtk_theme() {
    local gtk_theme
    
    if [[ "$new_theme" == "dark" ]]; then
        gtk_theme="Adwaita-dark"
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    else
        gtk_theme="Adwaita"
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
    fi
    
    # Apply GTK theme
    gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme"
    
    # Update GTK4 config
    gtk4_config="$HOME/.config/gtk-4.0/settings.ini"
    if [[ -f "$gtk4_config" ]]; then
        sed -i "s/^gtk-application-prefer-dark-theme=.*/gtk-application-prefer-dark-theme=$([ "$new_theme" == "dark" ] && echo "true" || echo "false")/" "$gtk4_config"
    fi
}

# Function to apply theme to Qt5/Qt6 applications
apply_qt_theme() {
    local qt_style qt_theme
    
    if [[ "$new_theme" == "dark" ]]; then
        qt_style="Fusion"
        qt_theme="dark"
    else
        qt_style="Fusion"
        qt_theme="light"
    fi
    
    # Update Qt5 config
    qt5ct_config="$HOME/.config/qt5ct/qt5ct.conf"
    if [[ -f "$qt5ct_config" ]]; then
        sed -i "s/^style=.*/style=$qt_style/" "$qt5ct_config"
        sed -i "s/^custom_palette=.*/custom_palette=$([ "$new_theme" == "dark" ] && echo "true" || echo "false")/" "$qt5ct_config"
    fi
    
    # Update Qt6 config
    qt6ct_config="$HOME/.config/qt6ct/qt6ct.conf"
    if [[ -f "$qt6ct_config" ]]; then
        sed -i "s/^style=.*/style=$qt_style/" "$qt6ct_config"
        sed -i "s/^custom_palette=.*/custom_palette=$([ "$new_theme" == "dark" ] && echo "true" || echo "false")/" "$qt6ct_config"
    fi
}

# Apply Hyprpanel theme
apply_hyprpanel_theme() {
    if [[ -f "$HYPRPANEL_CONFIG" ]]; then
        if [[ "$new_theme" == "dark" ]]; then
            sed -i 's/theme = "light"/theme = "dark"/' "$HYPRPANEL_CONFIG"
        else
            sed -i 's/theme = "dark"/theme = "light"/' "$HYPRPANEL_CONFIG"
        fi
        
        # Restart Hyprpanel if it's running
        if pgrep -x "hyprpanel" >/dev/null; then
            pkill -x "hyprpanel"
            hyprpanel &
        fi
    fi
}

# Apply themes to all applications
apply_hyprland_theme
apply_kitty_theme
apply_ghostty_theme
apply_gtk_theme
apply_qt_theme
apply_hyprpanel_theme

# Restart Waybar to apply the theme
if pgrep -x "waybar" >/dev/null; then
    "$HYPR_CONFIG_DIR/scripts/reload.sh"
fi

# Notify the user
notify-send -i "$theme_icon" "Theme Changed" "$notification_text"

exit 0 
