# Pornește gtklock (din sistem) cu modulele powerbar și playerctl, oriunde le-a
# pus distribuția (/usr/lib, /usr/lib64, /usr/local/lib…).
args=()
for dir in /usr/lib/gtklock /usr/lib64/gtklock /usr/local/lib/gtklock /usr/local/lib64/gtklock; do
  for module in powerbar-module playerctl-module; do
    if [ -f "$dir/$module.so" ]; then args+=(-m "$dir/$module.so"); fi
  done
  if [ ${#args[@]} -gt 0 ]; then break; fi
done
exec gtklock "${args[@]}" "$@"
