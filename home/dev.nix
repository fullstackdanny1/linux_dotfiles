# Workflow de programare: o sesiune tmux per proiect (stil tmux-sessionizer).
#   Super+P → alegi proiectul (fzf) → fereastra „code” cu Helix pe tot ecranul,
#   fereastra „term” în containerul de dev (distrobox).
{
  config,
  lib,
  pkgs,
  theme,
  ...
}:
let
  cfg = config.dotfiles;
  inherit (import ./lib.nix { inherit pkgs; }) mkScript;
  c = theme.scheme;
  hash = x: "#${x}";
  ts = lib.getExe cfg.scripts.ts;
in
{
  options.dotfiles.dev = with lib; {
    projectsDir = mkOption {
      type = types.str;
      default = "${config.home.homeDirectory}/code";
      defaultText = "~/code";
      description = "Directorul cu proiecte (fiecare subdirector = o sesiune).";
    };
    container = mkOption {
      type = types.str;
      default = "dev";
      description = "Containerul distrobox în care rulează fereastra „term”.";
    };
  };

  config = {
    dotfiles.scripts.ts = mkScript {
      name = "ts";
      runtimeInputs = with pkgs; [
        tmux
        fzf
        coreutils
        findutils
      ];
      env = {
        TS_PROJECTS = cfg.dev.projectsDir;
        TS_CONTAINER = cfg.dev.container;
      };
    };

    home.packages = with pkgs; [
      fzf
      lazygit
    ];

    wayland.windowManager.sway.config.keybindings."Mod4+p" = "exec foot ${ts}";

    programs.tmux = {
      enable = true;
      # Ctrl-b e „page up” în Helix
      prefix = "C-a";
      escapeTime = 0; # fără întârziere la Esc (editor modal)
      baseIndex = 1;
      mouse = true;
      terminal = "tmux-256color";
      historyLimit = 10000;
      extraConfig = ''
        set -g renumber-windows on
        set -g set-clipboard on
        set -g focus-events on

        # Truecolor și undercurl pentru diagnosticele Helix
        set -as terminal-features ",foot*:RGB,foot*:usstyle"
        # Shift+Enter și alte taste extinse în agenții CLI
        set -s extended-keys on

        # code <-> term
        bind Tab last-window
        # alt proiect, din fzf, într-un popup
        bind f display-popup -E -w 60% -h 50% ${ts}
        # split-uri în directorul curent
        bind '"' split-window -v -c "#{pane_current_path}"
        bind % split-window -h -c "#{pane_current_path}"
        bind r source-file ~/.config/tmux/tmux.conf \; display-message "tmux.conf reîncărcat"

        # ---- aspect: minimal, paleta gruvbox, fără fundal propriu
        set -g status-position bottom
        set -g status-justify left
        set -g status-interval 5
        set -g status-style "bg=default,fg=${hash theme.muted}"
        set -g status-left-length 40
        set -g status-left "#[fg=${hash theme.bg},bg=${hash theme.accent},bold] #S #[bg=default] "
        set -g status-right "#{?client_prefix,#[fg=${hash c.base0A}]prefix ,}#[fg=${hash c.base03}]#h"
        set -g window-status-format " #I #W "
        set -g window-status-current-format "#[fg=${hash theme.fg},bold] #I #W "
        set -g window-status-separator ""
        set -g pane-border-style "fg=${hash c.base02}"
        set -g pane-active-border-style "fg=${hash "a89984"}"
        set -g pane-border-lines single
        set -g message-style "bg=${hash c.base01},fg=${hash theme.fg}"
        set -g message-command-style "bg=${hash c.base01},fg=${hash theme.fg}"
        set -g mode-style "bg=${hash c.base02},fg=${hash theme.fg}"
        set -g popup-border-style "fg=${hash c.base03}"
        set -g popup-border-lines rounded
        set -g display-panes-active-colour "${hash theme.accent}"
        set -g display-panes-colour "${hash theme.muted}"
        set -g clock-mode-colour "${hash theme.accent}"
      '';
    };

    programs.helix.settings = {
      editor = {
        true-color = true; # forțează truecolor în tmux
        bufferline = "multiple"; # taburi când ai 2+ fișiere deschise
      };
      keys.normal.space.R = ":reload-all"; # reîncarcă fișierele modificate de agent
    };
  };
}
