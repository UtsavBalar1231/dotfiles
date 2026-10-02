#!/usr/bin/env bash
# Start the eww shell: a bar on every niri output, plus notification popups on the focused one.
# eww only writes its own log file when started from a TTY, so the daemon log goes to
# ~/.cache/eww/daemon.log explicitly.
cd "$(dirname "$(readlink -f "$0")")" || exit 1
LOG=${XDG_CACHE_HOME:-$HOME/.cache}/eww/daemon.log
mkdir -p "$(dirname "$LOG")"

if ! timeout 2 eww active-windows >/dev/null 2>&1; then
  setsid -f eww daemon --no-daemonize >"$LOG" 2>&1 </dev/null
  for _ in $(seq 50); do timeout 1 eww active-windows >/dev/null 2>&1 && break; sleep 0.1; done
fi
eww close-all >/dev/null 2>&1
PANEL_DETACHED=1 ./scripts/panel.sh close
./scripts/wall.py ping  # starts the wallpaper daemon, which starts awww-daemon and restores the wallpaper
for out in $(niri msg --json outputs | jq -r 'keys[]'); do
  eww open bar --id "bar-$out" --arg monitor="$out"
done
eww open notif-popups --screen "$(niri msg --json focused-output | jq -r '.name')"
