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
    # Format stil Omarchy/Walker: combinație aliniată + săgeată + acțiune + [categorie]
    {
      printf '%-26s →   %s   %s\n' \
        'super + Return'        'Terminal (foot)'              '[sway]' \
        'super + d'             'App launcher (Fuzzel)'        '[sway]' \
        'super + b'             'Browser (Firefox)'            '[sway]' \
        'super + c'             'Control center'               '[sway]' \
        'super + p'             'Power menu'                   '[sway]' \
        'super + q'             'Închide fereastra'            '[sway]' \
        'super + f'             'Fullscreen'                   '[sway]' \
        'super + v'             'Floating toggle'              '[sway]' \
        'super + h/j/k/l'       'Navigare între ferestre'      '[sway]' \
        'super + shift + h/j/k/l' 'Mută fereastra'             '[sway]' \
        'super + 1…0'           'Workspace 1…10'               '[sway]' \
        'super + shift + 1…0'   'Mută pe workspace 1…10'       '[sway]' \
        'super + s / Print'     'Captură cu adnotare (satty)'  '[sway]' \
        'super + shift + s'     'Captură zonă în clipboard'    '[sway]' \
        'super + shift + r'     'Reîncarcă configurația Sway'  '[sway]' \
        'ctrl + a'              'Prefix tmux'                  '[tmux]' \
        'prefix + Tab'          'Fereastra anterioară'         '[tmux]' \
        'prefix + f'            'Alege alt proiect'            '[tmux]' \
        'prefix + " / %'        'Split vertical / orizontal'   '[tmux]' \
        'i / Esc'               'Insert / Normal mode'         '[helix]' \
        'y'                     'Copiază în clipboard sistem'  '[helix]' \
        'p'                     'Lipește din registrul curent' '[helix]' \
        'space + R'             'Reîncarcă toate fișierele'    '[helix]'
    } | fuzzel --dmenu --no-icons \
          --prompt '' \
          --placeholder 'type to search' \
          --lines 15 \
          --width 65 \
          --horizontal-pad 24 \
          --vertical-pad 18 \
          --inner-pad 12 \
          --line-height 26 >/dev/null
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
