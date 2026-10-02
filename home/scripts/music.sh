# Playerul (rmpc) stă pe workspace-ul 10. Îl pornește dacă nu rulează, altfel sare la el.
if swaymsg -t get_tree | jq -e '[.. | objects | select(.app_id? == "rmpc")] | length > 0' >/dev/null; then
  swaymsg '[app_id="^rmpc$"] focus' >/dev/null
else
  swaymsg 'workspace number 10' >/dev/null
  exec foot --app-id=rmpc rmpc
fi
