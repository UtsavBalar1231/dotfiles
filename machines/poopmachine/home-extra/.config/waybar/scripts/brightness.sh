#!/bin/bash

# Brightness control script with caching and signaling for instant feedback
# Optimized for external monitors (ddcutil)

CACHE_FILE="/tmp/waybar_brightness"
STEP=5
SIGNAL=10
VCP=10
I2C_BUS=$(ddcutil detect 2>/dev/null | awk '/I2C bus/{print $3}' | cut -f2- -d-)

# Initialize cache if missing
if [ ! -f "$CACHE_FILE" ]; then
	if [ -n "$I2C_BUS" ]; then
    	val=$(ddcutil getvcp $VCP --brief --noverify 2>/dev/null | awk '{print $4}')
    else
    	val=$(ddcutil --bus "$I2C_BUS" getvcp $VCP --brief --noverify 2>/dev/null | awk '{print $4}')
    fi

    [[ "$val" =~ ^[0-9]+$ ]] || val=50
    echo "$val" > "$CACHE_FILE"
fi

get_cache() {
    cat "$CACHE_FILE"
}

set_cache() {
    echo "$1" > "$CACHE_FILE"
    # Trigger waybar update
    pkill -RTMIN+$SIGNAL waybar
}

sync_hardware() {
    local val=$1
    # Kill any existing ddcutil processes to avoid I2C congestion during fast scrolling
    pkill ddcutil 2>/dev/null
    if [ -n "$I2C_BUS" ]; then
        ddcutil setvcp $VCP "$val" --brief --noverify >/dev/null 2>&1 &
    else
        ddcutil --bus "$I2C_BUS" setvcp $VCP "$val" --brief --noverify >/dev/null 2>&1 &
    fi
}

case "$1" in
    up)
        curr=$(get_cache)
        new=$((curr + STEP))
        [ $new -gt 100 ] && new=100
        set_cache "$new"
        sync_hardware "$new"
        ;;
    down)
        curr=$(get_cache)
        new=$((curr - STEP))
        [ $new -lt 0 ] && new=0
        set_cache "$new"
        sync_hardware "$new"
        ;;
    waybar)
        val=$(get_cache)
        echo "{\"text\": \"$val%\", \"tooltip\": \"Brightness: $val%\"}"
        ;;
    *)
        echo "Usage: $0 {up|down|waybar}"
        exit 1
        ;;
esac
