#!/bin/sh

# 1. Wifi Module (Blue)
wifi_interface=$(ip route | grep '^default' | awk '{print $5}' | grep '^w')
if [ -n "$wifi_interface" ]; then
    essid=$(nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | grep '^yes' | cut -d: -f2)
    net_text="wifi: ${essid:-on}"
else
    net_text="wifi: off"
fi
wifi_out="<span foreground='#83a598'>$net_text</span>"

# 2. Volume Module (Light Green)
muted=$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | awk '{print $2}')
if [ "$muted" = "yes" ]; then
    vol_text="vol: mute"
else
    vol=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | awk -F '/' '{print $2}' | head -n 1 | sed 's/[ %]//g')
    vol_text="vol: ${vol:-0}%"
fi
vol_out="<span foreground='#b8bb26'>$vol_text</span>"

# 3. Battery Module (Yellow)
BAT_DIR=""
for dir in /sys/class/power_supply/BAT*; do [ -d "$dir" ] && BAT_DIR="$dir" && break; done
if [ -n "$BAT_DIR" ] && [ -f "$BAT_DIR/capacity" ]; then
    cap=$(cat "$BAT_DIR/capacity")
    bat_text="bat: $cap%"
else
    bat_text="bat: none"
fi
bat_out="<span foreground='#fabd2f'>$bat_text</span>"

# 4. Clock Module (Red - Clean HH:MM)
clock_text=$(date '+%H:%M')
clock_out="<span foreground='#fb4934'>$clock_text</span>"

# 5. Output Construction (Spaces only, no symbols)
echo "   $wifi_out   $vol_out   $bat_out   $clock_out"
