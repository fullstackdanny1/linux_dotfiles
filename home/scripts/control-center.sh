# Control center în launcher: aceleași acțiuni ca bara, plus restul.
menu() { fuzzel --dmenu --prompt "$1 " --lines "${2:-10}"; }

choice=$(printf '%b\n' \
  "Wi-Fi\0icon\x1fnetwork-wireless" \
  "Bluetooth\0icon\x1fbluetooth" \
  "Audio\0icon\x1faudio-volume-high" \
  "Profil energie\0icon\x1fbattery" \
  "Night light\0icon\x1fweather-clear-night" \
  "Nu deranja\0icon\x1fnotifications-disabled" \
  "Monitor sistem\0icon\x1futilities-system-monitor" \
  "Cheatsheet / Scurtături\0icon\x1fhelp-about" \
  "Time tracking\0icon\x1fappointment-soon" |
  menu control 9) || exit 0

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
      pkill -SIGRTMIN+1 i3status-rs 2>/dev/null || true
      notify-send --app-name=mako "Nu deranja: oprit"
    else
      notify-send --app-name=mako --expire-time=2000 "Nu deranja: pornit"
      makoctl mode -a do-not-disturb >/dev/null
      pkill -SIGRTMIN+1 i3status-rs 2>/dev/null || true
    fi
    ;;
  "Monitor sistem") popup sysmon btop ;;
  "Cheatsheet / Scurtături")
    # Lista este read-only: selectează o scurtătură sau apasă Esc pentru ieșire.
    printf '%s\n' \
      'SWAY — Mod = Super' \
      'Mod+Return  Terminal foot' \
      'Mod+d  App launcher (Fuzzel)' \
      'Mod+b  Firefox' \
      'Mod+c  Control center' \
      'Mod+p  Power menu' \
      'Mod+q  Închide fereastra' \
      'Mod+f  Fullscreen' \
      'Mod+v  Floating toggle' \
      'Mod+h/j/k/l  Navigare între ferestre' \
      'Mod+Shift+h/j/k/l  Mută fereastra' \
      'Mod+1…0  Workspace 1…10' \
      'Mod+Shift+1…0  Mută pe workspace 1…10' \
      'Mod+Print / Mod+s  Captură cu adnotare' \
      'Mod+Shift+s  Captură zonă' \
      'Mod+Shift+r  Reîncarcă Sway' \
      'TMUX' \
      'Ctrl+a  Prefix tmux' \
      'Prefix+Tab  Fereastra anterioară' \
      'Prefix+f  Alege alt proiect' \
      'Prefix+" / %  Split vertical / orizontal' \
      'HELIX' \
      'i / Esc  Insert / Normal' \
      'y  Copiază în clipboard-ul sistemului' \
      'p  Lipește din registrul curent' \
      'Space+R  Reîncarcă toate fișierele' |
      fuzzel --dmenu --no-icons --prompt 'scurtături ' --lines 20 >/dev/null
    ;;
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
