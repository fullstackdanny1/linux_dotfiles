# Pornește agentul polkit instalat din sistem (căile diferă între distribuții).
for agent in \
  lxqt-policykit-agent \
  /usr/libexec/lxqt-policykit-agent \
  /usr/libexec/polkit-gnome-authentication-agent-1 \
  /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 \
  /usr/libexec/polkit-gnome/polkit-gnome-authentication-agent-1; do
  if command -v "$agent" >/dev/null; then exec "$agent"; fi
done
echo "polkit-agent: niciun agent polkit găsit (instalează lxqt-policykit sau polkit-gnome)" >&2
exit 1
