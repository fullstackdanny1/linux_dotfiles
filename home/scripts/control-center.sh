# Control center în launcher: aceleași acțiuni ca bara, plus restul.
menu() { fuzzel --dmenu --prompt "$1 " --lines "${2:-10}"; }

choice=$(printf '%s\n' \
  "Wi-Fi" "Bluetooth" "Audio" "Profil energie" "Night light" \
  "Nu deranja" "Monitor sistem" "Time tracking" |
  menu control 8) || exit 0

case "$choice" in
  Wi-Fi) popup wifi impala ;;
  Bluetooth) popup bluetooth bluetui ;;
  Audio) popup audio wiremix ;;
  "Profil energie")
    current=$(powerprofilesctl get)
    profile=$(printf '%s\n' power-saver balanced performance | menu "profil ($current)" 3) || exit 0
    powerprofilesctl set "$profile" && notify-send --app-name=power "Profil energie: $profile"
    ;;
  "Night light")
    if systemctl --user is-active --quiet gammastep; then
      systemctl --user stop gammastep && notify-send --app-name=gammastep "Night light oprit"
    else
      systemctl --user start gammastep && notify-send --app-name=gammastep "Night light pornit"
    fi
    ;;
  "Nu deranja")
    if makoctl mode | grep -qx do-not-disturb; then
      makoctl mode -r do-not-disturb >/dev/null
      notify-send --app-name=mako "Nu deranja: oprit"
    else
      notify-send --app-name=mako --expire-time=2000 "Nu deranja: pornit"
      sleep 2
      makoctl mode -a do-not-disturb >/dev/null
    fi
    ;;
  "Monitor sistem") popup sysmon btop ;;
  "Time tracking")
    action=$(printf '%s\n' "Pornire" "Oprire" "Continuare" "Raport" | menu timer 4) || exit 0
    case "$action" in
      Pornire) timer pick ;;
      Oprire) timer stop ;;
      Continuare) timer continue ;;
      Raport) popup timer timer report ;;
    esac
    ;;
esac
