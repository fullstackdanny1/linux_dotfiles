# Sway, Fuzzel, foot, Helix și tmux: mici corecții transversale care nu se potrivesc
# într-un singur modul de aplicație.
{ lib, theme, ... }:
{
  # Etichetă pentru launcherul principal; meniurile specifice păstrează prompturile lor.
  programs.fuzzel.settings.main = {
    prompt = lib.mkForce "apps ";
    icon-theme = lib.mkForce "Papirus-Dark";
  };
  programs.fuzzel.settings.colors = {
    selection = lib.mkForce "${theme.accent}ff";
    selection-text = lib.mkForce "${theme.bg}ff";
    selection-match = lib.mkForce "${theme.scheme.base0A}ff";
    border = lib.mkForce "${theme.accent}ff";
  };
  programs.fuzzel.settings.border.radius = lib.mkForce 0;

  # Ctrl+Shift+C copiază selecția în clipboard-ul Wayland. OSC 52 permite
  # aplicațiilor din tmux să trimită yanks către clipboard-ul hostului.
  programs.foot.settings = {
    key-bindings.clipboard-copy = "Control+Shift+c";
    security.osc52 = "copy-enabled";
  };

  programs.helix.settings.editor = {
    clipboard-provider = "wayland";
    default-yank-register = "+";
  };

  # tmux negociază OSC 52 cu foot; păstrăm RGB și undercurl.
  programs.tmux.extraConfig = ''
    set -as terminal-features ",foot*:clipboard"
  '';

  # Regulă Satty cerută explicit și dimensiuni mari doar pentru monitor/cheatsheet;
  # păstrăm geometria generală a popup-urilor.
  wayland.windowManager.sway.extraConfig = ''
    for_window [app_id="(?i)satty"] floating enable, move position center, resize set width 960 px height 640 px
    for_window [app_id="^popup-sysmon$"] floating enable, resize set width 80 ppt height 80 ppt, move position center
    for_window [app_id="^popup-cheatsheet$"] floating enable, resize set width 80 ppt height 80 ppt, move position center
  '';

  # Inhibit nu este implementat de portalul folosit în sesiunea aceasta; nu-l
  # selectăm ca backend și evităm interogarea inutilă la pornirea Satty.
  xdg.configFile."xdg-desktop-portal/sway-portals.conf".text = lib.mkForce ''
    [preferred]
    default=gtk
    org.freedesktop.impl.portal.ScreenCast=wlr
    org.freedesktop.impl.portal.Screenshot=wlr
  '';
}
