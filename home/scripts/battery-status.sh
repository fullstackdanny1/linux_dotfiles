#!/usr/bin/env bash
# Notificare rapidă cu starea bateriei (declanșată la click pe modulul de baterie)
set -euo pipefail

info=$(upower -i /org/freedesktop/UPower/devices/battery_BAT1 2>/dev/null || upower -i "$(upower -e 2>/dev/null | grep -i battery | head -n1)" 2>/dev/null || true)

if [ -z "$info" ]; then
  notify-send --app-name=baterie "Baterie" "Informațiile despre baterie nu sunt disponibile."
  exit 0
fi

percentage=$(echo "$info" | awk '/percentage:/ {print $2}' | head -n1)
state=$(echo "$info" | awk '/state:/ {print $2}' | head -n1)
time_remaining=$(echo "$info" | grep -E 'time to (empty|full):' | head -n1 | sed -E 's/.*time to (empty|full):[[:space:]]*//' || true)

[ -z "$percentage" ] && percentage="N/A"
[ -z "$time_remaining" ] && time_remaining="calculare..."

case "$state" in
  charging) state_ro="În încărcare" ;;
  discharging) state_ro="Descărcare" ;;
  fully-charged) state_ro="Complet încărcată" ;;
  pending-charge) state_ro="În așteptare" ;;
  pending-discharge) state_ro="În așteptare" ;;
  *) state_ro="${state:-necunoscută}" ;;
esac

notify-send --app-name=baterie --icon=battery "Stare Baterie: $percentage" "Stare: $state_ro\nTimp estimat: $time_remaining"
