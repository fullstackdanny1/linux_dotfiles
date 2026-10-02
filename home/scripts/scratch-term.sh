# Terminal ascuns în scratchpad: îl pornește la prima apăsare, apoi îl arată/ascunde.
if swaymsg -t get_tree | jq -e '[.. | objects | select(.app_id? == "scratchpad")] | length > 0' >/dev/null; then
  swaymsg '[app_id="^scratchpad$"] scratchpad show' >/dev/null
else
  exec foot --app-id=scratchpad
fi
