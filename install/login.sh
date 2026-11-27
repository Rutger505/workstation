#!/bin/bash
set -euo pipefail

if [ "$(getent passwd "$USER" | cut -d: -f7)" != /usr/bin/zsh ]; then
  sudo chsh -s /usr/bin/zsh "$USER"
fi

# Autologin only once per boot: after a logout or a Hyprland crash tty1 asks for the password
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d
sudo tee /etc/systemd/system/getty@tty1.service.d/autologin.conf >/dev/null <<CONF
[Service]
ExecStart=
ExecStart=-/bin/sh -c 'mkdir /run/workstation-autologin 2>/dev/null && exec agetty --autologin $USER --noreset --noclear - "\$\$TERM"; exec agetty --noreset --noclear - "\$\$TERM"'
CONF

systemctl --user enable hyprpolkitagent.service
