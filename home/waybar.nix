# Bara Waybar (sus, module clickabile). Activă cu `--bar waybar`.
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
  exe = name: lib.getExe cfg.scripts.${name};
  c = theme.scheme;
  r = toString theme.radius;
  popup = name: cmd: "${exe "popup"} ${name} ${cmd}";
  osd = lib.getExe' pkgs.swayosd "swayosd-client";
in
lib.mkIf (cfg.bar == "waybar") {
  dotfiles.radius = theme.radius;
  wayland.windowManager.sway.config.bars = [ ]; # waybar rulează ca serviciu systemd

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
        # 1–3 apar mereu, chiar goale
        persistent-workspaces = {
          "1" = [ ];
          "2" = [ ];
          "3" = [ ];
        };
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
        tooltip-format = "click: meniu power, click dreapta: lock";
        on-click = exe "power-menu";
        on-click-right = "${exe "session"} lock";
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
        border-radius: 0;
        box-shadow: inset 0 -2px transparent;
      }

      #workspaces button:hover {
        background: transparent;
        color: #${theme.fg};
      }

      /* workspace-urile persistente goale, mai estompate */
      #workspaces button.persistent {
        color: #${c.base03};
      }

      /* doar cifra colorată + o linie sub ea, fără dreptunghi */
      #workspaces button.focused {
        color: #${theme.accent};
        background: transparent;
        box-shadow: inset 0 -2px #${theme.accent};
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
}
