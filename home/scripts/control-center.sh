# Control center în launcher: aceleași acțiuni ca bara, plus restul.
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
    printf '%-26s →   %-34s   %s\n' \
      'Mod+Return' 'Terminal foot' '[sway]' \
      'Mod+d' 'App launcher Fuzzel' '[sway]' \
      'Mod+c' 'Control center' '[sway]' \
      'Mod+p' 'Power menu' '[sway]' \
      'Mod+q' 'Închide fereastra' '[sway]' \
      'Mod+f' 'Fullscreen' '[sway]' \
      'Mod+v' 'Floating toggle' '[sway]' \
      'Mod+h/j/k/l' 'Navigare' '[sway]' \
      'Mod+Shift+h/j/k/l' 'Mută fereastra' '[sway]' \
      'Mod+1…0' 'Workspace 1…10' '[sway]' \
      'Mod+Shift+1…0' 'Mută pe workspace' '[sway]' \
      'Mod+Print / Mod+s' 'Captură cu adnotare' '[sway]' \
      'Mod+Shift+s' 'Captură zonă' '[sway]' \
      'Mod+Shift+r' 'Reîncarcă Sway' '[sway]' \
      'Ctrl+a Tab' 'Comută ferestrele' '[tmux]' \
      'Ctrl+a f' 'Alege alt proiect' '[tmux]' \
      'Ctrl+a " / %' 'Split vertical / orizontal' '[tmux]' \
      'Ctrl+a r' 'Reîncarcă tmux' '[tmux]' \
      'i / Esc' 'Insert / Normal' '[helix]' \
      'y' 'Copie în clipboard' '[helix]' \
      'p' 'Lipește' '[helix]' \
      'Space R' 'Reîncarcă fișierele' '[helix]' |
      fuzzel --dmenu --no-icons --prompt '' --placeholder 'type to search' --lines 18 --width 78 --horizontal-pad 24 --vertical-pad 18 --inner-pad 12 --line-height 26 >/dev/null
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
