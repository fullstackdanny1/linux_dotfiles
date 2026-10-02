# session {lock|logout|suspend|off|reboot}
# Din Nix: LOCKER (comanda de lock, blochează până la deblocare),
#          LOCK_PROCESS (numele procesului de lock, ca să nu pornim două),
#          NOTIFY_ON_UNLOCK (1 = notificare cu reluarea timerului după deblocare).

locked() { pgrep -u "$(id -u)" -x "$LOCK_PROCESS" >/dev/null; }

on_unlock() {
  [ "${NOTIFY_ON_UNLOCK:-0}" = 1 ] || return 0
  timer resumable || return 0
  local action
  action=$(notify-send --app-name=timewarrior --expire-time=60000 \
    --action=default=Reia "Timer oprit la lock" \
    "$(timer last) — click pentru reluare" || true)
  if [ "$action" = default ]; then timer continue; fi
}

lock() {
  locked && return 0
  timer pause || true
  local cmd
  read -ra cmd <<<"$LOCKER"
  ("${cmd[@]}"; on_unlock) &
  # swayidle -w așteaptă scriptul înainte de suspend: lăsăm lock screen-ul să apară.
  sleep 1
}

case "${1:-}" in
  lock) lock ;;
  logout) timer stop >/dev/null 2>&1 || true; swaymsg exit ;;
  suspend) systemctl suspend ;;
  off) timer stop >/dev/null 2>&1 || true; systemctl poweroff ;;
  reboot) timer stop >/dev/null 2>&1 || true; systemctl reboot ;;
  *) echo "usage: session {lock|logout|suspend|off|reboot}" >&2; exit 1 ;;
esac
