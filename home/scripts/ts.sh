# ts [director]: deschide sau comută pe sesiunea tmux a unui proiect.
#   fereastra 1 „code”: hx . (pe host)
#   fereastra 2 „term”: shell în containerul de dev (distrobox enter $TS_CONTAINER)
# Orice fereastră nouă (prefix c) intră și ea în container.
# Din Nix: TS_PROJECTS (directorul cu proiecte), TS_CONTAINER (containerul distrobox).

if [ $# -gt 0 ]; then
  dir="$1"
else
  dir=$(find "$TS_PROJECTS" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort | fzf --prompt "proiect " --reverse) || exit 0
fi
[ -z "$dir" ] && exit 0
dir=$(realpath "$dir")
name=$(basename "$dir" | tr . _)

if ! tmux has-session -t "=$name" 2>/dev/null; then
  tmux new-session -d -s "$name" -n code -c "$dir"
  tmux send-keys -t "$name:code" "hx ." Enter
  if command -v distrobox >/dev/null; then
    tmux set-option -t "$name" default-command "distrobox enter $TS_CONTAINER"
  fi
  tmux new-window -t "$name:" -n term -c "$dir"
  tmux select-window -t "$name:code"
fi

if [ -n "${TMUX:-}" ]; then
  tmux switch-client -t "=$name"
else
  exec tmux attach -t "=$name"
fi
