# screenshot {screen|area|window|annotate|delayed}
# Captură imediată sau întârziată, pentru fotografierea meniurilor Fuzzel.
dir="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
mkdir -p "$dir"
file="$dir/$(date +%Y-%m-%d_%H-%M-%S).png"

mode="${1:-}"
delay=0

if [ "$mode" = "--delay" ]; then
  [ "$#" -ge 3 ] || { echo "usage: screenshot --delay <seconds> {screen|area|window|annotate}" >&2; exit 1; }
  delay="$2"
  mode="$3"
elif [ "$mode" = "delayed" ]; then
  delay="${2:-3}"
  mode="${3:-area}"
fi

case "$delay" in
  ''|*[!0-9]*) echo "delay must be a non-negative integer" >&2; exit 1 ;;
esac

[ "$delay" -gt 0 ] && sleep "$delay"

case "$mode" in
  screen)
    output=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | .name')
    grim -o "$output" "$file"
    ;;
  area)
    geometry=$(slurp) || exit 0
    grim -g "$geometry" "$file"
    ;;
  window)
    geometry=$(swaymsg -t get_tree | jq -r '.. | objects | select(.focused? == true) | .rect | "\(.x),\(.y) \(.width)x\(.height)"')
    grim -g "$geometry" "$file"
    ;;
  annotate)
    geometry=$(slurp) || exit 0
    GSK_RENDERER=cairo grim -g "$geometry" - | GSK_RENDERER=cairo satty --filename - --output-filename "$file" --copy-command wl-copy
    ;;
  *) echo "usage: screenshot {screen|area|window|annotate|delayed}" >&2; exit 1 ;;
esac

if [ -f "$file" ]; then
  wl-copy --type image/png <"$file"
  notify-send --app-name=screenshot --icon="$file" "Captură salvată" "$file"
fi
