#!/usr/bin/env bash
# Popup manager: at most one popup is open, each over a click-away backdrop on the focused output.
#   panel.sh toggle NAME [ARG] | open NAME [ARG] | close
#   ARG: clipboard filter (all|text|image) or control centre page (wifi|bt)
POPUPS=" launcher drawer clipboard control calendar power wallpapers "
EXIT_ANIMATION_S=0.14 # $t-exit in scss/_tokens.scss
here=$(dirname "$(readlink -f "$0")")

# eww kills handler commands after their :timeout (200ms default); detach so the
# exit animation and the close that follows it always complete.
if [[ -z $PANEL_DETACHED ]]; then
  PANEL_DETACHED=1 setsid -f "$0" "$@" >/dev/null 2>&1
  exit 0
fi
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/eww-panel.lock"
flock 9

# eww widgets cannot see key presses, so popup keys are bound in niri, but only while a popup
# is open: the include is rewritten here and niri reloads it. Escape closes any popup; in the
# launcher and drawer Alt+Tab cycles the sort (normal binds outrank niri's window switcher,
# which gets Alt+Tab back on close). A stale bind heals itself, because pressing Escape runs
# `panel.sh close`, which clears it.
ESCAPE_KDL=${XDG_CONFIG_HOME:-$HOME/.config}/niri/eww-escape.kdl
popup_binds() { # popup_binds [POPUP]; no POPUP clears the binds
  local tmp="$ESCAPE_KDL.tmp"
  echo '// Managed by ~/.config/eww/scripts/panel.sh: popup keys, bound only while an eww popup is open.' >"$tmp"
  if [[ -n $1 ]]; then
    echo 'binds {'
    echo '    Escape hotkey-overlay-title=null { spawn "~/.config/eww/scripts/panel.sh" "close"; }'
    if [[ $1 == launcher || $1 == drawer ]]; then
      echo '    Alt+Tab hotkey-overlay-title=null { spawn "~/.config/eww/scripts/apps.py" "sort" "next"; }'
      echo '    Alt+Shift+Tab hotkey-overlay-title=null { spawn "~/.config/eww/scripts/apps.py" "sort" "prev"; }'
    fi
    echo '}'
  fi >>"$tmp"
  cmp -s "$tmp" "$ESCAPE_KDL" && rm -f "$tmp" || mv -f "$tmp" "$ESCAPE_KDL"
}

current() {
  eww active-windows 2>/dev/null | awk -F': ' '{print $2}' | while read -r w; do
    [[ $POPUPS == *" $w "* ]] && { echo "$w"; break; }
  done
}

close_all() {
  local cur; cur=$(current)
  if [[ -n $cur ]]; then
    eww update closing="$cur"
    sleep "$EXIT_ANIMATION_S"
    eww close "$cur" >/dev/null 2>&1
    eww update closing="" reveal="" cc_page=main wifi_pick="" wifi_pick_label="" power_pending=""
  fi
  eww active-windows 2>/dev/null | grep -q '^backdrop:' && eww close backdrop >/dev/null 2>&1
  popup_binds
}

open() {
  local name=$1 arg=$2 out
  out=$(niri msg --json focused-output | jq -r '.name // empty')
  case $name in
    launcher | drawer) "$here/apps.py" reset ;;
    clipboard) "$here/clip.py" refresh "${arg:-all}" ;;
    control) "$here/net.sh" list 9>&- & [[ -n $arg ]] && eww update cc_page="$arg" ;;
    wallpapers) "$here/wall.py" q "" ;;
  esac
  popup_binds "$name"
  eww open backdrop --screen "$out"
  eww open "$name" --screen "$out"
  eww update reveal="$name"
}

case $1 in
  toggle) cur=$(current); close_all; [[ $cur != "$2" ]] && open "$2" "$3" ;;
  open) close_all; open "$2" "$3" ;;
  close) close_all ;;
  *) echo "usage: $0 toggle NAME | open NAME | close" >&2; exit 1 ;;
esac
