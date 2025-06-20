#!/usr/bin/env bash

LOG_FILE="/tmp/hints.log"

HINTS_BIN=$(which hints)

if [ -z "$HINTS_BIN" ]; then
	if [ -f "/home/utsav/.local/bin/hints" ]; then
		HINTS_BIN="/home/utsav/.local/bin/hints"
	else
		echo "hints not found" >> $LOG_FILE
		notify-send "hints not found"
		exit 1
	fi
fi

notify-send "Mouse mode started (Esc to exit)"
$HINTS_BIN "$@" >> $LOG_FILE 2>&1
