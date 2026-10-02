# Meniu de power în launcher.
choice=$(printf '%s\n' "Lock" "Logout" "Suspend" "Reboot" "Power off" |
  fuzzel --dmenu --prompt "power " --lines 5) || exit 0
case "$choice" in
  Lock) session lock ;;
  Logout) session logout ;;
  Suspend) session suspend ;;
  Reboot) session reboot ;;
  "Power off") session off ;;
esac
