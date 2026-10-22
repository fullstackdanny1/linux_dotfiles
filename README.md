# n4r77 setup v2.0

Un singur config Sway, declarat cu Nix + home-manager: sway simplu,
swaylock-effects, două variante de bară (Waybar sau swaybar, alese la
instalare) și un workflow de programare cu Helix + tmux. Tema vine dintr-o
singură sursă (Stylix + `home/theme.nix`, Gruvbox dark hard).

## Structură

```
flake.nix         homeConfigurations.n4r77-{waybar,swaybar} + packages.system-files
install.sh        pachete de sistem, Nix, surse de compilat, /etc, servicii, configurile din Nix
home/
  theme.nix       paleta, accent, font, rază, cursor, wallpaper
  common.nix      pachete, bash + prompt, aliasuri, helix, foot, fuzzel, mpd, syncthing, Stylix
  sway.nix        sway, swaylock-effects, idle, mako, swayosd, capturi, gammastep, kanshi
  waybar.nix      bara Waybar (module clickabile)       — `--bar waybar`
  swaybar.nix     swaybar + i3status (needitabilă)      — `--bar swaybar`
  dev.nix         tmux, `ts`, setările Helix pentru workflow
  icons.nix       glife Nerd Font
  scripts/*.sh    scripturi (writeShellApplication, verificate cu shellcheck)
system/
  default.nix     /etc/greetd/config.toml (tuigreet) și /usr/local/bin/sway-session
  sway-session    pornește sway cu profilul Nix în PATH
wallpapers/       wallpaper.png
```

## Instalare

```sh
git clone <repo> ~/linux_dotfiles && cd ~/linux_dotfiles
# userul e setat în flake.nix (user.name / user.home)
./install.sh                                   # întreabă distribuția și bara
./install.sh --distro fedora --bar waybar      # sau direct
```

Opțiuni: `--distro fedora|debian|arch`, `--bar waybar|swaybar`,
`--only system` (fără configurile din Nix) sau `--only home` (doar configurile din Nix).

Ce face, în ordine:

1. **Pachete din sistem**, doar cele care lipsesc: git, curl, xz, sway, greetd,
   pipewire, wireplumber, iwd, bluez, power-profiles-daemon, lxqt-policykit,
   portals (wlr, gtk), podman, distrobox. Pe Arch instalează `swayfx` în locul
   lui `sway` (cu `sway` ca rezervă).
2. **Nix**, dacă lipsește (installer-ul oficial, multi-user).
3. **Ce nu există în managerul de pachete** e clonat în `~/src`, fără să fie
   compilat. La final scriptul afișează ce a clonat și comanda de build:

   | | Fedora | Debian | Arch |
   |---|---|---|---|
   | swaylock-effects | GitHub | GitHub | AUR |
   | swayfx (+ scenefx) | GitHub | GitHub | pachet (altfel AUR) |
   | tuigreet | pachet (altfel GitHub) | pachet (altfel GitHub) | `greetd-tuigreet` |

   Până compilezi swaylock-effects, lock screen-ul nu merge (configul folosește
   blur și ceas, pe care swaylock simplu nu le înțelege). Configul sway merge și
   cu swayfx, deci după ce îl instalezi nu trebuie schimbat nimic.
4. **Fișiere de sistem și servicii**: `/etc/greetd/config.toml`,
   `/usr/local/bin/sway-session` (backup `*.orig`), iwd (ca backend pentru
   NetworkManager, dacă există), bluetooth, power-profiles-daemon, greetd ca
   display manager.
5. **Configurile din Nix**: `home-manager switch --flake .#n4r77-<bară>` și
   driverele GPU pentru aplicațiile din Nix (`non-nixos-gpu-setup`).

După modificări în config: `./install.sh --only home --bar waybar`.

## Aspect

- Ferestre: bordura activă gri deschis (`#a89984`), cele inactive gri închis
  (`#504945`); latura unde se deschide următoarea fereastră (direcția split-ului)
  e un gri și mai deschis (`#d5c4a1`).
- Spațiere: 8 între ferestre, 7 față de marginea ecranului, și cu o singură fereastră.
- Waybar: bară plutitoare cu colțuri rotunjite; swaybar: transparentă, iconițe
  colorate separate de `│`. Workspace-ul activ: cifra colorată (cu linie sub ea
  în Waybar); în Waybar, 1–3 apar mereu.

## Taste

