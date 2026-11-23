# Plan

Prototype of a desktop without Omarchy, on Arch and Fedora from one branch. Delete steps once done.

## Wishes (what it must do, not how)

### Distro rule

- Arch leads. If Fedora blocks a feature (missing package, broken COPR), don't jump through hoops: build it for Arch, add a Fedora TODO under step 3.

### System

- Arch AUR helper: paru (not yay).
- Btrfs root with snapshots.
  - Automatic snapshot once a week; always keep at least one that is a week or older.
  - Snapshot around every package update, keep the last 5. Separate from the weekly ones: failed-update retries only rotate among themselves (Omarchy's "retention of 5" problem: 3 retries = 3 snapshots, useful old ones gone).
  - Boot any snapshot from the boot menu.
- No boot/shutdown eye candy: no Plymouth, no quiet boot, no splash, no graphical login manager.
  - Raw kernel + systemd logs on boot and shutdown, so a service hanging on its stop deadline is visible.
  - Keep systemd's default stop timeouts; seeing the hang is the point, not hiding it.
  - Plain console prompt for the disk encryption passphrase.
- Login: the disk passphrase is the only thing typed at boot. No second password on the TTY; Hyprland starts on its own.

### Hyprland

- Idle, laptop only: dim screen to 10% at 4m30s, at 5m lock + suspend (suspend-then-hibernate, same as dev-env incl. hibernate-unlock: the disk passphrase after a hibernate resume unlocks the session).
- Desktop: no idle actions at all, never dims, locks or suspends by itself (Sunshine, SSH). Locks only by hand.
- Laptop: a fullscreen app (video, game) keeps it from dimming/locking. Super+Ctrl+I toggles idle inhibit by hand.
- Lid close and suspend always lock first.
- Workspaces bound to monitors: monitor 1 gets workspace 1, monitor 2 gets 2, ...; the last configured monitor gets all the rest (e.g. 5-9 on a 4-monitor setup).
  - Laptop with only its own screen: it gets 1-9.
  - New monitor plugged in: a popup asks what to do (e.g. extend + move workspaces, mirror, external only, ignore); workspaces move per that choice. Asked only the first time per monitor; the choice is remembered and reapplied on reconnect. Super+Ctrl+D to change it.
- Tiling for everything, including apps Omarchy floats (Bitwarden etc.). Floating only for real pop-ups/dialogs. Never the scrolling layout.
- No keybindings for theme switching, wallpaper cycling or other ricing; one fixed look.
- Left-hand app launching: every app/tool shortcut reachable with the left hand only, so the right hand stays on the mouse. See Keybindings.
- Keyboard-first apps where possible (e.g. spotatui instead of Spotify).
- Font: JetBrainsMono NL Nerd Font (no ligatures).

### Top bar

- Top bar like Omarchy.
- Left: workspaces.
- Center: clock as `Wed 18 Nov 10:05` (weekday, date without year, no seconds).
- Right: now playing, system tray (all background apps: Discord etc.), Claude usage, Tailscale, network, bluetooth, CPU, RAM, battery.
- Battery always visible: percentage, watts, time left. Time left in hours with one decimal (`3.4h`), in minutes below one hour (`45m`). Hidden on machines without a battery.
- Battery while charging: time until full instead of time left (same format).
- Battery menu (Super+Ctrl+P, laptop only): charger watts, volts and amps (e.g. `65W 20V 3.25A`), not in the bar. Charger values are what USB-C PD negotiated; if the laptop doesn't expose them, fall back to what goes into the battery.
- Claude usage: Claude subscription limits (5h session + weekly %), replaces Omarchy's agent usage panel (Super+Ctrl+U).
- Low memory use: waybar + mako + hypr* tools instead of a quickshell shell (~350 MB in Omarchy).

### Rest

- App launcher: yes.
- Notifications: plain popups only. No history panel, no Do Not Disturb.
- Theme: fresh, see Theme.

### Keybindings

Scheme: Super = windows/workspaces, Super+Shift = apps, Super+Ctrl = system tools. Every app/tool bind uses left-hand keys (QWERT ASDFG ZXCVB, 1-5, Tab, Esc, Space). Navigation stays on hjkl.

Windows and workspaces (Super):
- Space: app launcher
- Return: terminal
- W: close window
- F: fullscreen
- T: toggle floating (escape hatch for the odd app that should float)
- H/J/K/L or arrows: focus; +Shift: move window
- 1-9: workspace; +Shift: move window there
- Tab / Shift+Tab: next / previous workspace on this monitor
- Escape: power menu (lock first, then suspend, reboot, shutdown; so Super+Esc, Enter locks)
- V: type clipboard (kept from dev-env)
- C: GSR save replay + share; Shift+C: GSR show/hide (kept from dev-env)
- F1: keybinding cheat sheet

Apps (Super+Shift):
- T: terminal (left-hand alias of Super+Return)
- B: browser (Zen)
- F: file manager (yazi)
- D: Discord
- S: spotatui (was Super+Shift+M, right hand)
- W: Bitwarden
- G: Steam
- Rare apps (Snapchat webapp, Firefox, ...) via launcher only.

System tools (Super+Ctrl):
- W: WiFi (impala)
- B: bluetooth (bluetui)
- A: audio (wiremix)
- T: btop
- D: displays (same popup as on monitor connect)
- I: toggle idle inhibit (laptop only; no dim/lock/suspend)
- P: battery menu (laptop only): charger W/V/A, time to full/left
- S: screenshot region (Print stays as alias)
- R: screen recording start/stop
- V: clipboard history
- E: emoji picker
- C: webcam photo, instant (no preview)

Other:
- Media keys: volume, brightness, play/pause/next
- Alt+F6: autoclicker (kept from dev-env)

### Theme

Placeholder: will be refined/replaced later, keep colors in one place so swapping is cheap.

"Granite": dark, low-contrast greys, one warm accent. Draft palette:
- Background `#15171c`, surface `#1e2128`, inactive border `#2a2e37`
- Text `#d4d7de`, muted `#7b8190`
- Accent (active border, focused workspace, selection) amber `#e5a54b`
- Red `#e06c6c`, green `#8fbf7f`, yellow `#d9c27a`, blue `#7aa2d6`, magenta `#b48ec7`, cyan `#78b8b0`
- Same palette everywhere: hyprland, waybar, mako, fuzzel, hyprlock, ghostty, btop, nvim, GTK/Qt dark.

## 1. Test machines

- Proxmox VMs: minimal Arch (archinstall, no profile, btrfs + LUKS, Limine, ESP ≥ 2 GB) and Fedora Everything minimal (btrfs + LUKS), with snapshots right after the base install so every `install.sh` run starts clean.
- Hyprland in a VM: works headless on software rendering (llvmpipe) with `test/vm` (QEMU/KVM, no GPU needed; checked 2026-11-21: Hyprland 0.57.2 starts, keys via QMP, screenshots). Good for install runs, configs, bar, binds, hyprlock; not for performance. virgl (Hyprland wiki "Running in a VM") only on a host with a GPU.
- `test/vm arch` uses the arch-boxes basic image (btrfs, GRUB, no LUKS): fine for `install.sh`, not for Limine/LUKS/boot snapshots. Those need a real archinstall VM.
- TODO: `test/vm fedora` (Fedora Cloud qcow2 + cloud-init seed for user/SSH key).

## 2. Desktop base (replaces what Omarchy provides)

- Arch: switch `install/distro/arch.sh` from yay to paru.
- Snapshots: snapper. Timeline config: weekly only, `TIMELINE_LIMIT_WEEKLY` keeps the week-old one. Update snapshots via snap-pac (Arch) / dnf plugin (Fedora) with `NUMBER_LIMIT=5`.
- Boot: no `quiet`/`splash` kernel args, no Plymouth, plain LUKS prompt, default stop timeouts.
- Bootable snapshots: Limine + limine-snapper-sync (AUR), text menu only (Rutger OK'd over systemd-boot).
  - Why not systemd-boot: it only reads the FAT ESP, kernels live there and aren't in the btrfs snapshot. A plain `rootflags=subvol=<snapshot>` entry boots the current kernel against the snapshot's old `/usr/lib/modules` → missing modules after any kernel update. Needs a kernel + initramfs copy per snapshot on the ESP; limine-snapper-sync does exactly that, nothing maintained does it for systemd-boot.
  - ESP size: ≥ 2 GB for the per-snapshot kernel copies.
- Session: getty autologin on tty1 + uwsm starting Hyprland (no greeter), xdg-desktop-portal-hyprland, polkit agent.
  - Pitfall: with plain autologin a Hyprland crash while locked respawns an unlocked session. Autologin only once per boot (flag in /run); after that tty1 asks for the password.
- Hyprland base config: own `hyprland.lua` without Omarchy's bootstrap, defaults, toggles and paths modules. Monitor-bound workspaces, tile-by-default window rules, keybindings above.
- Monitor popup: script on Hyprland's `monitoradded` event (socket2) shows a fuzzel menu, applies monitor + workspace rules, moves workspaces.
- Bar: waybar. Custom modules: battery (watts + time-left/time-to-full format), battery menu on Super+Ctrl+P (charger W/V/A from `/sys/class/power_supply/ucsi-source-psy-*` or `/sys/class/typec`, fallback battery `voltage_now`/`current_now`; check what the laptop exposes), Claude usage (poll every few minutes), Tailscale (status only, no click action). mpris for now playing.
- Launcher and menus: fuzzel (also power menu, monitor popup, emoji, clipboard via cliphist). Lighter than walker, no background service.
- Notifications: mako, popups only.
- Lock, idle, wallpaper: hyprlock, hypridle on laptop only (dim 4m30s; 5m lock + suspend; lock before sleep), logind lid switch → suspend, hyprpaper.
  - Per-host: laptop suspend-then-hibernate (port dev-env's sleep.conf + hibernate-unlock, rewritten for hyprlock: its `omarchy-shell lock isLocked` and `/etc/pam.d/omarchy-lock-password` don't exist here). Desktop: no hypridle listeners at all (manual lock only).
  - Idle inhibit: Hyprland `idleinhibit fullscreen` window rule + Super+Ctrl+I toggle with a bar indicator.
- Monitor popup memory: choices stored per monitor (make/model/serial from `hyprctl monitors`), reapplied silently on reconnect.
- Screenshots and recording: grim, slurp, satty, gpu-screen-recorder.
- Webcam photo (Super+Ctrl+C): ffmpeg grabs one frame from v4l2 (skip first ~10 frames so auto-exposure settles, ~0.5-1s), saves to ~/Pictures/Webcam/<timestamp>.jpg, copies it to the clipboard (wl-copy) and opens it in imv. No shutter sound or flash. Desktop: only if a webcam is connected, else notify "no camera". Test in VM with a fake v4l2loopback device.
- Audio, bluetooth, network: pipewire + wireplumber + wiremix, bluez + bluetui, NetworkManager or iwd + impala.
- Theming: Granite palette, JetBrainsMono NL Nerd Font, cursor, GTK/Qt dark mode. No theme switcher.
- Own scripts for the `omarchy-*` commands dev-env calls: lock, shutdown, launch-or-focus, webapp install, tzupdate, Tailscale service.

## 3. Fedora specifics

- Hyprland stack: `hyprland` is not in the Fedora 45 repos (checked 2026-11-10), so COPR (solopasha/hyprland or similar). Check each hypr* package.
- AUR packages from dev-env (zen-browser, spotatui, visual-studio-code, ...): Flatpak, vendor repo or install script.
- Kernel/hibernate, sudo-rs, kanata, ydotool: check each one.
- Snapshots: snapper works on Fedora; update snapshots via the dnf snapper plugin.
- TODO: bootable snapshots. limine-snapper-sync isn't packaged for Fedora; Fedora's default is GRUB, so grub-btrfs is the likely route.
- TODOs for features blocked on Fedora go here.

## 4. Port from dev-env

- Shell, tmux, nvim, git, ghostty, starship, lazygit, yazi configs: copy as-is, they barely depend on Omarchy (recolor to Granite).
- hypr bindings, input, looknfeel, host files, application rules: rewrite against our own base.
- Install scripts and optional groups: port one by one, split per distro where needed.
- Self-update timer (`workstation-update-self`) once a machine runs from a live checkout.

## 5. Decide

- Arch vs Fedora after using both for a while. Drop the loser's `.fedora`/`.arch` files and `install/distro/` entry, or keep both.
- Switch the desktop and laptop from dev-env once the prototype covers daily use.
