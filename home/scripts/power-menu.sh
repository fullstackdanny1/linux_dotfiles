# Meniu de power în launcher. Folosim glyph-uri din Nerd Font în locul iconițelor
# tematice, ca Fuzzel să nu caute fiecare iconiță prin tema Papirus la pornire.
choice=$(printf '%s\n' \
  '󰌾  Lock' \
  '󰍃  Logout' \
  '󰤄  Suspend' \
  '󰜉  Reboot' \
  '󰐥  Power off' |
  fuzzel --dmenu --no-icons --prompt 'power ' --lines 5) || exit 0

case "$choice" in
  '󰌾  Lock') session lock ;;
  '󰍃  Logout') session logout ;;
  '󰤄  Suspend') session suspend ;;
  '󰜉  Reboot') session reboot ;;
  '󰐥  Power off') session off ;;
esac
