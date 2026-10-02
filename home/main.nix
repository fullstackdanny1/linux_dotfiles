# Principal — "elegant, yet minimal".
# SwayFX, Waybar clickabil, gtklock (lock + power), mako, swayosd, capturi,
# night light, kanshi, control center în launcher.
{
  config,
  lib,
  pkgs,
  theme,
  icons,
  ...
}:
let
  cfg = config.dotfiles;
  inherit (import ./lib.nix { inherit pkgs; }) mkScript;
  exe = name: lib.getExe cfg.scripts.${name};
  mod = "Mod4";
  c = theme.scheme;
  r = toString theme.radius;

  popup = name: cmd: "${exe "popup"} ${name} ${cmd}";
  osd = lib.getExe' pkgs.swayosd "swayosd-client";
in
{
  dotfiles = {
    host = "main";
    lockCommand = exe "gtklock-run";
    lockProcess = "gtklock";
    notifyOnUnlock = true;
    scale = 1.0; # ajustează pentru ecranul laptopului principal
    gaps = {
      inner = 14;
      outer = 6;
    };

    scripts = {
      gtklock-run = mkScript { name = "gtklock-run"; };
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
  };

  home.packages = with pkgs; [
    libnotify
    calcurse
    grim
    slurp
    satty
  ];

  # ---------------------------------------------------------------- sway(fx)
  wayland.windowManager.sway = {
    config = {
      bars = [ ]; # waybar rulează ca serviciu systemd

      keybindings = {
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
      };

      startup = [ { command = exe "polkit-agent"; } ];
    };

    extraConfig = ''
      # Terminale popup (din bară / control center): plutitoare, centrate, dimensiune fixă
      for_window [app_id="^popup-"] floating enable, resize set width 900 px height 560 px, move position center

      # SwayFX: colțuri rotunjite, umbre subtile, ferestrele inactive estompate.
      # Fără blur (hardware modest); de încercat doar pe bară:
      #   blur enable
      #   layer_effects "waybar" blur enable
      corner_radius ${r}
      smart_corner_radius disable
      shadows enable
      shadows_on_csd disable
      shadow_blur_radius 16
      shadow_color #00000066
      default_dim_inactive 0.08
      dim_inactive_colors.unfocused #000000FF
      dim_inactive_colors.urgent #${c.base08}FF
      blur disable
    '';
  };

  # ---------------------------------------------------------------- bară
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    settings.main = {
      layer = "top";
      position = "top";
      height = 30;
      margin-top = 6;
      margin-left = 8;
      margin-right = 8;
      spacing = 4;

      modules-left = [
        "sway/workspaces"
        "sway/mode"
      ];
      modules-center = [ "clock" ];
      modules-right = [
        "custom/timer"
        "mpris"
        "sway/language"
        "network"
        "bluetooth"
        "wireplumber"
        "battery"
        "custom/power"
      ];

      "sway/workspaces" = {
        disable-scroll = true;
        all-outputs = true;
        format = "{name}";
      };

      "sway/mode".format = "{}";

      clock = {
        format = "{:%a %d %b  %H:%M}";
        tooltip = false;
        on-click = popup "calendar" "calcurse";
      };

      network = {
        format-wifi = "{icon} {essid}";
        format-ethernet = "${icons.ethernet} eth";
        format-linked = "${icons.wifiOff} fără IP";
        format-disconnected = icons.wifiOff;
        format-icons = with icons; [
          wifi1
          wifi2
          wifi3
          wifi4
        ];
        tooltip-format = "{ifname}: {ipaddr}  {signalStrength}%";
        on-click = popup "wifi" "impala";
      };

      bluetooth = {
        format = icons.bluetooth;
        format-off = icons.bluetoothOff;
        format-disabled = icons.bluetoothOff;
        format-connected = "${icons.bluetoothConnected} {num_connections}";
        tooltip-format-connected = "{device_enumerate}";
        tooltip-format-enumerate-connected = "{device_alias}";
        on-click = popup "bluetooth" "bluetui";
        on-click-right = "bluetoothctl show | grep -q 'Powered: yes' && bluetoothctl power off || bluetoothctl power on";
      };

      wireplumber = {
        format = "{icon} {volume}%";
        format-muted = "${icons.volMute} mute";
        format-icons = with icons; [
          volLow
          volMid
          volHigh
        ];
        on-click = popup "audio" "wiremix";
        on-click-right = "${osd} --output-volume mute-toggle";
        on-scroll-up = "${osd} --output-volume raise";
        on-scroll-down = "${osd} --output-volume lower";
      };

      battery = {
        interval = 30;
        states = {
          warning = 30;
          critical = 15;
        };
        format = "{icon} {capacity}%";
        format-charging = "${icons.batCharging} {capacity}%";
        format-plugged = "${icons.batPlugged} {capacity}%";
        format-icons = with icons; [
          bat10
          bat30
          bat50
          bat70
          bat90
          batFull
        ];
        tooltip-format = "{timeTo}";
      };

      # Doar când cântă ceva
      # (formatul gol ascunde modulul; doar starea „playing” are text)
      mpris = {
        format = "";
        format-playing = "${icons.music} {artist} – {title}";
        max-length = 40;
        tooltip-format = "{player}: {artist} – {title}";
        on-click = popup "music" "rmpc";
        on-click-right = "playerctl play-pause";
        on-scroll-up = "playerctl next";
        on-scroll-down = "playerctl previous";
      };

      # Doar când rulează un timer
      "custom/timer" = {
        exec = "${exe "timer"} status";
        return-type = "json";
        interval = 15;
        signal = 8;
        format = "${icons.timer} {}";
        hide-empty-text = true;
        on-click = popup "timer" "${exe "timer"} report";
        on-click-right = "${exe "timer"} stop; pkill -RTMIN+8 waybar";
      };

      "sway/language" = {
        format = "{short}";
        tooltip = false;
        on-click = "swaymsg input type:keyboard xkb_switch_layout next";
      };

      "custom/power" = {
        format = icons.power;
        tooltip-format = "Lock screen (power)";
        on-click = "${exe "session"} lock";
      };
    };

    style = ''
      * {
        font-family: "${theme.font.name}";
        font-size: ${toString (theme.font.size + 3)}px;
        border: none;
        min-height: 0;
      }

      window#waybar {
        background: alpha(#${theme.bg}, 0.92);
        color: #${theme.fg};
        border-radius: ${r}px;
      }

      tooltip {
        background: #${theme.bg};
        border: 1px solid #${c.base02};
        border-radius: ${r}px;
      }

      #workspaces button {
        padding: 0 8px;
        color: #${theme.muted};
        background: transparent;
        border-radius: ${r}px;
        box-shadow: none;
      }

      #workspaces button:hover {
        background: #${c.base01};
      }

      #workspaces button.focused {
        color: #${theme.bg};
        background: #${theme.accent};
      }

      #workspaces button.urgent {
        color: #${c.base08};
      }

      #mode {
        color: #${c.base0A};
        padding: 0 10px;
      }

      #clock,
      #network,
      #bluetooth,
      #wireplumber,
      #battery,
      #mpris,
      #language,
      #custom-timer,
      #custom-power {
        padding: 0 10px;
      }

      #network { color: #${c.base0D}; }
      #network.disconnected { color: #${theme.muted}; }
      #bluetooth { color: #${c.base0D}; }
      #bluetooth.off, #bluetooth.disabled { color: #${theme.muted}; }
      #wireplumber { color: #${c.base0B}; }
      #wireplumber.muted { color: #${theme.muted}; }
      #battery { color: #${c.base0A}; }
      #battery.warning:not(.charging) { color: #${c.base09}; }
      #battery.critical:not(.charging) { color: #${c.base08}; }
      #mpris { color: #${c.base0E}; }
      #language { color: #${theme.muted}; }
      #custom-timer { color: #${theme.accent}; }
      #custom-power { color: #${c.base08}; padding-right: 14px; }
    '';
  };

  # ---------------------------------------------------------------- notificări / OSD
  services.mako = {
    enable = true;
    settings = {
      border-color = lib.mkForce "#${theme.accent}";
      anchor = "top-right";
      margin = "10";
      padding = "12";
      width = 360;
      border-size = 2;
      border-radius = theme.radius;
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

  # ---------------------------------------------------------------- lock + power
  # gtklock e din sistem (PAM); configul și stilul vin de aici.
  xdg.configFile."gtklock/config.ini".text = ''
    [main]
    time-format=%H:%M

    [powerbar]
    show-labels=false
    linked-buttons=false
    reboot-command=systemctl reboot
    poweroff-command=systemctl poweroff
    suspend-command=systemctl suspend
    logout-command=swaymsg exit
    userswitch-command=

    [playerctl]
    art-size=64
    position=top-center
  '';

  xdg.configFile."gtklock/style.css".text = import ./lock-css.nix {
    inherit theme;
    wallpaper = if theme.hasWallpaper then "${theme.wallpaper}" else null;
  };

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

  # Aceeași rază a colțurilor ca restul.
  programs.fuzzel.settings.border.radius = theme.radius;
}
