#!/bin/bash
# Rofi clipboard manager - clean dmenu with keybinds
# Ctrl+X = clear all, Ctrl+I = clear images

THEME="$HOME/.config/rofi/themes/clipboard.rasi"

for cmd in cliphist rofi wl-copy notify-send; do
    command -v "$cmd" &>/dev/null || { notify-send -u critical "Missing: $cmd"; exit 1; }
done

if [ "$(cliphist list | wc -l)" -eq 0 ]; then
    notify-send "Clipboard" "History is empty"
    exit 0
fi

# Build list - action at top, then clipboard items
build_list() {
    echo "󰆴 Clear History"
    cliphist list | while IFS= read -r line; do
        [[ "$line" == *"[[ binary data"* ]] && echo "󰋩 $line" || echo "󰆏 $line"
    done
}

selected=$(build_list | rofi -dmenu \
    -theme "$THEME" \
    -p "Clipboard" \
    -kb-custom-1 "Control+x" \
    -kb-custom-2 "Control+i")

ret=$?

# Keybind handlers
if [ $ret -eq 10 ]; then
    cliphist wipe
    notify-send "Clipboard" "History cleared"
    exit 0
elif [ $ret -eq 11 ]; then
    count=$(cliphist list | grep -c '\[\[ binary data' || echo 0)
    cliphist list | grep '\[\[ binary data' | cliphist delete-query 2>/dev/null
    notify-send "Clipboard" "Cleared $count images"
    exit 0
fi

[ -z "$selected" ] && exit 0

# Handle clear action
if [[ "$selected" == "󰆴 Clear History" ]]; then
    cliphist wipe
    notify-send "Clipboard" "History cleared"
    exit 0
fi

# Copy selected item - strip icon prefix
entry="${selected#󰋩 }"
entry="${entry#󰆏 }"
echo "$entry" | cliphist decode | wl-copy
notify-send "Clipboard" "Copied" -t 1500
