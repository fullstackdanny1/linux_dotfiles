# Fișierele de sistem pentru un host, randate cu aceeași temă ca home-manager.
# Rezultatul are structura rădăcinii (etc/…, usr/local/bin/…) și e copiat cu
# `./install.sh <host> system`. @GREETER_USER@ e înlocuit la instalare.
{ pkgs, host }:
let
  inherit (pkgs) lib;
  theme = import ../home/theme.nix;
  c = theme.scheme;
  wallpaper = "/etc/greetd/wallpaper.png";

  greetdConfig =
    command:
    pkgs.writeText "greetd-config.toml" ''
      [terminal]
      vt = 1

      [default_session]
      command = "${command}"
      user = "@GREETER_USER@"
    '';

  keyboard = ''
    input type:keyboard {
      xkb_layout us,ro
      xkb_variant ,std
      xkb_options caps:escape_shifted_capslock
    }
    input type:touchpad tap enabled
  '';

  # Principal: gtkgreet într-o instanță minimală de sway, stilizat ca gtklock.
  greeterSway = pkgs.writeText "greetd-sway-config" ''
    # Greeter: sway minimal care rulează doar gtkgreet.
    include /etc/sway/config.d/*

    ${keyboard}
    output * bg ${if theme.hasWallpaper then "${wallpaper} fill" else "#${theme.bg} solid_color"}
    default_border none
    seat * hide_cursor 5000

    bindsym Mod4+Shift+e exec swaynag -t warning -m 'Power' -Z 'Power off' 'systemctl poweroff' -Z 'Reboot' 'systemctl reboot'

    exec "gtkgreet -l -s /etc/greetd/gtkgreet.css; swaymsg exit"
  '';

  gtkgreetCss = pkgs.writeText "gtkgreet.css" (
    import ../home/lock-css.nix {
      inherit theme;
      wallpaper = if theme.hasWallpaper then wallpaper else null;
    }
  );

  # Secundar: tuigreet în terminal, culori ANSI apropiate de paletă.
  tuigreet = lib.concatStringsSep " " [
    "tuigreet"
    "--time"
    "--remember"
    "--asterisks"
    "--greeting 'barebones but with style'"
    "--cmd sway-session"
    "--theme 'border=green;title=green;greet=white;prompt=green;input=white;time=gray;action=gray;button=yellow;container=black;text=white'"
  ];
in
pkgs.runCommand "dotfiles-system-${host}" { } (
  ''
    mkdir -p $out/etc/greetd $out/usr/local/bin
    install -m755 ${./sway-session} $out/usr/local/bin/sway-session
  ''
  + lib.optionalString (host == "main") ''
    install -m644 ${greetdConfig "sway --config /etc/greetd/sway-config"} $out/etc/greetd/config.toml
    install -m644 ${greeterSway} $out/etc/greetd/sway-config
    install -m644 ${gtkgreetCss} $out/etc/greetd/gtkgreet.css
    echo sway-session > $out/etc/greetd/environments
    chmod 644 $out/etc/greetd/environments
  ''
  + lib.optionalString (host == "second") ''
    install -m644 ${greetdConfig tuigreet} $out/etc/greetd/config.toml
  ''
  + lib.optionalString (host == "main" && theme.hasWallpaper) ''
    install -m644 ${theme.wallpaper} $out${wallpaper}
  ''
)
