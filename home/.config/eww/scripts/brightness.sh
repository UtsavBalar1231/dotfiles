#!/usr/bin/env bash
# DDC/CI monitor brightness. ddcutil is slow (~0.5s), so the value is cached and writes are coalesced.
#   brightness.sh get | poll | set N | up | down
# `get` is the fast cached read used by keys; `poll` (the bar's defpoll) re-reads the monitor
# when the cache is older than STALE_MIN, so changes made with the monitor's own buttons show up.
CACHE=${XDG_RUNTIME_DIR:-/tmp}/eww-brightness
STEP=5
STALE_MIN=5

probe() {
  local v
  v=$(ddcutil getvcp 10 --brief 2>/dev/null | awk '{print $4}')
  [[ $v =~ ^[0-9]+$ ]] && echo "$v" >"$CACHE"
}

get() {
  [[ -s $CACHE ]] || probe
  [[ -s $CACHE ]] || echo 50 >"$CACHE"
  cat "$CACHE"
}

set_to() {
  local v=$1
  ((v < 0)) && v=0
  ((v > 100)) && v=100
  echo "$v" >"$CACHE"
  eww update brightness="$v" 2>/dev/null
  pkill -f 'ddcutil setvcp 10' 2>/dev/null
  setsid -f ddcutil setvcp 10 "$v" --noverify >/dev/null 2>&1
}

case $1 in
  get) get ;;
  poll) [[ -n $(find "$CACHE" -mmin -"$STALE_MIN" 2>/dev/null) ]] || probe; get ;;
  set) set_to "${2%.*}" ;;
  up) set_to $(($(get) + STEP)) ;;
  down) set_to $(($(get) - STEP)) ;;
  *) echo "usage: $0 get|poll|set N|up|down" >&2; exit 1 ;;
esac
