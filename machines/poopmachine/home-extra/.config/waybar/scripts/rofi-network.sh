#!/bin/bash
# Rofi NetworkManager menu - two column layout using script mode
# Mode-switcher on left (commands), listview on right (networks)

THEME="$HOME/.config/rofi/themes/network.rasi"

# Dependency check
for cmd in nmcli rofi notify-send; do
    command -v "$cmd" &>/dev/null || { notify-send -u critical "Missing: $cmd"; exit 1; }
done

# Get WiFi state
get_state() {
    wifi_enabled=$(nmcli radio wifi)
    current=$(nmcli -t -f NAME connection show --active 2>/dev/null | head -n1)
}

# Output commands menu
show_commands() {
    get_state
    if [ "$wifi_enabled" = "enabled" ]; then
        echo "󰖪 Disable Wi-Fi"
    else
        echo "󰖩 Enable Wi-Fi"
    fi
    [ -n "$current" ] && echo "󰅙 Disconnect ($current)"
    echo "󰑓 Rescan Networks"
    echo "󱛃 Hidden Network"
    echo "󰒓 Network Settings"
}

# Commands script mode
commands_mode() {
    get_state

    # First call - show menu
    if [ -z "$1" ]; then
        show_commands
        return
    fi

    # Handle selection
    case "$1" in
        "󰖪 Disable Wi-Fi")
            nmcli radio wifi off
            notify-send "Network" "Wi-Fi disabled"
            show_commands  # refresh menu
            ;;
        "󰖩 Enable Wi-Fi")
            nmcli radio wifi on
            notify-send "Network" "Wi-Fi enabled"
            show_commands  # refresh menu
            ;;
        "󰅙 Disconnect"*)
            nmcli connection down "$current"
            notify-send "Network" "Disconnected"
            show_commands  # refresh menu
            ;;
        "󰑓 Rescan Networks")
            nmcli device wifi rescan &
            notify-send "Network" "Scanning... switch to networks tab"
            show_commands  # keep menu open
            ;;
        "󱛃 Hidden Network")
            ssid=$(rofi -dmenu -p "SSID" -theme-str 'window {width: 25%;}')
            [ -z "$ssid" ] && exit 0
            password=$(rofi -dmenu -password -p "Password" -theme-str 'window {width: 25%;}')
            if nmcli device wifi connect "$ssid" password "$password" hidden yes; then
                notify-send "Network" "Connected to $ssid"
            else
                notify-send -u critical "Network" "Failed to connect"
            fi
            ;;
        "󰒓 Network Settings")
            coproc ( nm-connection-editor &>/dev/null )
            ;;
    esac
}

# Networks script mode
networks_mode() {
    get_state

    # First call - show menu
    if [ -z "$1" ]; then
        if [ "$wifi_enabled" != "enabled" ]; then
            echo "Wi-Fi disabled"
            return
        fi

        nmcli -t -f SSID,SECURITY,SIGNAL device wifi list 2>/dev/null | \
            awk -F: 'NF>=3 && $1!="" {
                ssid=$1; sec=$2; sig=$3
                if (sig >= 75) bar="▂▄▆█"
                else if (sig >= 50) bar="▂▄▆_"
                else if (sig >= 25) bar="▂▄__"
                else bar="▂___"
                lock = (sec != "") ? "󰌾" : "󰌿"
                printf "%s %s %s\n", lock, bar, ssid
            }' | sort -u
        return
    fi

    # Handle selection
    [ "$1" = "Wi-Fi disabled" ] && exit 0

    # Extract SSID
    ssid=$(echo "$1" | sed -E 's/^[^ ]+ [▂▄▆█_]+ //')

    if nmcli connection show "$ssid" &>/dev/null; then
        if nmcli connection up "$ssid"; then
            notify-send "Network" "Connected to $ssid"
        fi
    else
        password=$(rofi -dmenu -password -p "Password" -theme-str 'window {width: 25%;}')
        [ -z "$password" ] && exit 0
        if nmcli device wifi connect "$ssid" password "$password"; then
            notify-send "Network" "Connected to $ssid"
        else
            notify-send -u critical "Network" "Failed to connect"
        fi
    fi
}

# Script mode dispatcher
case "$1" in
    --cmd) shift; commands_mode "$@" ;;
    --net) shift; networks_mode "$@" ;;
    *)
        # Main entry - launch rofi with both modi
        # Use icons as mode names since -display-* doesn't work for script modes
        rofi -show "󰤨" \
            -modi "󰛳:$0 --cmd,󰤨:$0 --net" \
            -theme "$THEME"
        ;;
esac
