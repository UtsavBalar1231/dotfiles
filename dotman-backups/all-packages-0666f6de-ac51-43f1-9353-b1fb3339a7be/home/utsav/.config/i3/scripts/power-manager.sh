#!/usr/bin/env bash

if command -v xfce4-power-manager-settings &>/dev/null; then
	POWERMANAGER="xfce4-power-manager-settings"
elif command -v mate-power-preferences &>/dev/null; then
	POWERMANAGER="mate-power-preferences"
elif command -v gnome-power-preferences &>/dev/null; then
	POWERMANAGER="gnome-power-preferences"
elif command -v powerkit &>/dev/null; then
	POWERMANAGER="powerkit"
elif command -v cinnamon-settings power &>/dev/null; then
	POWERMANAGER="cinnamon-settings power"
elif command -v unity-control-center &>/dev/null; then
	POWERMANAGER="unity-control-center power"
elif command -v systemsettings5 &>/dev/null; then
	POWERMANAGER="systemsettings5"
elif command -v lxqt-config-powermanagement &>/dev/null; then
	POWERMANAGER="lxqt-config-powermanagement"
else
	echo "No power manager found"
	exit 1
fi

$POWERMANAGER &
nofify-send "Started power manager: $POWERMANAGER"
