#!/usr/bin/env bash

set -euo pipefail

hyprctl dispatch cyclenext
hyprctl dispatch bringactivetotop
hyprctl dispatch centerwindow
