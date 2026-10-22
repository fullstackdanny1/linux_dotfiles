# Fișierele de sistem: greetd cu tuigreet și wrapper-ul de sesiune sway.
# Rezultatul are structura rădăcinii (etc/…, usr/local/bin/…) și e copiat de
# `./install.sh`. @GREETER_USER@ e înlocuit la instalare.
{ pkgs }:
let
  inherit (pkgs) lib;

  # tuigreet în terminal, culori ANSI apropiate de paletă.
  tuigreet = lib.concatStringsSep " " [
    "tuigreet"
    "--time"
    "--remember"
    "--asterisks"
    "--greeting 'n4r77'"
    "--cmd sway-session"
    "--theme 'border=gray;title=green;greet=white;prompt=green;input=white;time=gray;action=gray;button=yellow;container=black;text=white'"
  ];

  greetdConfig = pkgs.writeText "greetd-config.toml" ''
    [terminal]
    vt = 1

    [default_session]
    command = "${tuigreet}"
    user = "@GREETER_USER@"
  '';
in
pkgs.runCommand "n4r77-system-files" { } ''
  mkdir -p $out/etc/greetd $out/usr/local/bin
  install -m755 ${./sway-session} $out/usr/local/bin/sway-session
  install -m644 ${greetdConfig} $out/etc/greetd/config.toml
''
