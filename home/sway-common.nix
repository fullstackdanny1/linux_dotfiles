# Sway comun: input, keybinds, reguli de ferestre, wallpaper, idle-inhibit,
# scratchpad, muzică, lid. Compositorul vine din sistem (sway / swayfx).
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
  exe = name: lib.getExe cfg.scripts.${name};
  mod = "Mod4";
  hash = c: "#${c}";

  workspaces = lib.genList (i: toString (i + 1)) 10;
  # tasta 0 → workspace 10
  wsKey = ws: if ws == "10" then "0" else ws;
in
{
  options.dotfiles = with lib; {
    host = mkOption {
      type = types.enum [
        "main"
        "second"
      ];
      description = "Ce configurație e activă.";
    };
    lockCommand = mkOption {
      type = types.str;
      description = "Comanda de lock; trebuie să blocheze până la deblocare.";
    };
    lockProcess = mkOption {
      type = types.str;
      description = "Numele procesului de lock (gtklock / swaylock).";
    };
    notifyOnUnlock = mkOption {
      type = types.bool;
      default = false;
      description = "La deblocare, notificare care oferă reluarea timerului.";
    };
    laptopOutput = mkOption {
      type = types.str;
      default = "eDP-1";
      description = "Ecranul laptopului (vezi `swaymsg -t get_outputs`).";
    };
    scale = mkOption {
      type = types.float;
      default = 1.0;
      description = "Scalarea ecranului laptopului.";
    };
    gaps = {
      inner = mkOption {
        type = types.int;
        default = 12;
        description = "Spațiul dintre ferestre.";
      };
      outer = mkOption {
        type = types.int;
        default = 4;
        description = "Spațiul suplimentar față de marginea ecranului.";
      };
    };
    scripts = mkOption {
      type = types.attrsOf types.package;
      default = { };
      description = "Scripturile din ./scripts, instalate în profil.";
    };
  };

  config = {
    dotfiles.scripts = {
      session = mkScript {
        name = "session";
        runtimeInputs = [
          cfg.scripts.timer
          pkgs.procps
          pkgs.libnotify
        ];
        env = {
          LOCKER = cfg.lockCommand;
          LOCK_PROCESS = cfg.lockProcess;
          NOTIFY_ON_UNLOCK = if cfg.notifyOnUnlock then "1" else "0";
        };
      };
      timer = mkScript {
        name = "timer";
        runtimeInputs = with pkgs; [
          timewarrior
          git
          jq
          fuzzel
          coreutils
          gawk
        ];
      };
      scratch-term = mkScript {
        name = "scratch-term";
        runtimeInputs = [
          pkgs.jq
          pkgs.foot
        ];
      };
      music = mkScript {
        name = "music";
        runtimeInputs = [
          pkgs.jq
          pkgs.foot
          pkgs.rmpc
        ];
      };
      power-menu = mkScript {
        name = "power-menu";
        runtimeInputs = [
          pkgs.fuzzel
          cfg.scripts.session
        ];
      };
    };

    home.packages = lib.attrValues cfg.scripts;

    wayland.windowManager.sway = {
      enable = true;
      package = null; # sway / swayfx din sistem
      checkConfig = false;
      # Exportă tot mediul sesiunii (inclusiv PATH cu profilul Nix) către
      # serviciile systemd --user (bară, notificări, idle…).
      systemd.variables = [ "--all" ];

      config = {
        modifier = mod;
        terminal = "foot";
        menu = "fuzzel";
        left = "h";
        down = "j";
        up = "k";
        right = "l";

        fonts = {
          names = [ theme.font.name ];
          size = theme.font.size + 0.0;
        };

        input = {
          "type:keyboard" = {
            xkb_layout = "us,ro";
            xkb_variant = ",std";
            # Caps = Escape; Shift+Caps = Caps Lock
            xkb_options = "caps:escape_shifted_capslock";
            repeat_delay = "250";
            repeat_rate = "40";
          };
          "type:touchpad" = {
            tap = "enabled";
            natural_scroll = "enabled";
            dwt = "enabled";
            middle_emulation = "enabled";
            scroll_factor = "0.5";
          };
        };

        output = {
          "*".bg = if theme.hasWallpaper then "${theme.wallpaper} fill" else "${hash theme.bg} solid_color";
          ${cfg.laptopOutput}.scale = toString cfg.scale;
        };

        seat."*".xcursor_theme = "${theme.cursor.name} ${toString theme.cursor.size}";

        window = {
          border = 2;
          titlebar = false;
        };
        floating = {
          border = 2;
          titlebar = false;
          modifier = mod;
        };
        # Margini și când e o singură fereastră pe workspace.
        gaps = {
          inherit (cfg.gaps) inner outer;
          smartGaps = false;
        };
        workspaceAutoBackAndForth = true;
        focus.wrapping = "no";

        colors =
          let
            accent = hash theme.accent;
            bg = hash theme.bg;
            fg = hash theme.fg;
            muted = hash theme.muted;
            red = hash theme.scheme.base08;
          in
          {
            focused = {
              border = accent;
              background = accent;
              text = bg;
              indicator = accent;
              childBorder = accent;
            };
            focusedInactive = {
              border = muted;
              background = bg;
              text = muted;
              indicator = bg;
              childBorder = hash theme.scheme.base02;
            };
            unfocused = {
              border = muted;
              background = bg;
              text = muted;
              indicator = bg;
              childBorder = hash theme.scheme.base02;
            };
            urgent = {
              border = red;
              background = red;
              text = fg;
              indicator = red;
              childBorder = red;
            };
          };

        assigns."10" = [ { app_id = "^rmpc$"; } ];

        bindswitches = {
          # Capac închis → doar monitorul extern; deschis → laptopul revine.
          "lid:on" = {
            reload = true;
            locked = true;
            action = "output ${cfg.laptopOutput} disable";
          };
          "lid:off" = {
            reload = true;
            locked = true;
            action = "output ${cfg.laptopOutput} enable";
          };
        };

        keybindings = {
          "${mod}+Return" = "exec foot";
          "${mod}+d" = "exec fuzzel";
          "${mod}+Shift+q" = "kill";
          "${mod}+Shift+c" = "reload";
          "${mod}+Escape" = "exec ${exe "session"} lock";
          "${mod}+Shift+e" =
            "exec swaynag -t warning -m 'Ieșire din sway?' -Z 'Logout' '${exe "session"} logout'";
          "${mod}+Shift+f" = "exec firefox";

          # US / RO
          "${mod}+space" = "input type:keyboard xkb_switch_layout next";

          # navigare și mutare (hjkl și săgeți)
          "${mod}+h" = "focus left";
          "${mod}+j" = "focus down";
          "${mod}+k" = "focus up";
          "${mod}+l" = "focus right";
          "${mod}+Left" = "focus left";
          "${mod}+Down" = "focus down";
          "${mod}+Up" = "focus up";
          "${mod}+Right" = "focus right";
          "${mod}+Shift+h" = "move left";
          "${mod}+Shift+j" = "move down";
          "${mod}+Shift+k" = "move up";
          "${mod}+Shift+l" = "move right";
          "${mod}+Shift+Left" = "move left";
          "${mod}+Shift+Down" = "move down";
          "${mod}+Shift+Up" = "move up";
          "${mod}+Shift+Right" = "move right";

          # layout
          "${mod}+b" = "splith";
          "${mod}+v" = "splitv";
          "${mod}+s" = "layout stacking";
          "${mod}+w" = "layout tabbed";
          "${mod}+e" = "layout toggle split";
          "${mod}+f" = "fullscreen toggle";
          "${mod}+Shift+space" = "floating toggle";
          "${mod}+Tab" = "focus mode_toggle";
          "${mod}+a" = "focus parent";
          "${mod}+r" = "mode resize";

          # scratchpad: terminal ascuns + scratchpad-ul obișnuit
          "${mod}+grave" = "exec ${exe "scratch-term"}";
          "${mod}+minus" = "scratchpad show";
          "${mod}+Shift+minus" = "move scratchpad";

          # muzică (workspace 10)
          "${mod}+m" = "exec ${exe "music"}";
          "${mod}+Shift+x" = "exec ${exe "power-menu"}";

          # media, funcționale și pe lock screen
          "--locked XF86AudioPlay" = "exec playerctl play-pause";
          "--locked XF86AudioPause" = "exec playerctl pause";
          "--locked XF86AudioNext" = "exec playerctl next";
          "--locked XF86AudioPrev" = "exec playerctl previous";
          "--locked XF86AudioStop" = "exec playerctl stop";
        }
        // lib.listToAttrs (
          lib.concatMap (ws: [
            (lib.nameValuePair "${mod}+${wsKey ws}" "workspace number ${ws}")
            (lib.nameValuePair "${mod}+Shift+${wsKey ws}" "move container to workspace number ${ws}")
          ]) workspaces
        );

        modes.resize = {
          "h" = "resize shrink width 20px";
          "j" = "resize grow height 20px";
          "k" = "resize shrink height 20px";
          "l" = "resize grow width 20px";
          "Left" = "resize shrink width 20px";
          "Down" = "resize grow height 20px";
          "Up" = "resize shrink height 20px";
          "Right" = "resize grow width 20px";
          "Return" = "mode default";
          "Escape" = "mode default";
        };
      };

      # Înainte de restul configurației, ca setările noastre să aibă prioritate.
      extraConfigEarly = ''
        include /etc/sway/config.d/*
      '';

      extraConfig = ''
        # Dialoguri și file picker-e plutitoare
        for_window [window_role="pop-up"] floating enable
        for_window [window_role="dialog"] floating enable
        for_window [window_role="bubble"] floating enable
        for_window [window_type="dialog"] floating enable
        for_window [app_id="xdg-desktop-portal-gtk"] floating enable
        for_window [title="(?i)^(open|save|select|choose)( a)? (file|files|folder|as|directory)"] floating enable
        for_window [title="(?i)file upload"] floating enable

        # Terminalul din scratchpad
        for_window [app_id="^scratchpad$"] floating enable, resize set width 70 ppt height 60 ppt, move position center, move scratchpad, scratchpad show

        # Idle inhibat cât o fereastră e pe fullscreen
        for_window [all] inhibit_idle fullscreen
      '';
    };
  };
}
