#!/usr/bin/env bash
# Mounted drives for `deflisten disks`: root, home and any removable/hotplug media.
# Refreshes on udisks mount/unmount events and every 30s for usage.
#   disks.sh             stream JSON (one line per change)
#   disks.sh open IDX    open drive IDX of the last listing in the file manager
#   disks.sh eject IDX   unmount removable drive IDX and power it off
# Widgets pass an index, never a path or label, so names with quotes or `$` cannot reach a shell.
REFRESH_S=30
LAST=${XDG_RUNTIME_DIR:-/tmp}/eww-disks.json

state() {
  lsblk -J -b -o PATH,LABEL,MOUNTPOINT,FSUSE%,FSSIZE,HOTPLUG,RM 2>/dev/null | jq -c '
    [.blockdevices[] | recurse(.children[]?)
     | select(.mountpoint != null and .mountpoint != "[SWAP]")
     | select(.mountpoint == "/" or .mountpoint == "/home" or .hotplug or .rm)
     | {path, mount: .mountpoint,
        removable: (.hotplug or .rm),
        name: ((if .mountpoint == "/" then "Root" elif .mountpoint == "/home" then "Home"
                else (.label // (.mountpoint | split("/") | last)) end) | gsub("\\\\"; "\\\\\\\\")),
        used: ((."fsuse%" // "0%") | rtrimstr("%") | tonumber),
        size: ((.fssize // 0) / 1e9 | floor)}]
    | sort_by(.removable, .mount) | to_entries | map(.value + {i: .key})'
}

field() { jq -r --argjson i "$1" ".[\$i].$2 // empty" "$LAST" 2>/dev/null; }

case $1 in
  open)
    [[ $2 =~ ^[0-9]+$ ]] || exit 1
    mount=$(field "$2" mount)
    [[ -n $mount ]] && niri msg action spawn -- xdg-open "$mount"
    exit 0 ;;
  eject)
    [[ $2 =~ ^[0-9]+$ ]] || exit 1
    [[ $(field "$2" removable) == true ]] || exit 0
    dev=$(field "$2" path)
    if out=$(udisksctl unmount -b "$dev" 2>&1); then
      udisksctl power-off -b "$dev" >/dev/null 2>&1
      notify-send -a Drives -i media-eject "Safe to remove" "$dev"
    else
      notify-send -a Drives -u critical -i dialog-error "Could not eject $dev" "${out:0:200}"
    fi
    exit 0 ;;
esac

last=""
emit() {
  local cur
  cur=$(state) || return 0
  [[ $cur == "$last" ]] && return 0
  printf '%s\n' "$cur" >"$LAST.tmp" && mv -f "$LAST.tmp" "$LAST"
  printf '%s\n' "$cur" || exit 0 # eww closed our stdout: stop instead of looping forever
  last=$cur
}

# The monitor is owned through a process substitution and killed on exit, so it never
# outlives this script (it ignores SIGPIPE and would otherwise run forever after a crash).
mon=
trap '[[ -n $mon ]] && kill "$mon" 2>/dev/null' EXIT
start_monitor() { exec 3< <(udisksctl monitor 2>/dev/null); mon=$!; }

emit
start_monitor
while :; do
  if read -r -u 3 -t "$REFRESH_S" _; then
    while read -r -u 3 -t 0.5 _; do :; done # one mount is a burst of lines; let it settle
  elif (($? <= 128)); then
    kill "$mon" 2>/dev/null; sleep 2; start_monitor # monitor ended (udisks restarted): reopen it
  fi
  emit
done
