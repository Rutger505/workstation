# Plan

Prototype of a desktop without Omarchy, on Arch and Fedora from one branch. Delete steps once done.

## Wishes (what it must do, not how)

### Distro rule

- Arch leads. If Fedora blocks a feature (missing package, broken COPR), don't jump through hoops: build it for Arch, add a Fedora TODO under step 3.

### System

- Arch AUR helper: paru (not yay).
- Btrfs root with snapshots.
  - Automatic snapshot once a week.
  - Always keep at least one snapshot that is a week or older. Failed-update retries must never push it out (Omarchy's "retention of 5" problem: 3 retries = 3 snapshots, useful old ones gone).
- No boot/shutdown eye candy: no Plymouth, no quiet boot, no splash, no graphical login manager.
  - Raw kernel + systemd logs on boot and shutdown, so a service hanging on its stop deadline is visible.
  - Plain console prompt for the disk encryption passphrase.

### Hyprland

- Idle: dim screen to 10% at 4m30s, lock at 5m.
- Workspaces bound to monitors: monitor 1 gets workspace 1, monitor 2 gets 2, ...; the last configured monitor gets all the rest (e.g. 5-9 on a 4-monitor setup).
- Tiling for everything, including apps Omarchy floats (Bitwarden etc.). Floating only for real pop-ups/dialogs.
- No keybindings for theme switching, wallpaper cycling or other ricing; one fixed look.
- Left-hand app launching: every app/tool shortcut reachable with the left hand only, so the right hand stays on the mouse.
  - Super+Ctrl+W: WiFi (Omarchy moved it to Super+Ctrl+N).
  - Super+Ctrl+T: btop (Omarchy moved it to the theme picker).
- Keyboard-first apps where possible (e.g. spotatui instead of Spotify).
- Font: JetBrainsMono NL Nerd Font (no ligatures).

### Top bar

- Top bar like Omarchy.
- System tray showing all background apps (Discord etc.).
- Battery always visible: percentage, watts, time left. Time left in hours with one decimal (`3.4h`), in minutes below one hour (`45m`).
- Low memory use. Omarchy's quickshell sits around 350 MB; waybar + mako + hypr* tools are a fraction of that and cover the wishes above. Quickshell only if a wish needs it.

## 1. Test machines

- Proxmox VMs: minimal Arch (archinstall, no profile, btrfs + LUKS) and Fedora Everything minimal (btrfs + LUKS), with snapshots right after the base install so every `install.sh` run starts clean.
- Hyprland in a VM: virtio-gpu with virgl or GPU passthrough; check the session starts before building on it.

## 2. Desktop base (replaces what Omarchy provides)

- Arch: switch `install/distro/arch.sh` from yay to paru.
- Snapshots: snapper with separate limits for weekly timeline snapshots and update snapshots, so update retries only rotate among themselves.
- Boot: no `quiet`/`splash` kernel args, no Plymouth, plain LUKS prompt.
- Session: TTY login + uwsm starting Hyprland (no greeter), xdg-desktop-portal-hyprland, polkit agent.
- Hyprland base config: own `hyprland.lua` without Omarchy's bootstrap, defaults, toggles and paths modules. Monitor-bound workspaces, tile-by-default window rules, left-hand bindings.
- Bar, launcher, notifications: waybar (tray, battery module/script), walker or fuzzel, mako.
- Lock, idle, wallpaper: hyprlock, hypridle (dim 4m30s, lock 5m), hyprpaper.
- Screenshots and recording: grim, slurp, satty, gpu-screen-recorder.
- Audio, bluetooth, network: pipewire + wireplumber, bluez + bluetui, NetworkManager or iwd + impala.
- Theming: one fixed theme, JetBrainsMono NL Nerd Font, cursor, GTK/Qt dark mode. No theme switcher.
- Own scripts for the `omarchy-*` commands dev-env calls: lock, shutdown, launch-or-focus, webapp install, tzupdate, Tailscale service.

## 3. Fedora specifics

- Hyprland stack: `hyprland` is not in the Fedora 45 repos (checked 2026-11-10), so COPR (solopasha/hyprland or similar). Check each hypr* package.
- AUR packages from dev-env (zen-browser, spotatui, visual-studio-code, ...): Flatpak, vendor repo or install script.
- Kernel/hibernate, sudo-rs, kanata, ydotool: check each one.
- Snapshots: snapper works on Fedora; bootable snapshots would need grub-btrfs instead of the Arch setup.
- TODOs for features blocked on Fedora go here.

## 4. Port from dev-env

- Shell, tmux, nvim, git, ghostty, starship, lazygit, yazi configs: copy as-is, they barely depend on Omarchy.
- hypr bindings, input, looknfeel, host files, application rules: rewrite against our own base.
- Install scripts and optional groups: port one by one, split per distro where needed.
- Self-update timer (`workstation-update-self`) once a machine runs from a live checkout.

## 5. Decide

- Arch vs Fedora after using both for a while. Drop the loser's `.fedora`/`.arch` files and `install/distro/` entry, or keep both.
- Switch the desktop and laptop from dev-env once the prototype covers daily use.
