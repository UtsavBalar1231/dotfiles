#!/usr/bin/env bash

pkill waybar && hyprctl dispatch exec waybar 

# Kill wallpaper-slideshow.sh and restart it
pkill -f wallpaper-slideshow.sh && ~/.config/hypr/scripts/wallpaper-slideshow.sh &
