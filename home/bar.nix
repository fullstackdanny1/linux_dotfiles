# Bara: swaybar (din sistem, ca sway) + i3status-rust. Sus, needitabilă, fundal
# transparent; fiecare modul = iconiță colorată + valoare, separate de „│”.
{
  config,
  lib,
  theme,
  icons,
  ...
}:
let
  cfg = config.dotfiles;
  exe = name: lib.getExe cfg.scripts.${name};
  c = theme.scheme;
  hash = x: "#${x}";
  transparent = "${hash theme.bg}00";
  # iconiță colorată (pango)
  icon = color: glyph: "<span color='#${color}'>${glyph}</span>";
  popup = name: cmd: "${exe "popup"} ${name} ${cmd}";
in
{
  programs.i3status-rust = {
    enable = true;
    bars.top = {
      settings = {
        icons.icons = "material-nf";
        # „native”: fără fundal propriu, culorile vin din swaybar și din iconițe
        theme.theme = "native";
      };
      blocks = [
        # timerul de time tracking, doar când rulează
        {
          block = "custom";
          command = "${exe "timer"} status --plain";
          interval = 15;
          hide_when_empty = true;
          format = " ${icon theme.accent icons.timer} $text ";
          click = [
            {
              button = "left";
              cmd = popup "timer" "${exe "timer"} report";
            }
            {
              button = "right";
              cmd = "${exe "timer"} stop";
              update = true;
            }
          ];
        }
        {
          block = "keyboard_layout";
          driver = "sway";
          format = " ${icon c.base08 icons.keyboard} $layout ";
          mappings = {
            "English (US)" = "US";
            "Romanian (standard)" = "RO";
          };
        }
        {
          block = "net";
          device = "^wl";
          format = " ${icon c.base0D icons.wifi} $ssid ";
          inactive_format = " ${icon c.base0D icons.wifiOff} off ";
          missing_format = " ${icon c.base0D icons.wifiOff} off ";
          click = [
            {
              button = "left";
              cmd = popup "wifi" "impala";
            }
          ];
        }
        {
          block = "sound";
          format = " ${icon c.base0B "$icon"} $volume.eng(w:2) ";
          click = [
            {
              button = "left";
              cmd = popup "audio" "wiremix";
            }
          ];
        }
        {
          block = "time";
          interval = 10;
          format = " ${icon c.base0A icons.clockOutline} $timestamp.datetime(f:'%H:%M') ";
        }
      ];
    };
  };

  wayland.windowManager.sway.config.bars = [
    {
      position = "top";
      statusCommand = "${lib.getExe config.programs.i3status-rust.package} ${config.xdg.configHome}/i3status-rust/config-top.toml";
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
        background = transparent;
        statusline = hash theme.fg;
        separator = hash c.base02;
        # doar cifra colorată, fără dreptunghi
        focusedWorkspace = {
          border = transparent;
          background = transparent;
          text = hash theme.accent;
        };
        activeWorkspace = {
          border = transparent;
          background = transparent;
          text = hash theme.fg;
        };
        inactiveWorkspace = {
          border = transparent;
          background = transparent;
          text = hash theme.muted;
        };
        urgentWorkspace = {
          border = transparent;
          background = transparent;
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
}
