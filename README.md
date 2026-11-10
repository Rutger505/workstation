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

`install.sh` is safe to rerun. It asks for the optional groups (`install/optional/`) and remembers the choice in `~/.config/workstation/optional-packages.conf`.
