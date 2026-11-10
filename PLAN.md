# Plan

Prototype of a desktop without Omarchy, on Arch and Fedora from one branch. Delete steps once done.

## 1. Test machines

- Proxmox VMs: minimal Arch (archinstall, no profile) and Fedora Everything minimal, with snapshots right after the base install so every `install.sh` run starts clean.
- Hyprland in a VM: virtio-gpu with virgl or GPU passthrough; check the session starts before building on it.

## 2. Desktop base (replaces what Omarchy provides)

- Session: uwsm + greetd (tuigreet) or a TTY autologin, hyprland, xdg-desktop-portal-hyprland, polkit agent.
- Hyprland base config: own `hyprland.lua` without Omarchy's bootstrap, defaults, toggles and paths modules.
- Bar, launcher, notifications: waybar, walker or fuzzel, mako or swaync.
- Lock, idle, wallpaper: hyprlock, hypridle, hyprpaper.
- Screenshots and recording: grim, slurp, satty, gpu-screen-recorder.
- Audio, bluetooth, network: pipewire + wireplumber, bluez + bluetui, NetworkManager or iwd + impala.
- Theming: one fixed theme, fonts, cursor, GTK/Qt dark mode. No theme switcher.
- Own scripts for the `omarchy-*` commands dev-env calls: lock, shutdown, launch-or-focus, webapp install, tzupdate, Tailscale service.

## 3. Fedora specifics

- Hyprland stack: Fedora repos vs COPR (solopasha/hyprland), pick per package.
- AUR packages from dev-env (zen-browser, spotatui, visual-studio-code, ...): Flatpak, vendor repo or install script.
- Kernel/hibernate, sudo-rs, kanata, ydotool: check each one.

## 4. Port from dev-env

- Shell, tmux, nvim, git, ghostty, starship, lazygit, yazi configs: copy as-is, they barely depend on Omarchy.
- hypr bindings, input, looknfeel, host files, application rules: rewrite against our own base.
- Install scripts and optional groups: port one by one, split per distro where needed.
- Self-update timer (`workstation-update-self`) once a machine runs from a live checkout.

## 5. Decide

- Arch vs Fedora after using both for a while. Drop the loser's `.fedora`/`.arch` files and `install/distro/` entry, or keep both.
- Switch the desktop and laptop from dev-env once the prototype covers daily use.
