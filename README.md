
## Meniuri Fuzzel și capturi întârziate

- Toate meniurile Fuzzel folosesc un chenar de `1 px`, colțuri drepte și culorile accentului din `home/theme.nix`.
- Fuzzel are `exit-on-keyboard-focus-loss = no`, deci mișcarea mouse-ului peste sau în afara meniului nu îl închide. Se închide la `Esc`, după alegerea cu `Enter` sau prin click explicit.
- Cheatsheet-ul de la `Super+c` este un meniu Omarchy/Walker cu căutare, fără iconițe tematice, cu liste aliniate pe coloane și etichete `[sway]`, `[tmux]`, `[helix]`.
- Pentru o captură în care un meniu trebuie să fie vizibil, folosește:

```sh
screenshot delayed 3
# echivalent:
screenshot --delay 3 area
```

Sway oferă și `Super+Shift+d` pentru captură de zonă cu întârziere implicită de 3 secunde.
