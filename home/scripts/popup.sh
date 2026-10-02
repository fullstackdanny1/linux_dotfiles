# popup <nume> <comandă…>
# Deschide comanda într-un terminal plutitor, centrat (app_id popup-<nume>).
# Al doilea apel cu același nume îl închide.
name="${1:?usage: popup <nume> <comandă…>}"
shift
id="popup-$name"
if swaymsg -t get_tree | jq -e --arg id "$id" '[.. | objects | select(.app_id? == $id)] | length > 0' >/dev/null; then
  swaymsg "[app_id=\"^${id}\$\"] kill" >/dev/null
else
  exec foot --app-id="$id" "$@"
fi
