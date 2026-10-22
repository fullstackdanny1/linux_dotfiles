#!/usr/bin/env bash
# n4r77 setup v2.1.0 — instalare.
#
#   ./install.sh [--distro fedora|debian|arch] [--only system|home]
#
# Fără --distro, scriptul întreabă (distribuția detectată e sugestia implicită).
#
#   1. utilitarele de sistem care nu vin din Nix (sway, swaylock, greetd,
#      pipewire, git, …), doar dacă lipsesc
#   2. Nix, dacă lipsește
#   3. /etc/greetd/config.toml și /usr/local/bin/sway-session, serviciile
#   4. configurile din Nix (home-manager)
set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")"

distro=""
only=""

usage() {
  sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'
  exit 1
}

while [ $# -gt 0 ]; do
  case "$1" in
    --distro) distro="${2:-}"; shift 2 ;;
    --only) only="${2:-}"; shift 2 ;;
    -h | --help) usage ;;
    *) usage ;;
  esac
done

say() { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m==>\033[0m %s\n' "$*" >&2; }

detect_distro() {
  local id="" like=""
  if [ -r /etc/os-release ]; then
    # shellcheck disable=SC1091
    id=$(. /etc/os-release && echo "${ID:-}")
    # shellcheck disable=SC1091
    like=$(. /etc/os-release && echo "${ID_LIKE:-}")
  fi
  case " $id $like " in
    *" fedora "*) echo fedora ;;
    *" debian "* | *" ubuntu "*) echo debian ;;
    *" arch "*) echo arch ;;
    *) echo "" ;;
  esac
}

choose() {
  local prompt="$1" default="$2"
  shift 2
  local options=("$@") answer
  echo "$prompt" >&2
  local i=1
  for o in "${options[@]}"; do
    if [ "$o" = "$default" ]; then echo "  $i) $o (implicit)" >&2; else echo "  $i) $o" >&2; fi
    i=$((i + 1))
  done
  read -rp "> " answer
  if [ -z "$answer" ] && [ -n "$default" ]; then
    echo "$default"
  elif [[ "$answer" =~ ^[0-9]+$ ]] && [ "$answer" -ge 1 ] && [ "$answer" -le ${#options[@]} ]; then
    echo "${options[$((answer - 1))]}"
  else
    echo "$answer"
  fi
}

[ -n "$distro" ] || distro=$(choose "Distribuția:" "$(detect_distro)" fedora debian arch)

case "$distro" in fedora | debian | arch) ;; *) warn "distribuție necunoscută: $distro"; usage ;; esac
case "$only" in "" | system | home) ;; *) usage ;; esac

# ------------------------------------------------------------------ pachete

# Pachetele din managerul distribuției. Fiecare intrare: nume pe fedora|debian|arch;
# „a/b” = încearcă a, apoi b; „-” = nu e nevoie pe distribuția respectivă.
packages=(
  "git|git|git"
  "curl|curl|curl"
  "xz|xz-utils|xz"
  "sway|sway|sway"
  "swaylock|swaylock|swaylock"
  "greetd|greetd|greetd"
  "tuigreet|tuigreet|greetd-tuigreet"
  "pipewire|pipewire|pipewire"
  "wireplumber|wireplumber|wireplumber"
  "pipewire-pulseaudio|pipewire-pulse|pipewire-pulse"
  "iwd|iwd|iwd"
  "bluez|bluez|bluez"
  "-|-|bluez-utils"
  "power-profiles-daemon|power-profiles-daemon|power-profiles-daemon"
  "lxqt-policykit|lxqt-policykit|lxqt-policykit"
  "xdg-desktop-portal-wlr|xdg-desktop-portal-wlr|xdg-desktop-portal-wlr"
  "xdg-desktop-portal-gtk|xdg-desktop-portal-gtk|xdg-desktop-portal-gtk"
  "podman|podman|podman"
  "distrobox|distrobox|distrobox"
)

field() {
  local line="$1" n="$2"
  cut -d'|' -f"$n" <<<"$line"
}

distro_index() {
  case "$distro" in fedora) echo 1 ;; debian) echo 2 ;; arch) echo 3 ;; esac
}

pkg_installed() {
  case "$distro" in
    fedora) rpm -q "$1" >/dev/null 2>&1 ;;
    debian) dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "install ok installed" ;;
    arch) pacman -Q "$1" >/dev/null 2>&1 ;;
  esac
}

pkg_install() {
  case "$distro" in
    fedora) sudo dnf install -y "$@" ;;
    debian) sudo apt-get install -y "$@" ;;
    arch) sudo pacman -S --needed --noconfirm "$@" ;;
  esac
}

