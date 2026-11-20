# Time tracking pe proiect, peste timewarrior. Proiectele sunt tag-uri.
#   timer start [proiect]  proiectul implicit = numele repo-ului git curent
#   timer stop | continue | report | pick
#   timer status [--plain]  text compact pentru swaybar
#   timer details          notificare completă (trece de Nu deranja)
#   timer pause | resumable | last   folosite de lock

state="${XDG_STATE_HOME:-$HOME/.local/state}/timer-paused"

active() { [ "$(timew get dom.active 2>/dev/null)" = 1 ]; }

current_tags() { timew get dom.active.json | jq -r '.tags // [] | join(" ")'; }

elapsed() {
  local start start_epoch now s
  start=$(timew get dom.active.start 2>/dev/null) || return 1
  start_epoch=$(date -d "$start" +%s 2>/dev/null) || return 1
  now=$(date +%s)
  s=$((now - start_epoch))
  (( s < 0 )) && s=0
  if (( s >= 3600 )); then
    printf '%d:%02d:%02d' $((s / 3600)) $((s % 3600 / 60)) $((s % 60))
  else
    printf '%d:%02d' $((s / 60)) $((s % 60))
  fi
}

short_tags() {
  local tags="$1"
  if (( ${#tags} > 12 )); then
    printf '%s…' "${tags:0:12}"
  else
    printf '%s' "$tags"
  fi
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
  details)
    if active; then
      notify-send --urgency=critical --app-name=timewarrior \
        "Timer activ" "$(current_tags) — $(elapsed)"
    fi
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
    if active; then
      tags=$(current_tags)
      time=$(elapsed) || exit 0
      if [ "${2:-}" = --plain ]; then
        printf '%s %s\n' "$(short_tags "$tags")" "$time"
      else
        jq -nc --arg t "$tags" --arg s "$(short_tags "$tags")" --arg e "$time" \
          '{text: "\($s) \($e)", tooltip: "\($t) — \($e); click: notificare cu detalii, click dreapta: oprire", class: "active"}'
      fi
    elif [ "${2:-}" != --plain ]; then
      echo '{"text": ""}'
    fi
    ;;
  *) echo "usage: timer {start [proiect]|stop|continue|pick|report|details|status|pause|resumable|last}" >&2; exit 1 ;;
esac
