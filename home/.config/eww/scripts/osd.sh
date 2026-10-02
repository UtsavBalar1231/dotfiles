#!/usr/bin/env bash
# Media keys: apply the change, then flash the OSD on the focused output for ~1.5s.
#   osd.sh vol-up|vol-down|vol-mute|mic-mute|bright-up|bright-down
here=$(dirname "$(readlink -f "$0")")
TOKEN=${XDG_RUNTIME_DIR:-/tmp}/eww-osd.token

# Bar scroll/right-click run this as an eww handler, which is killed after 200ms; detach so
# the OSD's open and its scheduled close always happen together.
if [[ -z $OSD_DETACHED ]]; then
  OSD_DETACHED=1 setsid -f "$0" "$@" >/dev/null 2>&1
  exit 0
fi

case $1 in
  vol-up) wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+ ;;
  vol-down) wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- ;;
  vol-mute) wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
  mic-mute) wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle ;;
  bright-up) "$here/brightness.sh" up ;;
  bright-down) "$here/brightness.sh" down ;;
  *) echo "usage: $0 vol-up|vol-down|vol-mute|mic-mute|bright-up|bright-down" >&2; exit 1 ;;
esac

volume_of() { wpctl get-volume "$1" 2>/dev/null | awk '{printf "%d %s", $2*100+0.5, ($3=="[MUTED]")?"true":"false"}'; }
case $1 in
  vol-*) kind=vol; read -r value muted < <(volume_of @DEFAULT_AUDIO_SINK@) ;;
  mic-*) kind=mic; read -r value muted < <(volume_of @DEFAULT_AUDIO_SOURCE@) ;;
  bright-*) kind=bright; value=$("$here/brightness.sh" get); muted=false ;;
esac
[[ $value =~ ^[0-9]+$ ]] || value=0
[[ $muted == true ]] || muted=false

eww update osd="{\"kind\":\"$kind\",\"value\":$value,\"muted\":$muted}"
token=$EPOCHREALTIME
echo "$token" >"$TOKEN"
if ! eww active-windows 2>/dev/null | grep -q '^osd:'; then
  eww open osd --screen "$(niri msg --json focused-output | jq -r '.name')"
fi
sleep 1.6
[[ $(cat "$TOKEN") == "$token" ]] && eww close osd
