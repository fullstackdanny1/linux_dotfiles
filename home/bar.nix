# Bara: swaybar (din sistem, ca sway) + i3status-rust. Sus, needitabilă, fundal
# negru (#1d2021); butoanele de workspace folosesc același fundal cu bara,
# fără bordură vizibilă.
#
# Ordine dreapta (strict dreapta -> stânga):
# Ceas & Dată | Baterie | Limbă | Nu deranja (când e activ) | Timer (când rulează)
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
  barBg = hash theme.bg;
  icon = color: glyph: "<span color='#${color}'>${glyph}</span>";
  popup = name: cmd: "${exe "popup"} ${name} ${cmd}";

  # Culori Gruvbox dark hard transmise către scriptul extern battery-bar:
  # verde închis (theme.accent) -> verde deschis (base0B) -> galben (base0A) -> roșu (base08)
  batteryEnv = "BAT_COLOR_DARK_GREEN='${theme.accent}' BAT_COLOR_LIGHT_GREEN='${c.base0B}' BAT_COLOR_YELLOW='${c.base0A}' BAT_COLOR_RED='${c.base08}'";
in
{
  programs.i3status-rust = {
    enable = true;
    bars.top = {
      settings = {
        icons.icons = "material-nf";
        theme.theme = "native";
      };
      blocks = [
        # --- Time tracker compact (vizibil doar când rulează) ---
        {
          block = "custom";
          command = "${exe "timer"} status --plain";
          interval = 5;
          hide_when_empty = true;
          format = " ${icon theme.accent icons.timer}$text ";
          click = [
            {
              button = "left";
              cmd = popup "timer" "${exe "timer"} report";
            }
            {
              button = "right";
              cmd = "${exe "timer"} stop; pkill -SIGRTMIN+1 i3status-rs || true";
              update = true;
            }
          ];
        }

        # --- Nu deranja (vizibil doar când e pornit) ---
        {
          block = "custom";
          signal = 1;
          command = "makoctl mode | grep -qx 'do-not-disturb' && echo 'on' || true";
          interval = 1;
          hide_when_empty = true;
          format = " ${icon c.base08 icons.bellOff} $text ";
          click = [
            {
              button = "left";
              cmd = "makoctl mode -r do-not-disturb";
              update = true;
            }
          ];
        }

        # --- Indicator Limbă (fără iconiță) ---
        {
          block = "keyboard_layout";
          driver = "sway";
          format = " $layout ";
          mappings = {
            "English (US)" = "US";
            "Romanian (standard)" = "RO";
          };
        }

        # --- Baterie (script separat: 4 culori + notificări + auto-poweroff la 6%) ---
        {
          block = "custom";
          command = "${batteryEnv} ${exe "battery-bar"}";
          interval = 2;
          hide_when_empty = true;
          format = " $text.pango-str() ";
          click = [
            {
              button = "left";
              cmd = exe "battery-status";
            }
          ];
        }

        # --- Ceas & Dată (fără iconiță) ---
        {
          block = "time";
          interval = 1;
          format = " $timestamp.datetime(f:'%a, %d %b  %H:%M') ";
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
        status_padding 5
        status_edge_padding 3
        separator_symbol ""
        workspace_buttons yes
      '';
      colors = {
        background = barBg;
        statusline = hash theme.fg;
        separator = barBg;
        focusedWorkspace = {
          border = barBg;
          background = barBg;
          text = hash theme.accent;
        };
        activeWorkspace = {
          border = barBg;
          background = barBg;
          text = hash theme.fg;
        };
        inactiveWorkspace = {
          border = barBg;
          background = barBg;
          text = hash theme.muted;
        };
        urgentWorkspace = {
          border = hash c.base08;
          background = hash c.base08;
          text = hash theme.fg;
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
