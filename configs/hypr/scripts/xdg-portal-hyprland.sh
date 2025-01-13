#!/bin/sh

# Kill all possible running xdg-desktop-portals
sudo killall -e xdg-desktop-portal-hyprland
sudo killall -e xdg-desktop-portal-gnome
sudo killall -e xdg-desktop-portal-kde
sudo killall -e xdg-desktop-portal-lxqt
sudo killall -e xdg-desktop-portal-wlr
sudo killall -e xdg-desktop-portal-gtk
sudo killall -e xdg-desktop-portal

/usr/lib/xdg-desktop-portal-hyprland &
sleep 0.5

# Start xdg-desktop-portal-gtk
if [ -f /usr/lib/xdg-desktop-portal-gtk ] ;then
    /usr/lib/xdg-desktop-portal-gtk &
    sleep 0.5
fi

/usr/lib/xdg-desktop-portal &
sleep 0.5
