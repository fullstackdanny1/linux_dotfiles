# Control center în launcher: aceleași acțiuni ca bara, plus restul.
menu() { fuzzel --dmenu --prompt "$1 " --lines "${2:-10}"; }

choice=$(printf '%s\n' \
  "Wi-Fi" "Bluetooth" "Audio" "Profil energie" "Night light" \
  "Nu deranja" "Monitor sistem" "Scurtături" "Time tracking" |
  menu control 9) || exit 0

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
  "Scurtături")
    # Păstrăm dimensiunile și formatul Walker; JetBrains Mono aliniază coloanele.
    {
      printf '%-26s →   %s   %s\n' \
        'super + Return'          'Terminal (foot)'               '[sway]' \
        'super + d'               'App launcher (Fuzzel)'         '[sway]' \
        'super + Shift + f'       'Browser (Firefox)'             '[sway]' \
        'super + x'               'Control center'                '[sway]' \
        'super + Shift + x'       'Power menu'                    '[sway]' \
        'super + Shift + q'       'Închide fereastra'             '[sway]' \
        'super + f'               'Fullscreen'                    '[sway]' \
        'super + Shift + Space'   'Floating toggle'               '[sway]' \
        'super + h/j/k/l'         'Navigare între ferestre'       '[sway]' \
        'super + Shift + h/j/k/l' 'Mută fereastra'                '[sway]' \
        'super + 1…0'             'Workspace 1…10'                '[sway]' \
        'super + Shift + 1…0'     'Mută pe workspace 1…10'        '[sway]' \
        'super + Print'           'Captură cu adnotare (satty)'   '[sway]' \
        'super + Shift + s'       'Captură zonă cu adnotare'      '[sway]' \
        'super + c'               'Acest meniu de scurtături'     '[sway]' \
        'super + m'               'Playerul de muzică'            '[sway]' \
        'ctrl + a'                'Prefix tmux'                   '[tmux]' \
        'prefix + Tab'            'Fereastra anterioară'          '[tmux]' \
        'prefix + f'              'Alege alt proiect'             '[tmux]' \
        'prefix + " / %'          'Split vertical / orizontal'    '[tmux]' \
        'i / Esc'                 'Insert / Normal mode'          '[helix]' \
        'y'                       'Copiază în clipboard sistem'   '[helix]' \
        'p'                       'Lipește din registrul curent'  '[helix]' \
        'space + R'               'Reîncarcă toate fișierele'     '[helix]'
    } | fuzzel --dmenu --no-icons \
          --prompt '' \
          --placeholder 'type to search' \
          --lines 15 \
          --width 65 \
          --horizontal-pad 24 \
          --vertical-pad 18 \
          --inner-pad 12 \
          --line-height 26 \
          --font 'JetBrains Mono:size=10' >/dev/null
    ;;
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