| Tastă | Acțiune |
|---|---|
| `Super+Enter` | terminal |
| `Super+p` | proiect: sesiune tmux cu Helix (vezi „Workflow de programare”) |
| `Super+d` | launcher |
| `Super+x` | control center (Wi-Fi, bluetooth, audio, energie, night light, nu deranja, timer) |
| `Super+Shift+x` | meniu power |
| `Super+Shift+q` | închide fereastra |
| `Super+Shift+c` | reload |
| `Super+Escape` | lock |
| `Super+Shift+e` | logout (cu confirmare) |
| `Super+Space` | US ⇄ RO |
| `Super+h/j/k/l` | focus; cu `Shift` mută fereastra |
| `Super+1…0` | workspace (apăsat din nou sau ținut apăsat rămâne pe el) |
| `Super+b` / `Super+v` | split orizontal / vertical |
| `Super+s` / `Super+w` / `Super+e` | stacking / tabbed / toggle split |
| `Super+f` | fullscreen |
| `Super+Shift+Space` / `Super+Tab` | floating / focus tiling ⇄ floating |
| `Super+r` | mod resize (hjkl, Enter/Esc iese) |
| ``Super+` `` | terminal ascuns (scratchpad) |
| `Super+m` | playerul de muzică (workspace 10) |
| `Caps` / `Shift+Caps` | Escape / Caps Lock |
| `Print`, `Shift+Print`, `Ctrl+Print` | captură ecran / zonă / fereastră |
| `Super+Print`, `Super+Shift+s` | captură zonă cu adnotare (satty) |

Volum, luminozitate și media merg și pe lock screen.

## Aliasuri

| Alias | Acțiune |
|---|---|
| `wifi` / `bt` / `audio` | impala / bluetui / wiremix |
| `sysmon` | btop |
| `ts [dir]` | sesiunea tmux a unui proiect (fără argument: alegi din fzf) |
| `track [proiect]` | pornește timerul (implicit: numele repo-ului git curent) |
| `untrack` / `retrack` | oprește / reia timerul |
| `off`, `reboot`, `sleep`, `logout`, `lock` | acțiuni de sesiune (`sleep 5` rămâne comanda obișnuită) |

## Prompt

Starship, pe două rânduri, cu săgeată îndoită; `❯` devine roșu după o comandă eșuată:

```
╭─  user 󰌢 laptop  󰉋 ~/linux_dotfiles   main 󰔛 3s
╰─❯
```

Se configurează în `programs.starship` din `home/common.nix`.

## Workflow de programare: Helix + tmux

O sesiune tmux per proiect, în stilul „tmux-sessionizer”:

| Fereastră | Nume | Rulează | Unde |
|---|---|---|---|
| 1 | `code` | `hx .` | host |
| 2 | `term` | shell | container (`distrobox enter dev`) |

Orice fereastră nouă (`Ctrl-a c`) intră automat în container. Sesiunea
supraviețuiește închiderii terminalului: `Super+p` pe același proiect o
redeschide exact cum ai lăsat-o.

Proiectele sunt subdirectoarele din `~/code`; containerul se numește `dev`.
Se schimbă în `home/dev.nix` (`dotfiles.dev.projectsDir`, `dotfiles.dev.container`).

### Pregătire (o singură dată)

```sh
mkdir -p ~/code
distrobox create -n dev -i <imagine>     # ex. registry.fedoraproject.org/fedora-toolbox
distrobox enter dev                       # instalează toolchain-ul și LSP-urile
distrobox-export --bin /usr/bin/rust-analyzer   # din container, pentru fiecare LSP
hx --health rust                          # verificare, de pe host
```

Helix rulează pe host, deci LSP-urile trebuie să fie accesibile de pe host:
exportate din container cu `distrobox-export --bin …` (recomandat) sau instalate
și pe host. distrobox montează `$HOME`, deci proiectul are aceeași cale în ambele.

### Taste tmux

| Tastă | Acțiune |
|---|---|
| `Super+p` | alegi proiectul din fzf; se deschide Helix pe tot ecranul |
| `Ctrl-a Tab` | comuți între `code` și `term` |
| `Ctrl-a 1` / `Ctrl-a 2` | direct la fereastra 1 / 2 |
| `Ctrl-a c` | fereastră nouă (în container) |
| `Ctrl-a f` | alt proiect, fără să ieși din tmux (popup cu fzf) |
| `Ctrl-a s` | lista sesiunilor |
| `Ctrl-a d` | detach (sesiunea rămâne vie) |
| `Ctrl-a "` / `Ctrl-a %` | split sus-jos / stânga-dreapta, în directorul curent |
| `Ctrl-a r` | reîncarcă configul tmux |
| `Ctrl-a Ctrl-a` | trimite `Ctrl-a` aplicației |

### Taste Helix

| Tastă | Acțiune |
|---|---|
| `gn` / `gp` | tabul (bufferul) următor / anterior |
| `Space b` | lista de buffere |
| `Space f` | file picker |
| `:bc` | închide bufferul curent |
| `Ctrl-w v` | split vertical |
| `Space R` | reîncarcă toate fișierele (după ce agentul AI le-a modificat) |

`lazygit` e instalat, pentru commit-uri din fereastra `term` sau dintr-una separată.

### Aspect tmux

Bara de status jos, fără fundal propriu: numele sesiunii pe accentul verde,
ferestrele ca `1 code  2 term` (cea activă cu text deschis, restul estompate),
în dreapta `prefix` (cât e apăsat `Ctrl-a`) și hostname-ul. Bordurile
panourilor folosesc aceleași griuri ca ferestrele din sway; popup-ul are colțuri
rotunjite.

## Time tracking

`timer` (peste timewarrior): proiectele sunt tag-uri. La lock timerul se
oprește; la deblocare apare o notificare cu „Reia” (sau `retrack` din terminal).
Baza de date e în `~/Sync/timewarrior`; leagă folderul `~/Sync` între laptopuri
din syncthing (http://127.0.0.1:8384). Evită să ții timerul pornit pe două
laptopuri simultan (syncthing ar crea fișiere de conflict).

## Idle

| Timp | Acțiune |
|---|---|
| 4:30 | ecranul se estompează |
| 5:00 | lock |
| 5:30 | ecranul se stinge |
| 15:00 | suspend, doar pe baterie |

Lock înainte de suspend.

## Per laptop

În `home/sway.nix`: `dotfiles.scale` (scalarea ecranului), `dotfiles.laptopOutput`
(implicit `eDP-1`), `dotfiles.gaps.inner` / `dotfiles.gaps.outer`, profilurile
kanshi și orele pentru night light (`services.gammastep`).

## Wallpaper

`wallpapers/wallpaper.png` (urmărit de git: flake-ul vede doar fișierele din
git). E folosit de sway și de swaylock (cu blur); fără el se folosește culoarea
de fundal din paletă.
