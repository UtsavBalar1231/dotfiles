#!/usr/bin/env bash
# Power menu. Everything except lock must be pressed twice within 4s.
#   power.sh press lock|logout|suspend|hibernate|reboot|shutdown
here=$(dirname "$(readlink -f "$0")")
if [[ -z $POWER_DETACHED ]]; then
  POWER_DETACHED=1 setsid -f "$0" "$@" >/dev/null 2>&1
  exit 0
fi

run() {
  case $1 in
    lock) swaylock -f ;;
    logout) niri msg action quit --skip-confirmation ;;
    suspend) systemctl suspend ;;
    hibernate) systemctl hibernate ;;
    reboot) systemctl reboot ;;
    shutdown) systemctl poweroff ;;
  esac
}

action=$2
[[ $1 == press && -n $action ]] || { echo "usage: $0 press ACTION" >&2; exit 1; }
if [[ $action == lock || $(eww get power_pending) == "$action" ]]; then
  "$here/panel.sh" close
  sleep 0.35
  run "$action"
else
  eww update power_pending="$action"
  sleep 4
  [[ $(eww get power_pending) == "$action" ]] && eww update power_pending=""
fi
