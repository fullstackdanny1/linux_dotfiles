#!/usr/bin/env bash
# Instalare dotfiles.
#
#   ./install.sh <main|second> [all|system|home]
#
#   system  pachetele din sistem (compositor, greeter, lock, servicii),
#           fișierele din /etc/greetd, /usr/local/bin/sway-session, serviciile
#   home    home-manager switch (tot restul, din Nix)
#   all     ambele (implicit)
set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")"

host="${1:-}"
step="${2:-all}"

usage() {
  echo "usage: $0 <main|second> [all|system|home]" >&2
  exit 1
}

case "$host" in main | second) ;; *) usage ;; esac
case "$step" in all | system | home) ;; *) usage ;; esac

say() { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m==>\033[0m %s\n' "$*" >&2; }

nix_cmd() { nix --extra-experimental-features 'nix-command flakes' "$@"; }

require_nix() {
  if ! command -v nix >/dev/null; then
    warn "Nix nu e instalat. Instalează-l (multi-user) și rulează din nou:"
    warn "  curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install"
    exit 1
  fi
}

# ------------------------------------------------------------------ pachete

detect_pm() {
  for pm in dnf pacman zypper apt-get; do
    if command -v "$pm" >/dev/null; then
      echo "$pm"
      return
    fi
  done
  echo none
}

# Nume upstream → numele din distribuție. "a|b" = încearcă a, apoi b.
packages_for() {
  local pm="$1"
  local common main second
  case "$pm" in
    dnf)
      common="greetd pipewire wireplumber pipewire-pulseaudio iwd bluez"
      main="swayfx gtkgreet gtklock gtklock-powerbar-module gtklock-playerctl-module power-profiles-daemon lxqt-policykit|polkit-gnome xdg-desktop-portal-wlr xdg-desktop-portal-gtk"
      second="sway tuigreet swaylock-effects|swaylock"
      ;;
    pacman)
      common="greetd pipewire wireplumber pipewire-pulse iwd bluez bluez-utils"
      main="swayfx greetd-gtkgreet gtklock gtklock-powerbar-module gtklock-playerctl-module power-profiles-daemon lxqt-policykit|polkit-gnome xdg-desktop-portal-wlr xdg-desktop-portal-gtk"
      second="sway greetd-tuigreet swaylock-effects|swaylock"
      ;;
    zypper)
      common="greetd pipewire wireplumber pipewire-pulseaudio iwd bluez"
      main="swayfx gtkgreet gtklock gtklock-powerbar-module gtklock-playerctl-module power-profiles-daemon lxqt-policykit|polkit-gnome xdg-desktop-portal-wlr xdg-desktop-portal-gtk"
      second="sway tuigreet swaylock-effects|swaylock"
      ;;
    apt-get)
      common="greetd pipewire wireplumber pipewire-pulse iwd bluez"
      main="swayfx gtkgreet gtklock gtklock-powerbar-module gtklock-playerctl-module power-profiles-daemon lxqt-policykit|policykit-1-gnome xdg-desktop-portal-wlr xdg-desktop-portal-gtk"
      second="sway tuigreet swaylock-effects|swaylock"
      ;;
  esac
  if [ "$host" = main ]; then echo "$common $main"; else echo "$common $second"; fi
}

pm_install() {
  local pm="$1" pkg="$2"
  case "$pm" in
    dnf) sudo dnf install -y --allowerasing "$pkg" ;;
    pacman) sudo pacman -S --needed --noconfirm "$pkg" ;;
    zypper) sudo zypper --non-interactive install "$pkg" ;;
    apt-get) sudo apt-get install -y "$pkg" ;;
  esac
}

