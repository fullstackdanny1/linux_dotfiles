# Control center în launcher: aceleași acțiuni ca bara, plus restul.
# --no-icons evită lookup-ul asincron al iconițelor tematice; glyph-urile sunt
# randate direct de JetBrainsMono Nerd Font.
menu() { fuzzel --dmenu --no-icons --prompt "$1 " --lines "${2:-10}"; }

choice=$(printf '%s\n' \
  '󰖩  Wi-Fi' \
  '󰂯  Bluetooth' \
  '󰕾  Audio' \
  '󰁹  Profil energie' \
  '󰖔  Night light' \
  '󰂛  Nu deranja' \
  '󰍹  Monitor sistem' \
  '󰌌  Cheatsheet / Scurtături' \
  '󰔛  Time tracking' |
  menu control 9) || exit 0

case "$choice" in
  '󰖩  Wi-Fi') popup wifi impala ;;
  '󰂯  Bluetooth') popup bluetooth bluetui ;;
  '󰕾  Audio') popup audio pulsemixer ;;
  '󰁹  Profil energie')
    current=$(powerprofilesctl get)
    profile=$(printf '%s\n' \
      '󰁺  power-saver' \
      '󰁹  balanced' \
      '󰓅  performance' |
      menu "profil ($current)" 3) || exit 0
    case "$profile" in
      '󰁺  power-saver') profile=power-saver ;;
      '󰁹  balanced') profile=balanced ;;
      '󰓅  performance') profile=performance ;;
      *) exit 0 ;;
    esac
    powerprofilesctl set "$profile" && notify-send --app-name=power "Profil energie: $profile"
    ;;
  '󰖔  Night light')
    if systemctl --user is-active --quiet gammastep; then
      systemctl --user stop gammastep && notify-send --app-name=gammastep "Night light oprit"
    else
      systemctl --user start gammastep && notify-send --app-name=gammastep "Night light pornit"
    fi
    ;;
  '󰂛  Nu deranja')
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
  '󰍹  Monitor sistem') popup sysmon btop ;;
  '󰌌  Cheatsheet / Scurtături')
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
  '󰔛  Time tracking')
    action=$(printf '%s\n' \
      '󰐊  Pornire' \
      '󰓛  Oprire' \
      '󰐊  Continuare' \
      '󰉹  Raport' |
      menu timer 4) || exit 0
    case "$action" in
      '󰐊  Pornire') timer pick ;;
      '󰓛  Oprire') timer stop ;;
      '󰐊  Continuare') timer continue ;;
      '󰉹  Raport') popup timer timer report ;;
    esac
    ;;
esac
