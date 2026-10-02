# status_command pentru swaybar: i3status + timerul (doar când rulează) + layout-ul
# de tastatură. Toate blocurile primesc același separator și aceeași spațiere.
# Din Nix: I3STATUS_CONFIG, TIMER_ICON/TIMER_COLOR, LAYOUT_ICON/LAYOUT_COLOR.

layout() {
  swaymsg -t get_inputs | jq -r '
    first(.[] | select(.type == "keyboard") | .xkb_active_layout_name) // ""
    | if startswith("Romanian") then "RO" elif . == "" then "" else "US" end'
}

extra_blocks() {
  local t l
  t=$(timer status --plain 2>/dev/null || true)
  l=$(layout 2>/dev/null || true)
  jq -nc --arg t "$t" --arg l "$l" \
    --arg ti "$TIMER_ICON" --arg tc "$TIMER_COLOR" \
    --arg li "$LAYOUT_ICON" --arg lc "$LAYOUT_COLOR" '
    def esc: gsub("&"; "&amp;") | gsub("<"; "&lt;") | gsub(">"; "&gt;");
    def icon($glyph; $color): "<span color=\"\($color)\">\($glyph)</span>";
    [ (select($t != "") | {name: "timer", full_text: "\(icon($ti; $tc)) \($t | esc)"}),
      (select($l != "") | {name: "layout", full_text: "\(icon($li; $lc)) \($l)"}) ]'
}

i3status -c "$I3STATUS_CONFIG" | {
  read -r header && echo "$header"   # {"version":1}
  read -r open && echo "$open"       # [
  while read -r line; do
    prefix=""
    if [[ $line == ,* ]]; then prefix=","; line="${line#,}"; fi
    extra=$(extra_blocks)
    echo "$prefix$(jq -c --argjson extra "$extra" '
      ($extra + .)
      | map(. + {markup: "pango", separator: true, separator_block_width: 29})
      | .[-1].separator = false' <<<"$line")"
  done
}
