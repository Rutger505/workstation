# workstation

My own desktop environment: Hyprland, packages, dotfiles linked with GNU Stow, and a few scripts. Successor to [dev-env](https://github.com/Rutger505/dev-env) without Omarchy: every piece of the desktop is configured here. Runs on Arch and Fedora from the same branch.

Prototype. Status and next steps: [PLAN.md](PLAN.md).

## Install

Start from a minimal Arch (archinstall, no desktop profile) or Fedora Everything (minimal install) system with a user that has sudo.

```bash
ssh-keygen -t ed25519 && cat ~/.ssh/id_ed25519.pub   # add at https://github.com/settings/ssh/new
git clone git@github.com:Rutger505/workstation.git ~/.local/share/workstation
~/.local/share/workstation/install.sh                 # then reboot
```

`install.sh` is safe to rerun. It asks for the optional groups (`install/optional/`) and remembers the choice in `~/.config/workstation/optional-packages.conf` (without a terminal it keeps that choice).

## Testing

`test/vm` runs a headless QEMU/KVM test VM (UEFI via OVMF); Hyprland renders in software (llvmpipe), so no GPU is needed.
Distros: `arch` (btrfs + Limine, like the desktop) and `arch-luks` (same with LUKS root, like the laptop). Host needs qemu, edk2-ovmf, socat, sshpass, jq.

```bash
test/vm arch install            # archinstall from the latest ISO (test/archinstall/), snapshot "base"
test/vm arch up                 # SSH on 127.0.0.1:2222 (arch-luks: 2223, passphrase typed for you)
test/vm arch ssh                # user arch, password arch
test/vm arch sync               # working tree to the guest, then: test/vm arch ssh '~/.local/share/workstation/install.sh'
test/vm arch key meta_l-q       # press keys (QEMU key names)
test/vm arch shot /tmp/s.png    # screenshot
test/vm arch down               # then: save/restore <name>, reset (= restore base)
```
