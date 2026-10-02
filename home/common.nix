# Comun pe ambele laptopuri: pachete, shell, editoare, terminal, launcher,
# TUI-uri, muzică, time tracking, aliasuri și tema (Stylix).
{
  config,
  lib,
  pkgs,
  user,
  theme,
  ...
}:
{
  home = {
    username = user.name;
    homeDirectory = user.home;
    stateVersion = "26.05";

    packages = with pkgs; [
      # rețea, bluetooth, audio
      impala
      bluetui
      wiremix
      # media, luminozitate
      playerctl
      brightnessctl
      rmpc
      # utilitare
      swaybg
      jq
      timewarrior
      wl-clipboard
    ];

    sessionVariables = {
      EDITOR = "hx";
      VISUAL = "hx";
      # Baza de date timewarrior stă în folderul sincronizat (vezi services.syncthing).
      TIMEWARRIORDB = "${config.home.homeDirectory}/Sync/timewarrior";
    };

    # timewarrior întreabă interactiv la prima rulare dacă nu există baza de date;
    # o creăm aici ca să meargă și din bară / lock.
    activation.timewarriorDb = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p "${config.home.homeDirectory}/Sync/timewarrior/data"
      run touch "${config.home.homeDirectory}/Sync/timewarrior/timewarrior.cfg"
    '';
  };

  programs.home-manager.enable = true;

  # Distribuție non-NixOS: XDG_DATA_DIRS, drivere GPU pentru aplicațiile din Nix etc.
  targets.genericLinux.enable = true;
  fonts.fontconfig.enable = true;
  xdg.enable = true;

  # ---------------------------------------------------------------- tema
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
      terminal = theme.terminalOpacity; # doar fundalul, textul rămâne opac
      popups = 0.95;
    };

    # Doar ținte alese explicit (fără configuri pentru aplicații nefolosite).
    # Sway, waybar, helix și lock screen-urile folosesc paleta direct, din theme.nix.
    autoEnable = false;
    targets = {
      font-packages.enable = true;
      fontconfig.enable = true;
      foot.enable = true;
      fuzzel.enable = true;
      btop.enable = true;
      neovim.enable = true;
    };
  };

  # ---------------------------------------------------------------- shell
  programs.bash = {
    enable = true;
    historyControl = [
      "ignoredups"
      "erasedups"
    ];
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
      # `sleep` fără argumente suspendă; cu argumente rămâne comanda obișnuită.
      sleep() {
        if [ $# -eq 0 ]; then session suspend; else command sleep "$@"; fi
      }
    '';
  };

  programs.git.enable = true;

  # ---------------------------------------------------------------- editoare
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
    # Gruvbox dark hard (aceeași paletă) cu fundal transparent.
    themes.dotfiles = {
      inherits = "gruvbox_dark_hard";
      "ui.background" = {
        bg = "none";
      };
      "ui.virtual.whitespace" = {
        fg = "#${theme.scheme.base01}";
      };
      "ui.linenr" = {
        fg = "#7c6f64";
        bg = "none";
      };
      "ui.linenr.selected" = {
        fg = "#${theme.accent}";
        bg = "none";
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

  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
  };

  programs.btop = {
    enable = true;
    settings.vim_keys = true;
  };

  # ---------------------------------------------------------------- terminal
  programs.foot = {
    enable = true;
    settings = {
      main.pad = "20x20";
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

  # ---------------------------------------------------------------- launcher
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        prompt = ''"❯ "'';
        terminal = "foot";
        lines = 10;
        width = 30;
        horizontal-pad = 20;
        vertical-pad = 15;
        inner-pad = 8;
      };
      colors = {
        selection-text = lib.mkForce "${theme.accent}ff";
        border = lib.mkForce "${theme.accent}ff";
      };
      border.width = 2;
    };
  };

  # ---------------------------------------------------------------- muzică
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
  services.mpd-mpris.enable = true; # tastele media / playerctl / bara

  # ---------------------------------------------------------------- sincronizare
  # Folderul ~/Sync (cu baza timewarrior) se partajează între laptopuri din
  # interfața syncthing: http://127.0.0.1:8384
  services.syncthing.enable = true;
}
