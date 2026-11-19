# Meniu de power în launcher.
choice=$(printf '%b\n' \
  "Lock\0icon\x1fsystem-lock-screen" \
  "Logout\0icon\x1fsystem-log-out" \
  "Suspend\0icon\x1fsystem-suspend" \
  "Reboot\0icon\x1fsystem-reboot" \
  "Power off\0icon\x1fsystem-shutdown" |
  fuzzel --dmenu --prompt "power " --lines 5) || exit 0

case "$choice" in
  Lock) session lock ;;
  Logout) session logout ;;
  Suspend) session suspend ;;
  Reboot) session reboot ;;
  "Power off") session off ;;
esac
