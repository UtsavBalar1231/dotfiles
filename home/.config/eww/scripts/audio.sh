#!/usr/bin/env bash
# PipeWire sink/source state for `deflisten audio`, one JSON line per change.
# eww never restarts a listener that exits, so a PipeWire restart (which ends
# `pactl subscribe`) reopens the subscription instead of ending this script.
state() {
  jq -nc \
    --arg s "$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)" \
    --arg m "$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null)" \
    --arg d "$(wpctl inspect @DEFAULT_AUDIO_SINK@ 2>/dev/null | sed -n 's/.*node.description = "\(.*\)"/\1/p' | head -1)" '
    def vol: ((capture("Volume: (?<v>[0-9.]+)").v // "0") | tonumber * 100 | round);
    {vol: ($s | vol), muted: ($s | test("MUTED")), mic: ($m | vol), mic_muted: ($m | test("MUTED")),
     sink: $d, headphones: ($d | test("(?i)head|ear|buds|airpods"))}'
}

last=""
emit() {
  local cur
  cur=$(state) || return 0
  [[ $cur == "$last" ]] && return 0
  printf '%s\n' "$cur" || exit 0 # eww closed our stdout: stop instead of looping forever
  last=$cur
}

# pactl is owned through a process substitution and killed on exit, so it never outlives
# this script (it ignores SIGPIPE and would otherwise run forever after eww crashes).
mon=
trap '[[ -n $mon ]] && kill "$mon" 2>/dev/null' EXIT

emit
while :; do
  exec 3< <(pactl subscribe 2>/dev/null)
  mon=$!
  while read -r -u 3 line; do
    case $line in
      *" on sink "* | *" on source "* | *" on server "* | *" on card "*)
        while read -r -u 3 -t 0.05 _; do :; done # one volume step is a burst of events
        emit ;;
    esac
  done
  kill "$mon" 2>/dev/null
  sleep 2
  emit
done
