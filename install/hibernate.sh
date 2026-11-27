#!/bin/bash
set -euo pipefail

# Laptop only: lid and idle suspend-then-hibernate, which needs swap the size of RAM. limine.arch.sh adds the resume args.
[ "$(../bin/workstation-machine)" = laptop ] || exit 0

sudo mkdir -p /etc/systemd/logind.conf.d /etc/systemd/sleep.conf.d
printf '[Login]\nHandleLidSwitch=suspend-then-hibernate\n' | sudo tee /etc/systemd/logind.conf.d/lid.conf >/dev/null
printf '[Sleep]\nHibernateDelaySec=30min\nHibernateOnACPower=no\n' | sudo tee /etc/systemd/sleep.conf.d/hibernate.conf >/dev/null

# Its own subvolume keeps the swapfile out of root snapshots
if ! sudo btrfs subvolume show /swap >/dev/null 2>&1; then
  sudo btrfs subvolume create /swap
fi
if [ ! -f /swap/swapfile ]; then
  ram_gib=$((($(awk '/MemTotal/ {print $2}' /proc/meminfo) + 1048575) / 1048576))
  sudo btrfs filesystem mkswapfile --size "${ram_gib}g" /swap/swapfile
fi
if ! grep -q '^/swap/swapfile ' /etc/fstab; then
  echo '/swap/swapfile none swap defaults 0 0' | sudo tee -a /etc/fstab >/dev/null
fi
