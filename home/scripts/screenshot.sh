# screenshot {screen|area|window|annotate}
# Salvează în ~/Pictures/Screenshots și copiază în clipboard; annotate deschide satty.
dir="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
mkdir -p "$dir"
file="$dir/$(date +%Y-%m-%d_%H-%M-%S).png"

case "${1:-}" in
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
    # Fără --early-exit: utilizatorul salvează/adnotează și închide Satty manual.
    # GTK_USE_PORTAL dezactivează portalurile GTK pentru acest dialogless flow.
    grim -g "$geometry" - | GTK_USE_PORTAL=0 satty --filename - --output-filename "$file" --copy-command wl-copy
    ;;
  *) echo "usage: screenshot {screen|area|window|annotate}" >&2; exit 1 ;;
esac

# La annotate, notificarea apare după închiderea manuală și doar dacă s-a salvat.
if [ -f "$file" ]; then
  wl-copy --type image/png <"$file"
  notify-send --app-name=screenshot --icon="$file" "Captură salvată" "$file"
fi
