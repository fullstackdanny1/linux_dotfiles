# Suspend la idle doar pe baterie.
for online in /sys/class/power_supply/*/online; do
  [ -e "$online" ] || continue
  supply="${online%/online}"
  if [ "$(cat "$supply/type")" = Mains ] && [ "$(cat "$online")" = 1 ]; then
    exit 0
  fi
done
systemctl suspend
