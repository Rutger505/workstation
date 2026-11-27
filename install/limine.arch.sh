#!/bin/bash
set -euo pipefail

# limine-entry-tool reads /proc/cmdline when unset, which is wrong when booted into a snapshot
if ! grep -q '^KERNEL_CMDLINE' /etc/default/limine 2>/dev/null; then
  read -ra args </proc/cmdline
  cmdline=()
  for arg in "${args[@]}"; do
    case $arg in
      quiet | splash) ;;
      *) cmdline+=("$arg") ;;
    esac
  done
  echo "KERNEL_CMDLINE[default]=${cmdline[*]}" | sudo tee -a /etc/default/limine >/dev/null
fi

# Snapshots are read-only; this hook boots them with a writable overlay
hook=btrfs-overlayfs
if grep -Eq '^HOOKS=.*[( ]systemd[ )]' /etc/mkinitcpio.conf; then
  hook=sd-btrfs-overlayfs
fi
if ! grep -Eq "^HOOKS=.*[( ]${hook}[ )]" /etc/mkinitcpio.conf; then
  sudo sed -i -E "/^HOOKS=/ s/([( ])filesystems([ )])/\1filesystems $hook\2/" /etc/mkinitcpio.conf
fi

sudo limine-update

# Limine prefers a limine.conf next to its EFI binary (archinstall's) over the generated /boot/limine.conf
sudo rm -f /boot/EFI/BOOT/limine.conf

sudo systemctl enable limine-snapper-sync.service
