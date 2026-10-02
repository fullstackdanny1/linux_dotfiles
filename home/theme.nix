# Sursa unică pentru aspect. Folosită de Stylix (home-manager) și de fișierele
# de sistem (greeter, /etc/greetd), ca loginul să arate la fel ca restul.
rec {
  # Gruvbox dark, hard — paleta din configurațiile anterioare.
  scheme = {
    scheme = "Gruvbox dark, hard (dotfiles)";
    author = "Dawid Kurek, morhetz";
    base00 = "1d2021"; # fundal
    base01 = "3c3836";
    base02 = "504945";
    base03 = "665c54";
    base04 = "bdae93";
    base05 = "d5c4a1";
    base06 = "ebdbb2"; # text
    base07 = "fbf1c7";
    base08 = "fb4934"; # roșu
    base09 = "fe8019"; # portocaliu
    base0A = "fabd2f"; # galben
    base0B = "b8bb26"; # verde
    base0C = "8ec07c"; # aqua
    base0D = "83a598"; # albastru
    base0E = "d3869b"; # mov
    base0F = "d65d0e";
  };

  # Accentul (verdele estompat din vechiul sway/foot/fuzzel).
  accent = "689d6a";
  bg = scheme.base00;
  fg = scheme.base06;
  muted = "928374";

  font = {
    name = "JetBrainsMono Nerd Font";
    size = 11; # bară, launcher, notificări
    terminalSize = 12;
  };

  # Raza colțurilor pe principal: compositor, bară, launcher, notificări, lock, login.
  radius = 8;

  cursor = {
    name = "Bibata-Modern-Classic";
    size = 24;
  };

  terminalOpacity = 0.90;

  # Pune o imagine aici (și fă `git add`), altfel se folosește culoarea de fundal.
  wallpaper = ../wallpapers/wallpaper.png;
  hasWallpaper = builtins.pathExists wallpaper;
}
