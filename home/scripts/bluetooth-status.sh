#!/usr/bin/env bash
# Verifică starea bluetooth pentru bara i3status-rust:
# 󰂱 (conectat), 󰂯 (activ/pornit), 󰂲 (oprit/blocat)
set -euo pipefail

if bluetoothctl info 2>/dev/null | grep -q 'Connected: yes'; then
  printf '󰂱\n'
elif bluetoothctl show 2>/dev/null | grep -q 'Powered: yes'; then
  printf '󰂯\n'
else
  printf '󰂲\n'
fi
