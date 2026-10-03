# Secundar — "barebones but with style".
# Sway simplu, swaybar + i3status, swaylock(-effects), fără notificări / OSD /
# popup-uri / polkit / portals / GTK. Stilul vine din paletă și terminalul transparent.
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
  hash = x: "#${x}";
  # iconiță colorată (pango) pentru blocurile din swaybar
  icon = color: glyph: "<span color='#${color}'>${glyph}</span>";

  # false dacă distribuția are doar swaylock simplu (fără blur / ceas);
  # wallpaper-ul rămâne, doar fără blur.
  swaylockEffects = true;
in
{
  dotfiles = {
    host = "second";
    lockCommand = "swaylock";
    lockProcess = "swaylock";
    notifyOnUnlock = false; # timerul se reia din terminal: `retrack`
    scale = 1.0; # ajustează pentru ecranul laptopului secundar
    gaps = {
      # sway pune la margine outer + inner: 8 + (-1) = 7 (jumătate din 14)
      inner = 8;
      outer = -1;
    };

    scripts.swaybar-status = mkScript {
      name = "swaybar-status";
      runtimeInputs = [
        pkgs.i3status
        pkgs.jq
        cfg.scripts.timer
      ];
      env = {
        I3STATUS_CONFIG = "${config.xdg.configHome}/i3status/config";
        TIMER_ICON = icons.timer;
        TIMER_COLOR = hash theme.accent;
        LAYOUT_ICON = icons.keyboard;
        LAYOUT_COLOR = hash c.base08;
      };
    };
  };

  # Colțuri drepte.
  programs.fuzzel.settings.border.radius = 0;

  # ---------------------------------------------------------------- sway
  wayland.windowManager.sway.config = {
    # Direcția split-ului: latura unde apare următoarea fereastră (dreapta pentru
    # splith, jos pentru splitv) e într-un verde mai deschis decât bordura.
    keybindings = {
      "${mod}+x" = "exec ${exe "power-menu"}";

      "--locked XF86AudioRaiseVolume" = "exec wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+";
      "--locked XF86AudioLowerVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
      "--locked XF86AudioMute" = "exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
      "--locked XF86AudioMicMute" = "exec wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
      "--locked XF86MonBrightnessUp" = "exec ${lib.getExe pkgs.brightnessctl} set 5%+";
      "--locked XF86MonBrightnessDown" = "exec ${lib.getExe pkgs.brightnessctl} set 5%-";
    };

    bars = [
      {
        position = "top";
        statusCommand = exe "swaybar-status";
        command = "swaybar"; # cel din sistem, ca sway
        fonts = {
          names = [ theme.font.name ];
          size = theme.font.size + 0.0;
        };
        trayOutput = "none";
        extraConfig = ''
          status_padding 4
          status_edge_padding 12
          separator_symbol "│"
        '';
        colors = {
          background = "${hash theme.bg}00"; # transparent
          statusline = hash theme.fg;
          separator = hash c.base02;
          # doar cifra colorată, fără dreptunghi
          focusedWorkspace = {
            border = "${hash theme.bg}00";
            background = "${hash theme.bg}00";
            text = hash theme.accent;
          };
          activeWorkspace = {
            border = "${hash theme.bg}00";
            background = "${hash theme.bg}00";
            text = hash theme.fg;
          };
          inactiveWorkspace = {
            border = "${hash theme.bg}00";
            background = "${hash theme.bg}00";
            text = hash theme.muted;
          };
          urgentWorkspace = {
            border = "${hash theme.bg}00";
            background = "${hash theme.bg}00";
            text = hash c.base08;
          };
          bindingMode = {
            border = hash c.base0A;
            background = hash c.base0A;
            text = hash theme.bg;
          };
        };
      }
    ];
  };

  # Fiecare modul: iconiță colorată + valoare, separate de swaybar cu „│”.
  programs.i3status = {
    enable = true;
    enableDefault = false;
    general = {
      output_format = "i3bar";
      markup = "pango";
      colors = false; # culorile vin din iconițe
      interval = 2;
    };
    modules = {
      "wireless _first_" = {
        position = 1;
        settings = {
          format_up = "${icon c.base0D icons.wifi} %essid";
          format_down = "${icon c.base0D icons.wifiOff} off";
        };
      };
      "volume master" = {
        position = 2;
        settings = {
          format = "${icon c.base0B icons.volHigh} %volume";
          format_muted = "${icon theme.muted icons.volMute} mute";
          device = "pulse";
        };
      };
      "tztime local" = {
        position = 3;
        settings.format = "${icon c.base0A icons.clockOutline} %H:%M";
      };
    };
  };

  # ---------------------------------------------------------------- lock
  # swaylock(-effects) e din sistem (PAM); configul vine de aici.
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
  ''
  + lib.optionalString swaylockEffects ''
    effect-blur=8x3
    effect-vignette=0.5:0.6
    clock
    indicator
    timestr=%H:%M
    datestr=%a %d %b
  '';

  # ---------------------------------------------------------------- idle
  services.swayidle =
    let
      session = exe "session";
    in
    {
      enable = true;
      timeouts = [
        {
          timeout = 300; # 5:00 — lock
          command = "${session} lock";
        }
        {
          timeout = 330; # 5:30 — ecran stins
          command = "swaymsg 'output * power off'";
          resumeCommand = "swaymsg 'output * power on'";
        }
      ];
      events = {
        before-sleep = "${session} lock";
        lock = "${session} lock";
      };
    };
}
