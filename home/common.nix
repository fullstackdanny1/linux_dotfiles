# Comun: pachete, shell + prompt, editor, terminal, launcher,
# TUI-uri, muzică, time tracking, aliasuri și tema (Stylix).
{
  config,
  lib,
  pkgs,
  user,
  theme,
  icons,
  ...
}:
{
  home = {
    username = user.name;
    homeDirectory = user.home;
    stateVersion = "26.05";

    packages = with pkgs; [
      impala
      bluetui
      wiremix
      pulsemixer
      playerctl
      brightnessctl
      rmpc
      swaybg
      jq
      timewarrior
      wl-clipboard
    ];

    sessionVariables = {
      EDITOR = "hx";
      VISUAL = "hx";
      TIMEWARRIORDB = "${config.home.homeDirectory}/Sync/timewarrior";
    };

    activation.timewarriorDb = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p "${config.home.homeDirectory}/Sync/timewarrior/data"
      run touch "${config.home.homeDirectory}/Sync/timewarrior/timewarrior.cfg"
    '';
  };

  programs.home-manager.enable = true;
  targets.genericLinux.enable = true;
  fonts.fontconfig.enable = true;
  xdg.enable = true;

  stylix = {
    enable = true;
    base16Scheme = theme.scheme;
    polarity = "dark";
    fonts = rec {
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        inherit (theme.font) name;
      };
      sansSerif = monospace;
      serif = monospace;
      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };
      sizes = {
        terminal = theme.font.terminalSize;
        applications = theme.font.size;
        popups = theme.font.size;
        desktop = theme.font.size;
      };
    };
    cursor = {
      package = pkgs.bibata-cursors;
      inherit (theme.cursor) name size;
    };
    icons = {
      enable = true;
      package = pkgs.papirus-icon-theme;
      dark = "Papirus-Dark";
      light = "Papirus-Light";
    };
    opacity = {
      terminal = theme.terminalOpacity;
      popups = 0.95;
    };
    autoEnable = false;
    targets = {
      font-packages.enable = true;
      fontconfig.enable = true;
      foot.enable = true;
      fuzzel.enable = true;
      btop.enable = true;
    };
  };

  programs.bash = {
    enable = true;
    historyControl = [ "ignoredups" "erasedups" ];
    shellAliases = {
      wifi = "impala";
      bt = "bluetui";
      audio = "wiremix";
      sysmon = "btop";
      track = "timer start";
      untrack = "timer stop";
      retrack = "timer continue";
      off = "session off";
      reboot = "session reboot";
      logout = "session logout";
      lock = "session lock";
    };
    initExtra = ''
      sleep() {
        if [ $# -eq 0 ]; then session suspend; else command sleep "$@"; fi
      }
    '';
  };

  # Prompt pe două rânduri cu iconițe: utilizator, host, director, branch și
  # durata comenzilor lungi. Săgeata devine roșie după o comandă eșuată.
  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    settings =
      let
        c = theme.scheme;
        frame = "fg:#${c.base03}";
      in
      {
        add_newline = true;
        format = lib.concatStrings [
          "[╭─](${frame}) "
          "$username"
          "$hostname"
          "$directory"
          "$git_branch"
          "$git_state"
          "$git_status"
          "$nix_shell"
          "$cmd_duration"
          "$line_break"
          "[╰─](${frame})"
          "$character"
        ];
        username = {
          show_always = true;
          format = "[${icons.user} $user]($style) ";
          style_user = "bold fg:#${theme.accent}";
          style_root = "bold fg:#${c.base08}";
        };
        hostname = {
          ssh_only = false;
          format = "[${icons.laptop} $hostname]($style)  ";
          style = "fg:#${theme.muted}";
        };
        directory = {
          format = "[${icons.folder} $path]($style)[$read_only]($read_only_style) ";
          style = "bold fg:#${c.base0D}";
          truncation_length = 3;
          truncation_symbol = "…/";
          read_only = " ${icons.lock}";
        };
        git_branch = {
          format = " [${icons.gitBranch} $branch]($style) ";
          style = "fg:#${c.base0E}";
        };
        git_status = {
          format = "([$all_status$ahead_behind]($style) )";
          style = "fg:#${c.base0A}";
        };
        nix_shell = {
          format = "[${icons.nix} $name]($style) ";
          style = "fg:#${c.base0C}";
        };
        cmd_duration = {
          min_time = 2000;
          format = "[${icons.timer} $duration]($style) ";
          style = "fg:#${theme.muted}";
        };
        character = {
          success_symbol = "[❯](bold fg:#${theme.accent})";
          error_symbol = "[❯](bold fg:#${c.base08})";
        };
      };
  };

  programs.git.enable = true;

  programs.helix = {
    enable = true;
    settings = {
      theme = "dotfiles";
      editor = {
        line-number = "relative";
        cursorline = true;
        color-modes = true;
        cursor-shape = {
          insert = "bar";
          normal = "block";
        };
      };
    };
    themes.dotfiles = {
      inherits = "gruvbox_dark_hard";
      "ui.background" = { };
      "ui.virtual.whitespace" = { fg = "#${theme.scheme.base01}"; };
      "ui.linenr" = { fg = "#7c6f64"; };
      "ui.linenr.selected" = {
        fg = "#${theme.accent}";
        modifiers = [ "bold" ];
      };
      "ui.statusline" = {
        fg = "#${theme.fg}";
        bg = "#${theme.scheme.base01}";
      };
      "ui.menu" = {
        fg = "#${theme.fg}";
        bg = "#282828";
      };
      "ui.menu.selected" = {
        fg = "#${theme.bg}";
        bg = "#${theme.accent}";
      };
    };
  };

  programs.btop = {
    enable = true;
    settings.vim_keys = true;
  };

  programs.foot = {
    enable = true;
    settings = {
      main = {
        pad = "20x20";
        selection-target = "clipboard";
      };
      cursor = {
        style = "block";
        blink = "no";
      };
      scrollback = {
        lines = 5000;
        multiplier = 3.0;
      };
      url = {
        launch = "xdg-open \${url}";
        osc8-underline = "always";
      };
      tweak.font-monospace-warn = "no";
    };
  };

  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        prompt = ''"❯ "'';
        terminal = "foot";
        lines = 10;
        width = 36;
        horizontal-pad = 24;
        vertical-pad = 16;
        inner-pad = 10;
        line-height = 22;
        exit-on-keyboard-focus-loss = "no";
      };
      border = {
        width = 1;
        radius = 0;
      };
    };
  };

  services.mpd = {
    enable = true;
    musicDirectory = "${config.home.homeDirectory}/Music";
    extraConfig = ''
      audio_output {
        type "pipewire"
        name "PipeWire"
      }
    '';
  };
  services.mpd-mpris.enable = true;
  services.syncthing.enable = true;
}
