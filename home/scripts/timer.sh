# Time tracking pe proiect, peste timewarrior. Proiectele sunt tag-uri.
#   timer start [proiect]  proiectul implicit = numele repo-ului git curent
#   timer stop | continue | report | pick
#   timer status [--plain]  pentru bară (JSON pentru waybar, text simplu pentru swaybar)
#   timer pause | resumable | last   folosite de lock

state="${XDG_STATE_HOME:-$HOME/.local/state}/timer-paused"

active() { [ "$(timew get dom.active 2>/dev/null)" = 1 ]; }

current_tags() { timew get dom.active.json | jq -r '.tags // [] | join(" ")'; }

elapsed() {
  local start s
  start=$(timew get dom.active.start)
  s=$(($(date +%s) - $(date -d "$start" +%s)))
  printf '%d:%02d' $((s / 3600)) $((s % 3600 / 60))
}

git_project() {
  local top
  top=$(git rev-parse --show-toplevel 2>/dev/null) || return 1
  basename "$top"
}

start() {
  local project="${1:-}"
  if [ -z "$project" ]; then
    project=$(git_project) || {
      echo "timer: nu ești într-un repo git; dă numele proiectului: timer start <proiect>" >&2
      exit 1
    }
  fi
  rm -f "$state"
  timew start "$project"
}

case "${1:-status}" in
  start) shift; start "$@" ;;
  stop) rm -f "$state"; if active; then timew stop; fi ;;
  continue) rm -f "$state"; timew continue ;;
  pick)
    project=$(timew tags 2>/dev/null | awk 'p && NF { print $1 } /^-+/ { p = 1 }' |
      fuzzel --dmenu --prompt "proiect " --placeholder "alege sau scrie un proiect nou") || exit 0
    [ -n "$project" ] && start "$project"
    ;;
  report)
    timew summary :week :ids
    if [ -t 0 ]; then read -rsn1 -p "Apasă o tastă pentru a închide…"; fi
    ;;
  pause)
    if active; then
      tags=$(current_tags)
      if timew stop >/dev/null; then
        mkdir -p "$(dirname "$state")"
        echo "$tags" >"$state"
      fi
    fi
    ;;
  resumable) [ -f "$state" ] ;;
  last) cat "$state" 2>/dev/null || true ;;
  status)
    if [ "${2:-}" = --plain ]; then
      if active; then echo "$(current_tags) $(elapsed)"; fi
    elif active; then
      jq -nc --arg t "$(current_tags)" --arg e "$(elapsed)" \
        '{text: "\($t) \($e)", tooltip: "\($t): \($e) — click: raportul săptămânii, click dreapta: oprire", class: "active"}'
    else
      echo '{"text": ""}'
    fi
    ;;
  *) echo "usage: timer {start [proiect]|stop|continue|pick|report|status|pause|resumable|last}" >&2; exit 1 ;;
esac
