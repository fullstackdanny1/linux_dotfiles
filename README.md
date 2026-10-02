# linux_dotfiles

Două laptopuri, două configurații Sway, o bază comună. Tot ce ține de utilizator
e declarat cu Nix + home-manager; tema vine dintr-o singură sursă (Stylix +
`home/theme.nix`).

| | `main` | `second` |
|---|---|---|
| **Nume** | *elegant, yet minimal* | *barebones but with style* |
| **Compositor** | SwayFX | Sway |
| **Bară** | Waybar, module clickabile | swaybar + i3status |
| **Login** | greetd + gtkgreet | greetd + tuigreet |
| **Lock + power** | gtklock (+ powerbar, playerctl) | swaylock-effects + aliasuri |

## Structură

```
flake.nix               homeConfigurations.{main,second} + packages.system-{main,second}
install.sh              instalare: pachete din sistem, /etc/greetd, servicii, home-manager
home/
  theme.nix             paleta (Gruvbox dark hard), accent, font, rază, cursor, wallpaper
  common.nix            pachete, shell + aliasuri, editoare, foot, fuzzel, mpd, syncthing, Stylix
  sway-common.nix       input, keybinds, reguli de ferestre, wallpaper, lid, scratchpad
  main.nix              SwayFX, waybar, gtklock, mako, swayosd, idle, capturi, gammastep, kanshi
  second.nix            swaybar + i3status, swaylock, idle
  lock-css.nix          CSS comun pentru gtklock și gtkgreet (lock = login)
  icons.nix             glife Nerd Font
  scripts/*.sh          scripturi (împachetate cu writeShellApplication, verificate cu shellcheck)
system/
  default.nix           /etc/greetd/* și /usr/local/bin/sway-session, randate cu aceeași temă
  sway-session          pornește sway cu profilul Nix în PATH
wallpapers/             pune aici wallpaper.png
```

## Instalare

Distribuție non-NixOS cu systemd. Ai nevoie de Nix (multi-user):

```sh
curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install
```

Apoi, pe fiecare laptop:

```sh
git clone <repo> ~/linux_dotfiles && cd ~/linux_dotfiles
# userul e setat în flake.nix (user.name / user.home) — schimbă-l dacă diferă
./install.sh main           # sau: ./install.sh second
```

Pași separați: `./install.sh main system` (pachete, /etc, servicii) și
`./install.sh main home` (doar home-manager). După modificări în config:

```sh
nix run home-manager -- switch --flake .#main
```

### Ce face `install.sh <host> system`

1. Instalează din sistem compositorul, greeter-ul, lock-ul și serviciile
   (pipewire, wireplumber, iwd, bluez; pe `main` și power-profiles-daemon,
   agent polkit, portals). Încearcă dnf / pacman / zypper / apt și raportează ce
   n-a găsit.
2. Copiază `/etc/greetd/*` și `/usr/local/bin/sway-session` (backup `*.orig`).
3. Wi-Fi prin iwd: dacă există NetworkManager îl trece pe backend-ul iwd,
   altfel iwd face singur DHCP. Activează bluetooth, greetd
   (înlocuiește gdm/sddm), power-profiles-daemon.

`home` rulează `home-manager switch` și apoi `non-nixos-gpu-setup` (cu sudo),
ca aplicațiile din Nix care folosesc GPU-ul (satty, swayosd) să găsească driverele.

### Pachete care pot lipsi din repo-urile distribuției

| Pachet | Fedora | Arch |
|---|---|---|
| `swayfx` | repo oficial | `extra` / AUR |
| `gtklock`, `gtklock-powerbar-module`, `gtklock-playerctl-module` | COPR | AUR (modulele) |
| `gtkgreet` | repo oficial | `greetd-gtkgreet` |
| `tuigreet` | repo oficial | `greetd-tuigreet` |
| `swaylock-effects` | COPR | AUR |

Fără `swaylock-effects`, pune `swaylockEffects = false;` în `home/second.nix`
(swaylock simplu nu cunoaște opțiunile de blur / ceas).

## Taste

| Tastă | Acțiune |
|---|---|
| `Super+Enter` | terminal |
| `Super+d` | launcher |
| `Super+x` | control center (`main`) / meniu power (`second`) |
| `Super+Shift+x` | meniu power |
| `Super+Shift+q` | închide fereastra |
| `Super+Shift+c` | reload |
| `Super+Escape` | lock |
| `Super+Shift+e` | logout (cu confirmare) |
| `Super+Space` | US ⇄ RO |
| `Super+h/j/k/l` | focus; cu `Shift` mută fereastra |
| `Super+1…0` | workspace (din nou pe același = înapoi la anteriorul) |
| `Super+b` / `Super+v` | split orizontal / vertical |
| `Super+s` / `Super+w` / `Super+e` | stacking / tabbed / toggle split |
| `Super+f` | fullscreen |
| `Super+Shift+Space` / `Super+Tab` | floating / focus tiling ⇄ floating |
| `Super+r` | mod resize (hjkl, Enter/Esc iese) |
| ``Super+` `` | terminal ascuns (scratchpad) |
| `Super+m` | playerul de muzică (workspace 10) |
| `Caps` / `Shift+Caps` | Escape / Caps Lock |
| `Print`, `Shift+Print`, `Ctrl+Print` | captură ecran / zonă / fereastră (`main`) |
| `Super+Print`, `Super+Shift+s` | captură zonă cu adnotare (satty, `main`) |

Volum, luminozitate și media merg și pe lock screen.

## Aliasuri

| Alias | Acțiune |
|---|---|
| `wifi` / `bt` / `audio` | impala / bluetui / wiremix |
| `sysmon` | btop |
| `track [proiect]` | pornește timerul (implicit: numele repo-ului git curent) |
| `untrack` / `retrack` | oprește / reia timerul |
| `off`, `reboot`, `sleep`, `logout`, `lock` | acțiuni de sesiune (`sleep 5` rămâne comanda obișnuită) |

## Time tracking

`timer` (peste timewarrior): proiectele sunt tag-uri. La lock timerul se oprește;
pe `main` apare o notificare cu „Reia” la deblocare, pe `second` se reia cu
`retrack`. Baza de date e în `~/Sync/timewarrior`; leagă folderul `~/Sync`
între laptopuri din syncthing (http://127.0.0.1:8384). Evită să ții timerul
pornit pe ambele laptopuri simultan (syncthing ar crea fișiere de conflict).

## Idle

| | `main` | `second` |
|---|---|---|
| estompare | 4:30 | — |
| lock | 5:00 | 5:00 |
| ecran stins | 5:30 | 5:30 |
| suspend | 15:00, doar pe baterie | — |

Lock înainte de suspend pe ambele.

## Per laptop

În `home/main.nix` / `home/second.nix`: `dotfiles.scale` (scalarea ecranului),
`dotfiles.laptopOutput` (implicit `eDP-1`), `dotfiles.gaps`. Pe `main`, profilurile
kanshi și orele pentru night light (`services.gammastep`) sunt tot acolo.

## Wallpaper

Pune o imagine în `wallpapers/wallpaper.png` și fă `git add` (flake-ul vede doar
fișierele urmărite de git). E folosită de sway, gtklock și gtkgreet; fără ea se
folosește culoarea de fundal din paletă.
