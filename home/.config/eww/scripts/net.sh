#!/usr/bin/env bash
# NetworkManager state for `deflisten net` (`net.sh watch`); the control centre's Wi-Fi page uses:
#   net.sh list | rescan | toggle | connect IDX | pick IDX | connect-pick (password on stdin)
# Rows pass an index into the last list, never an SSID, so names with quotes cannot reach a shell.
LIST=${XDG_RUNTIME_DIR:-/tmp}/eww-wifi.json
REFRESH_S=20 # no NetworkManager event exists for signal strength, so re-read periodically

state() {
  local type conn dev signal=0
  IFS=: read -r type _ conn dev < <(nmcli -t -f TYPE,STATE,CONNECTION,DEVICE device 2>/dev/null | grep -E '^(ethernet|wifi):connected' | sort | head -1)
  conn=${conn//\\:/:}
  [[ $type == wifi ]] && signal=$(nmcli -t -f IN-USE,SIGNAL device wifi list --rescan no 2>/dev/null | awk -F: '$1=="*"{print $2; exit}')
  jq -nc --arg t "${type:-none}" --arg c "$conn" --arg d "$dev" --arg s "${signal:-0}" --arg r "$(nmcli radio wifi)" \
    '{type: $t, name: ($c | gsub("\\\\"; "\\\\\\\\")), dev: $d, signal: ($s | tonumber? // 0), wifi_on: ($r == "enabled")}'
}

list() {
  local known; known=$(nmcli -t -f NAME connection show 2>/dev/null)
  nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY device wifi list --rescan no 2>/dev/null |
    jq -Rsc --arg known "$known" '
      ($known | split("\n") | map(gsub("\\\\:"; ":"))) as $k
      | [split("\n")[] | select(length > 0) | gsub("\\\\:"; "\u0001") | split(":") | map(gsub("\u0001"; ":"))
         | {active: (.[0] == "*"), ssid: .[1], signal: (.[2] | tonumber? // 0), secure: (.[3] != "" and .[3] != "--")}
         | select(.ssid != "") | . + {known: (.ssid as $s | $k | index($s) != null)}]
      | group_by(.ssid) | map(max_by(.signal) + {active: (map(.active) | any)}) | sort_by(-(.active | if . then 1000 else 0 end) - .signal) | .[:14]
      | to_entries | map(.value + {i: .key, label: (.value.ssid | gsub("\\\\"; "\\\\\\\\"))})'
}

ssid_at() { [[ $1 =~ ^[0-9]+$ ]] && jq -r --argjson i "$1" '.[$i].ssid // empty' "$LIST" 2>/dev/null; }

last=""
emit() {
  local cur
  cur=$(state) || return 0
  [[ $cur == "$last" ]] && return 0
  printf '%s\n' "$cur" || exit 0 # eww closed our stdout: stop instead of looping forever
  last=$cur
}

case ${1:-watch} in
  watch)
    # The monitor is owned through a process substitution and killed on exit, so it never
    # outlives this script (nmcli ignores SIGPIPE and would otherwise run forever).
    mon=
    trap '[[ -n $mon ]] && kill "$mon" 2>/dev/null' EXIT
    start_monitor() { exec 3< <(nmcli monitor 2>/dev/null); mon=$!; }
    emit
    start_monitor
    while :; do
      if read -r -u 3 -t "$REFRESH_S" _; then
        while read -r -u 3 -t 0.3 _; do :; done
      elif (($? <= 128)); then
        kill "$mon" 2>/dev/null; sleep 2; start_monitor # NetworkManager restarted: reopen
      fi
      emit
    done ;;
  list)
    l=$(list)
    printf '%s\n' "$l" >"$LIST.tmp" && mv -f "$LIST.tmp" "$LIST"
    eww update "wifi_list=$l" ;;
  rescan) setsid -f sh -c "nmcli device wifi rescan; sleep 3; '$0' list" >/dev/null 2>&1 ;;
  toggle) [[ $(nmcli radio wifi) == enabled ]] && setsid -f nmcli radio wifi off || setsid -f nmcli radio wifi on ;;
  pick) # a secured network we have no profile for: show the password field for row IDX
    label=$(jq -r --argjson i "$2" '.[$i].label // empty' "$LIST" 2>/dev/null)
    [[ -n $label ]] && eww update "wifi_pick=$2" "wifi_pick_label=$label" ;;
  connect)
    ssid=$(ssid_at "$2")
    [[ -n $ssid ]] && setsid -f "$0" _connect "$ssid" </dev/null >/dev/null 2>&1 ;;
  connect-pick)
    pass=$(cat)
    ssid=$(ssid_at "$(eww get wifi_pick)")
    eww update wifi_pick= wifi_pick_label=
    [[ -n $ssid ]] && printf '%s' "$pass" | setsid -f "$0" _connect "$ssid" >/dev/null 2>&1 ;;
  _connect)
    ssid=$2
    pass=$(cat)
    if nmcli -t -f NAME connection show | grep -qxF -- "$ssid"; then
      out=$(nmcli connection up id "$ssid" 2>&1)
    elif [[ -n $pass ]]; then
      out=$(nmcli device wifi connect "$ssid" password "$pass" 2>&1)
    else
      out=$(nmcli device wifi connect "$ssid" 2>&1)
    fi
    notify-send -a Network -i network-wireless "Wi-Fi" "${out:0:200}"
    "$0" list ;;
esac
