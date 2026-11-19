#!/usr/bin/env bash
# Afișare bară (iconiță colorată + procent), notificări sincronizate
# și oprire în 30s la <= 6% (anulabilă la conectarea încărcătorului).
set -euo pipefail

COLOR_GREEN="${BAT_COLOR_GREEN:-b8bb26}"        # >= 60% sau charging/full
COLOR_LIGHT_GREEN="${BAT_COLOR_LGREEN:-689d6a}"  # 30% - 59%
COLOR_YELLOW="${BAT_COLOR_YELLOW:-fabd2f}"    # 15% - 29%
COLOR_RED="${BAT_COLOR_RED:-fb4934}"          # <= 14%

bat_dir=$(find /sys/class/power_supply -maxdepth 1 -name 'BAT*' 2>/dev/null | head -n1 || true)
[ -n "$bat_dir" ] || exit 0

cap=$(cat "$bat_dir/capacity" 2>/dev/null || echo "")
status=$(cat "$bat_dir/status" 2>/dev/null || echo "")
[ -n "$cap" ] || exit 0

state_file="/tmp/bat_notified"
shutdown_pid_file="/tmp/bat_shutdown_pid"
last_notified=$(cat "$state_file" 2>/dev/null || echo "")

if [ "$status" = "Discharging" ]; then
  if [ "$cap" -le 6 ]; then
    if [ "$last_notified" != "6" ]; then
      notify-send -u critical --app-name=battery --icon=battery-caution \
        "Baterie critică ($cap%)" \
        "Sistemul se va stinge în 30 de secunde. Conectează încărcătorul pentru a anula."
      echo "6" > "$state_file"
      (
        sleep 30
        cur_status=$(cat "$bat_dir/status" 2>/dev/null || echo "")
        if [ "$cur_status" = "Discharging" ]; then
          systemctl poweroff
        fi
      ) >/dev/null 2>&1 &
      echo $! > "$shutdown_pid_file"
    fi
  elif [ "$cap" -le 14 ]; then
    if [ "$last_notified" != "14" ] && [ "$last_notified" != "6" ]; then
      notify-send -u critical --app-name=battery --icon=battery-caution \
        "Baterie critică ($cap%)" \
        "Nivel critic — conectează urgent încărcătorul."
      echo "14" > "$state_file"
    fi
  elif [ "$cap" -le 29 ]; then
    if [ -z "$last_notified" ]; then
      notify-send -u normal --app-name=battery --icon=battery-low \
        "Baterie scăzută ($cap%)" \
        "Nivelul bateriei a scăzut sub 30%."
      echo "29" > "$state_file"
    fi
  fi
else
  if [ -f "$shutdown_pid_file" ]; then
    kill "$(cat "$shutdown_pid_file" 2>/dev/null)" 2>/dev/null || true
    rm -f "$shutdown_pid_file"
    notify-send -u low --app-name=battery --icon=battery \
      "Încărcare conectată" "Oprirea automată a fost anulată."
  fi
  rm -f "$state_file"
fi

if [ "$status" = "Charging" ] || [ "$status" = "Full" ] || [ "$cap" -ge 60 ]; then
  color="$COLOR_GREEN"
  glyph="󰁹"
elif [ "$cap" -ge 30 ]; then
  color="$COLOR_LIGHT_GREEN"
  glyph="󰂀"
elif [ "$cap" -ge 15 ]; then
  color="$COLOR_YELLOW"
  glyph="󰁾"
else
  color="$COLOR_RED"
  glyph="󰁺"
fi

printf "<span color='#%s'>%s</span> %s%%\n" "$color" "$glyph" "$cap"