pkg_refresh() {
  case "$distro" in
    debian) sudo apt-get update ;;
    arch) sudo pacman -Sy ;;
    fedora) : ;;
  esac
}

missing_pkgs=()

any_installed() {
  local alt
  for alt in ${1//\// }; do pkg_installed "$alt" && return 0; done
  return 1
}

install_alternatives() {
  local alt
  for alt in ${1//\// }; do pkg_install "$alt" && return 0; done
  return 1
}

install_packages() {
  local idx line name
  idx=$(distro_index)
  say "Pachete din sistem ($distro)"
  pkg_refresh
  local todo=()
  for line in "${packages[@]}"; do
    name=$(field "$line" "$idx")
    [ "$name" = "-" ] && continue
    any_installed "$name" || todo+=("$name")
  done
  if [ ${#todo[@]} -eq 0 ]; then
    echo "  toate sunt deja instalate"
    return
  fi
  echo "  de instalat: ${todo[*]}"
  # întâi toate odată (prima variantă din fiecare); dacă eșuează, pe rând,
  # cu alternativele, ca să vedem exact ce lipsește
  local first=()
  for name in "${todo[@]}"; do first+=("${name%%/*}"); done
  if ! pkg_install "${first[@]}"; then
    for name in "${todo[@]}"; do
      any_installed "$name" || install_alternatives "$name" || missing_pkgs+=("$name")
    done
  fi
}

# ------------------------------------------------------------------ nix

nix_cmd() { nix --extra-experimental-features 'nix-command flakes' "$@"; }

load_nix() {
  local f
  for f in /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh "$HOME/.nix-profile/etc/profile.d/nix.sh"; do
    # shellcheck disable=SC1090
    if [ -f "$f" ]; then . "$f"; return; fi
  done
}

install_nix() {
  load_nix
  if command -v nix >/dev/null; then
    say "Nix e deja instalat ($(nix --version))"
    return
  fi
  say "Instalez Nix (multi-user)"
  sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --daemon --yes
  load_nix
  command -v nix >/dev/null || {
    warn "nix nu e în PATH după instalare; deschide un shell nou și rulează din nou"
    exit 1
  }
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
  local out file dest
  out=$(nix_cmd build --no-link --print-out-paths ".#system-files")
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
  sudo sed -i "s/@GREETER_USER@/$(greeter_user)/" /etc/greetd/config.toml
}

configure_services() {
  say "Servicii"

  # Wi-Fi prin iwd (impala vorbește cu iwd). Dacă există NetworkManager, îl
  # punem să folosească iwd ca backend; altfel iwd își face singur DHCP.
  if systemctl is-enabled --quiet NetworkManager 2>/dev/null; then
    sudo mkdir -p /etc/NetworkManager/conf.d
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
  sudo systemctl enable --now power-profiles-daemon || warn "power-profiles-daemon nu a putut fi pornit"

  # greetd devine display manager-ul (înlocuiește gdm/sddm/lightdm).
  sudo systemctl enable --force greetd
  sudo systemctl set-default graphical.target
}

# ------------------------------------------------------------------ home-manager

switch_home() {
  say "Configurile din Nix (.#n4r77)"
  nix_cmd run home-manager/master -- switch -b backup --flake ".#n4r77"

  # Aplicațiile din Nix care folosesc OpenGL/Vulkan au nevoie de driverele GPU
  # expuse în /run/opengl-driver pe distribuții non-NixOS.
  local setup
  setup=$(readlink -f "$HOME/.nix-profile/bin/non-nixos-gpu-setup" 2>/dev/null || true)
  if [ -n "$setup" ] && [ -x "$setup" ]; then
    say "Drivere GPU pentru aplicațiile din Nix"
    sudo "$setup"
  fi
}

# ------------------------------------------------------------------ rezumat

summary() {
  echo
  say "Gata: n4r77 ($distro)"
  if [ ${#missing_pkgs[@]} -gt 0 ]; then
    warn "Nu s-au putut instala din $distro: ${missing_pkgs[*]}"
    warn "Instalează-le manual, apoi rulează din nou scriptul."
  fi
  echo
  echo "  Containerul de dev (o singură dată):  distrobox create -n dev -i <imagine>"
  echo "  Apoi repornește sau deloghează-te ca să intri prin greetd."
}

# ------------------------------------------------------------------

if [ "$only" != home ]; then
  install_packages
  install_nix
  install_system_files
  configure_services
else
  install_nix
fi
if [ "$only" != system ]; then
  switch_home
fi
summary
