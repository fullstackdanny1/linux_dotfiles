# Control center în launcher: aceleași acțiuni ca bara, plus restul.
menu() { fuzzel --dmenu --prompt "$1 " --lines "${2:-10}"; }

choice=$(printf '%b\n' \
  "Wi-Fi\0icon\x1fnetwork-wireless" \
  "Bluetooth\0icon\x1fbluetooth" \
  "Audio\0icon\x1faudio-volume-high" \
  "Profil energie\0icon\x1fbattery" \
  "Night light\0icon\x1fweather-clear-night" \
  "Nu deranja\0icon\x1fnotifications-disabled" \
  "Monitor sistem\0icon\x1futash" \
  "Time tracking\0icon\x1fappointment-soon" |
  menu control 8) || exit 0

case "$choice" in
  Wi-Fi) popup wifi impala ;;
  Bluetooth) popup bluetooth bluetui ;;
  Audio) popup audio pulsemixer ;;
  "Profil energie")
    current=$(powerprofilesctl get)
    profile=$(printf '%b\n' \
      "power-saver\0icon\x1fbattery-low" \
      "balanced\0icon\x1fbattery" \
      "performance\0icon\x1findicator-cpufreq" |
      menu "profil ($current)" 3) || exit 0
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
    action=$(printf '%b\n' \
      "Pornire\0icon\x1fmedia-playback-start" \
      "Oprire\0icon\x1fmedia-playback-stop" \
      "Continuare\0icon\x1fmedia-playback-start" \
      "Raport\0icon\x1fx-office-document" |
      menu timer 4) || exit 0
    case "$action" in
      Pornire) timer pick ;;
      Oprire) timer stop ;;
      Continuare) timer continue ;;
      Raport) popup timer timer report ;;
    esac
    ;;
esac
