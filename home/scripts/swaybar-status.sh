# status_command pentru swaybar: i3status + timerul (doar când rulează) + layout-ul de tastatură.
# Din Nix: I3STATUS_CONFIG, MUTED, ACCENT (culori #rrggbb).

layout() {
  swaymsg -t get_inputs | jq -r '
    first(.[] | select(.type == "keyboard") | .xkb_active_layout_name) // ""
    | if startswith("Romanian") then "RO" elif . == "" then "" else "US" end'
}

extra_blocks() {
  local t l
  t=$(timer status --plain 2>/dev/null || true)
  l=$(layout 2>/dev/null || true)
  jq -nc --arg t "$t" --arg l "$l" --arg accent "$ACCENT" --arg muted "$MUTED" '
    [ (select($t != "") | {name: "timer", full_text: "timer \($t)", color: $accent}),
      (select($l != "") | {name: "layout", full_text: $l, color: $muted}) ]'
}

i3status -c "$I3STATUS_CONFIG" | {
  read -r header && echo "$header"   # {"version":1}
  read -r open && echo "$open"       # [
  while read -r line; do
    prefix=""
    if [[ $line == ,* ]]; then prefix=","; line="${line#,}"; fi
    extra=$(extra_blocks)
    echo "$prefix$(jq -c --argjson extra "$extra" '$extra + .' <<<"$line")"
  done
}
