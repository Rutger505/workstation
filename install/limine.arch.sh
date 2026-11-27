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

# Laptop: resume from hibernate.sh's swapfile. /etc/default/limine is read after limine-entry-tool.d, so the args go here.
if [ -f /swap/swapfile ]; then
  resume="resume=UUID=$(findmnt -no UUID -T /swap/swapfile) resume_offset=$(sudo btrfs inspect-internal map-swapfile -r /swap/swapfile)"
  # suspend-then-hibernate needs an RTC wakeup from s2idle to hibernate on time
  if grep -q '\[s2idle\]' /sys/power/mem_sleep; then
    resume+=" rtc_cmos.use_acpi_alarm=1"
  fi
  sudo sed -i '/^KERNEL_CMDLINE\[default\]+=" resume=/d' /etc/default/limine
  echo "KERNEL_CMDLINE[default]+=\" $resume\"" | sudo tee -a /etc/default/limine >/dev/null
  # The systemd hook resumes by itself
  if [ "$hook" = btrfs-overlayfs ] && ! grep -Eq '^HOOKS=.*[( ]resume[ )]' /etc/mkinitcpio.conf; then
    sudo sed -i -E '/^HOOKS=/ s/([( ])filesystems([ )])/\1resume filesystems\2/' /etc/mkinitcpio.conf
  fi
fi

sudo limine-update

# Limine prefers a limine.conf next to its EFI binary (archinstall's) over the generated /boot/limine.conf
sudo rm -f /boot/EFI/BOOT/limine.conf

sudo systemctl enable limine-snapper-sync.service
