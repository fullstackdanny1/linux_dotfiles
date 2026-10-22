# Swaybar + i3status (sus, needitabilă, fundal transparent). Activă cu `--bar swaybar`.
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
  c = theme.scheme;
  hash = x: "#${x}";
  # iconiță colorată (pango) pentru blocurile din swaybar
  icon = color: glyph: "<span color='#${color}'>${glyph}</span>";
in
lib.mkIf (cfg.bar == "swaybar") {
  dotfiles.radius = 0;

  dotfiles.scripts.swaybar-status = mkScript {
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

  wayland.windowManager.sway.config = {
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
}
