#!/usr/bin/env bash
# Niri-aware XDG Desktop Portal startup script.
# Ensures portals are properly managed via systemd for reliable screen sharing.

# Export desktop identity so the portal system picks up niri-portals.conf
export XDG_CURRENT_DESKTOP=niri
export XDG_SESSION_TYPE=wayland

# Stop any portal processes that may have been started outside systemd
systemctl --user stop xdg-desktop-portal-gnome.service 2>/dev/null
systemctl --user stop xdg-desktop-portal-gtk.service 2>/dev/null
systemctl --user stop xdg-desktop-portal.service 2>/dev/null

# Small delay to let D-Bus names release
sleep 1

# Start backends FIRST (order matters — backends must register before the frontend queries them)
systemctl --user start xdg-desktop-portal-gnome.service
systemctl --user start xdg-desktop-portal-gtk.service

# Small delay to let backends register on D-Bus
sleep 1

# Start the main portal frontend last
systemctl --user start xdg-desktop-portal.service
