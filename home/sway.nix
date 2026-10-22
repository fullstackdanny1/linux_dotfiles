# Sway: input, keybinds, reguli de ferestre, wallpaper, lock (swaylock), idle,
# notificări, OSD, capturi, night light, monitoare. Sway și swaylock vin din sistem.
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
  hash = x: "#${x}";
  c = theme.scheme;
  osd = lib.getExe' pkgs.swayosd "swayosd-client";

  # 1–9 în keybindings; 10 (tasta 0) în extraConfig: home-manager sortează tastele
  # alfabetic, iar sway pornește pe primul workspace din config — altfel ar fi 10.
  workspaces = lib.genList (i: toString (i + 1)) 9;
in
{
  options.dotfiles = with lib; {
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
        default = 8;
        description = "Spațiul dintre ferestre.";
      };
      outer = mkOption {
        type = types.int;
        # sway pune la margine outer + inner: 8 + (-1) = 7
        default = -1;
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
          LOCKER = "swaylock";
          LOCK_PROCESS = "swaylock";
          NOTIFY_ON_UNLOCK = "1";
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
      popup = mkScript {
        name = "popup";
        runtimeInputs = [
          pkgs.jq
          pkgs.foot
        ];
      };
      screenshot = mkScript {
        name = "screenshot";
        runtimeInputs = with pkgs; [
          grim
          slurp
          satty
          jq
          wl-clipboard
          libnotify
        ];
      };
      control-center = mkScript {
        name = "control-center";
        runtimeInputs = with pkgs; [
          fuzzel
          libnotify
          mako
          impala
          bluetui
          wiremix
          btop
          cfg.scripts.popup
          cfg.scripts.timer
        ];
      };
      idle-suspend = mkScript { name = "idle-suspend"; };
      polkit-agent = mkScript { name = "polkit-agent"; };
    };

    home.packages =
      lib.attrValues cfg.scripts
      ++ (with pkgs; [
        libnotify
        grim
        slurp
        satty
      ]);

    wayland.windowManager.sway = {
      enable = true;
      package = null; # sway din sistem
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
        # Super+cifră de mai multe ori (sau ținut apăsat) rămâne pe același workspace.
        workspaceAutoBackAndForth = false;
        focus.wrapping = "no";

        colors =
          let
            activeBorder = hash "a89984"; # gruvbox gray (fg4)
            bg = hash theme.bg;
            fg = hash theme.fg;
            muted = hash theme.muted;
            red = hash theme.scheme.base08;
          in
          {
            # Activă: gri deschis; inactive: gri închis. Latura split-ului
            # (unde se deschide următoarea fereastră) e un gri și mai deschis.
            focused = {
              border = activeBorder;
              background = activeBorder;
              text = bg;
              indicator = hash theme.scheme.base05;
              childBorder = activeBorder;
            };
            focusedInactive = {
              border = muted;
              background = bg;
              text = muted;
              # fără focus: toate laturile la fel (și cea a split-ului)
              indicator = hash theme.scheme.base02;
              childBorder = hash theme.scheme.base02;
            };
            unfocused = {
              border = muted;
              background = bg;
              text = muted;
              indicator = hash theme.scheme.base02;
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
          "${mod}+x" = "exec ${exe "control-center"}";

          # volum / luminozitate cu OSD, funcționale și pe lock screen
          "--locked XF86AudioRaiseVolume" = "exec ${osd} --output-volume raise";
          "--locked XF86AudioLowerVolume" = "exec ${osd} --output-volume lower";
          "--locked XF86AudioMute" = "exec ${osd} --output-volume mute-toggle";
          "--locked XF86AudioMicMute" = "exec ${osd} --input-volume mute-toggle";
          "--locked XF86MonBrightnessUp" = "exec ${osd} --brightness raise";
          "--locked XF86MonBrightnessDown" = "exec ${osd} --brightness lower";
          # Caps Lock e pe Shift+Caps (Caps singur = Escape)
          "--release Caps_Lock" = "exec ${osd} --caps-lock";
          "--release Shift+Caps_Lock" = "exec ${osd} --caps-lock";

          # capturi de ecran
          "Print" = "exec ${exe "screenshot"} screen";
          "Shift+Print" = "exec ${exe "screenshot"} area";
          "Ctrl+Print" = "exec ${exe "screenshot"} window";
          "${mod}+Print" = "exec ${exe "screenshot"} annotate";
          "${mod}+Shift+s" = "exec ${exe "screenshot"} annotate";

          # media, funcționale și pe lock screen
          "--locked XF86AudioPlay" = "exec playerctl play-pause";
          "--locked XF86AudioPause" = "exec playerctl pause";
          "--locked XF86AudioNext" = "exec playerctl next";
          "--locked XF86AudioPrev" = "exec playerctl previous";
          "--locked XF86AudioStop" = "exec playerctl stop";
        }
        // lib.listToAttrs (
          lib.concatMap (ws: [
            (lib.nameValuePair "${mod}+${ws}" "workspace number ${ws}")
            (lib.nameValuePair "${mod}+Shift+${ws}" "move container to workspace number ${ws}")
          ]) workspaces
        );

        startup = [ { command = exe "polkit-agent"; } ];

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
        # Workspace 10 (muzica) pe tasta 0, după 1–9 (vezi `workspaces` mai sus)
        bindsym ${mod}+0 workspace number 10
        bindsym ${mod}+Shift+0 move container to workspace number 10

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

        # Terminale popup (din bară / control center): plutitoare, centrate, dimensiune fixă
        for_window [app_id="^popup-"] floating enable, resize set width 900 px height 560 px, move position center

        # Idle inhibat cât o fereastră e pe fullscreen
        for_window [all] inhibit_idle fullscreen
      '';
    };

    programs.fuzzel.settings.border.radius = 0; # colțuri drepte, ca ferestrele
    # ---------------------------------------------------------------- notificări / OSD
    services.mako = {
      enable = true;
      settings = {
        anchor = "top-right";
        margin = "10";
        padding = "12";
        width = 360;
        border-size = 2;
        border-radius = 0;
        default-timeout = 5000;
        layer = "overlay";
        "mode=do-not-disturb" = {
          invisible = 1;
        };
        # bateria critică trece și de „nu deranja”
        "mode=do-not-disturb urgency=critical" = {
          invisible = 0;
        };
      };
    };

    services.swayosd.enable = true;

    services.batsignal = {
      enable = true;
      extraArgs = [
        "-w"
        "20"
        "-c"
        "10"
        "-d"
        "5"
      ];
    };

    # ---------------------------------------------------------------- idle
    services.swayidle =
      let
        session = exe "session";
        brightnessctl = lib.getExe pkgs.brightnessctl;
      in
      {
        enable = true;
        timeouts = [
          {
            timeout = 270; # 4:30 — estompare
            command = "${brightnessctl} -s set 10%";
            resumeCommand = "${brightnessctl} -r";
          }
          {
            timeout = 300; # 5:00 — lock
            command = "${session} lock";
          }
          {
            timeout = 330; # 5:30 — ecran stins
            command = "swaymsg 'output * power off'";
            resumeCommand = "swaymsg 'output * power on'";
          }
          {
            timeout = 900; # 15:00 — suspend, doar pe baterie
            command = exe "idle-suspend";
          }
        ];
        events = {
          before-sleep = "${session} lock";
          lock = "${session} lock";
        };
      };

    # ---------------------------------------------------------------- lock
    # swaylock e din sistem (PAM); configul vine de aici. Fundal: wallpaper-ul.
    xdg.configFile."swaylock/config".text = ''
      ignore-empty-password
      show-failed-attempts
      font=${theme.font.name}
      indicator-radius=135
      indicator-thickness=8
      color=${theme.bg}
      inside-color=${theme.bg}cc
      inside-clear-color=${theme.bg}cc
      inside-ver-color=${theme.bg}cc
      inside-wrong-color=${theme.bg}cc
      ring-color=${c.base01}
      ring-clear-color=${c.base0A}
      ring-ver-color=${c.base0D}
      ring-wrong-color=${c.base08}
      key-hl-color=${theme.accent}
      bs-hl-color=${c.base08}
      line-color=00000000
      line-clear-color=00000000
      line-ver-color=00000000
      line-wrong-color=00000000
      separator-color=00000000
      text-color=${theme.fg}
      text-clear-color=${theme.fg}
      text-ver-color=${theme.fg}
      text-wrong-color=${c.base08}
    ''
    + lib.optionalString theme.hasWallpaper ''
      image=${theme.wallpaper}
      scaling=fill
    '';

    # ---------------------------------------------------------------- night light, monitoare
    services.gammastep = {
      enable = true;
      provider = "manual";
      dawnTime = "6:30-7:30";
      duskTime = "19:30-20:30";
      temperature = {
        day = 6500;
        night = 3800;
      };
    };

    services.kanshi = {
      enable = true;
      settings = [
        {
          profile.name = "laptop";
          profile.outputs = [
            {
              criteria = cfg.laptopOutput;
              status = "enable";
              inherit (cfg) scale;
            }
          ];
        }
        {
          # Ecran extern: laptopul rămâne activ cât capacul e deschis (vezi bindswitch).
          profile.name = "docked";
          profile.outputs = [
            {
              criteria = cfg.laptopOutput;
              status = "enable";
              inherit (cfg) scale;
            }
            {
              criteria = "*";
              status = "enable";
            }
          ];
        }
      ];
    };

    # ---------------------------------------------------------------- portals, GTK
    xdg.configFile."xdg-desktop-portal/sway-portals.conf".text = ''
      [preferred]
      default=gtk
      org.freedesktop.impl.portal.ScreenCast=wlr
      org.freedesktop.impl.portal.Screenshot=wlr
      org.freedesktop.impl.portal.Inhibit=none
    '';

    # Tema GTK (adw-gtk3 colorat cu paleta) vine din Stylix.
    gtk.enable = true;
    stylix.targets = {
      gtk.enable = true;
      mako.enable = true;
    };
  };
}