install_packages() {
  local pm missing=() spec alt ok
  pm=$(detect_pm)
  if [ "$pm" = none ]; then
    warn "Manager de pachete necunoscut; instalează manual: $(packages_for dnf)"
    return
  fi
  say "Pachete din sistem ($pm)"
  [ "$pm" = apt-get ] && sudo apt-get update
  for spec in $(packages_for "$pm"); do
    ok=0
    IFS='|' read -ra alts <<<"$spec"
    for alt in "${alts[@]}"; do
      if pm_install "$pm" "$alt"; then
        ok=1
        break
      fi
    done
    [ "$ok" = 1 ] || missing+=("$spec")
  done
  if [ ${#missing[@]} -gt 0 ]; then
    warn "Nu s-au putut instala: ${missing[*]}"
    warn "Probabil sunt în COPR (Fedora) / AUR (Arch) — vezi README.md, apoi rulează din nou."
  fi
}

# ------------------------------------------------------------------ fișiere de sistem

greeter_user() {
  for u in greeter greetd _greetd; do
    if id "$u" >/dev/null 2>&1; then
      echo "$u"
      return
    fi
  done
  echo greeter
}

install_system_files() {
  say "Fișiere de sistem (greetd, sway-session)"
  local out file dest user
  out=$(nix_cmd build --no-link --print-out-paths ".#system-$host")
  user=$(greeter_user)
  (cd "$out" && find . -type f) | while read -r file; do
    file="${file#./}"
    dest="/$file"
    if [ -e "$dest" ] && [ ! -e "$dest.orig" ]; then sudo cp -a "$dest" "$dest.orig"; fi
    if [ -x "$out/$file" ]; then
      sudo install -Dm755 "$out/$file" "$dest"
    else
      sudo install -Dm644 "$out/$file" "$dest"
    fi
    echo "  $dest"
  done
  sudo sed -i "s/@GREETER_USER@/$user/" /etc/greetd/config.toml
}

# ------------------------------------------------------------------ servicii

configure_services() {
  say "Servicii"

  # Wi-Fi prin iwd (impala vorbește cu iwd). Dacă există NetworkManager, îl
  # punem să folosească iwd ca backend; altfel iwd își face singur DHCP.
  if systemctl list-unit-files NetworkManager.service >/dev/null 2>&1 &&
    systemctl is-enabled --quiet NetworkManager 2>/dev/null; then
    printf '[device]\nwifi.backend=iwd\n' | sudo tee /etc/NetworkManager/conf.d/wifi-backend-iwd.conf >/dev/null
    sudo systemctl disable --now wpa_supplicant 2>/dev/null || true
    sudo systemctl enable iwd
    sudo systemctl restart NetworkManager || true
  else
    sudo mkdir -p /etc/iwd
    [ -f /etc/iwd/main.conf ] || printf '[General]\nEnableNetworkConfiguration=true\n' | sudo tee /etc/iwd/main.conf >/dev/null
    sudo systemctl enable --now iwd
  fi

  sudo systemctl enable --now bluetooth || warn "bluetooth nu a putut fi pornit"
  if [ "$host" = main ]; then
    sudo systemctl enable --now power-profiles-daemon || warn "power-profiles-daemon nu a putut fi pornit"
  fi

  # greetd devine display manager-ul (înlocuiește gdm/sddm/lightdm).
  sudo systemctl enable --force greetd
  sudo systemctl set-default graphical.target
  say "greetd activat — pornește la următorul boot."
}

# ------------------------------------------------------------------ home-manager

switch_home() {
  say "home-manager switch (.#$host)"
  nix_cmd run home-manager/master -- switch -b backup --flake ".#$host"

  # Aplicațiile din Nix care folosesc OpenGL/Vulkan au nevoie de driverele GPU
  # expuse în /run/opengl-driver pe distribuții non-NixOS.
  local setup
  setup=$(readlink -f "$HOME/.nix-profile/bin/non-nixos-gpu-setup" 2>/dev/null || true)
  if [ -n "$setup" ] && [ -x "$setup" ]; then
    say "Drivere GPU pentru aplicațiile din Nix"
    sudo "$setup"
  fi
}

# ------------------------------------------------------------------

require_nix
if [ "$step" = all ] || [ "$step" = system ]; then
  install_packages
  install_system_files
  configure_services
fi
if [ "$step" = all ] || [ "$step" = home ]; then
  switch_home
fi
say "Gata ($host). Repornește sau deloghează-te ca să intri prin greetd."
