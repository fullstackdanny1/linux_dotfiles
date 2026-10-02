# CSS comun pentru lock screen (gtklock) și login (gtkgreet): arată identic.
{
  theme,
  wallpaper ? null, # cale absolută către imagine sau null pentru culoare solidă
}:
let
  c = theme.scheme;
  r = toString theme.radius;
  background =
    if wallpaper == null then
      "background: #${theme.bg};"
    else
      ''
        background: #${theme.bg} url("file://${wallpaper}") no-repeat center;
          background-size: cover;'';
in
''
  * {
    font-family: "${theme.font.name}";
    color: #${theme.fg};
  }

  window {
    ${background}
  }

  /* gtkgreet: caseta centrală; gtklock: zona de deblocare */
  #body,
  #window-box {
    background-color: alpha(#${theme.bg}, 0.85);
    border: 2px solid #${theme.accent};
    border-radius: ${r}px;
    padding: 32px 40px;
  }

  #clock-label {
    font-size: 48px;
    font-weight: bold;
    color: #${theme.fg};
  }

  entry {
    background: #${c.base01};
    color: #${theme.fg};
    border: 1px solid #${c.base02};
    border-radius: ${r}px;
    padding: 6px 10px;
    box-shadow: none;
  }

  entry:focus {
    border-color: #${theme.accent};
  }

  button {
    background: #${c.base01};
    color: #${theme.fg};
    border: none;
    border-radius: ${r}px;
    padding: 6px 12px;
    box-shadow: none;
    text-shadow: none;
  }

  button:hover,
  button:focus {
    background: #${theme.accent};
    color: #${theme.bg};
  }

  button:hover label,
  button:focus label {
    color: #${theme.bg};
  }

  #error-label,
  #warning-label {
    color: #${c.base08};
  }

  /* gtklock-powerbar-module / gtklock-playerctl-module */
  #powerbar-box,
  #playerctl-box {
    background-color: alpha(#${theme.bg}, 0.85);
    border-radius: ${r}px;
    padding: 8px;
    margin: 16px;
  }

  #album-art {
    border-radius: ${r}px;
  }
''
