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
- Disk encryption: chosen per machine at install. Desktop: none. Laptop: probably none. Everything must work with and without LUKS.
  - With LUKS: plain console passphrase prompt, the only thing typed at boot.
  - Without LUKS: nothing typed at boot, autologin straight into Hyprland (OK for the desktop at home).
- Login: no password on the TTY at boot; Hyprland starts on its own.

### Hyprland

- Idle, laptop only: dim screen to 10% at 4m30s, at 5m lock + suspend (suspend-then-hibernate, same as dev-env). Without LUKS: after a hibernate resume just type the password in hyprlock (no hibernate-unlock).
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

## Build order (2026-11-27)

Each part tested in `test/vm`, committed + pushed on its own.

1. Done (2026-11-27): `test/vm <distro> install` boots the latest ISO under OVMF, archinstall 4.5 with `test/archinstall/` (btrfs @/@home/@log/@pkg zstd, Limine, ESP 2 GiB at /boot, user arch, systemd-networkd from the ISO), snapshot `base`. Variants `arch` (no LUKS, like the desktop) and `arch-luks` (encrypt hook, passphrase typed over QMP).
2. Done (2026-11-27): paru, snapper (weekly timeline + last 5 updates via snap-pac), limine-snapper-sync + limine-mkinitcpio-hook (cmdline in `/etc/default/limine`, no quiet/splash), zsh + `.zprofile` → uwsm → Hyprland, tty1 autologin once per boot. Tested in `arch`: snapshot boot from the menu, logout → password prompt. VM snapshot `system`. Not tested: `arch-luks`.
3. Done (2026-11-27): own `.config/hypr/` (dwindle, binds as above, no float rules, `idle_inhibit = "fullscreen"` on all windows), uwsm env (`bin/` on PATH), ghostty + fuzzel, launch-or-focus, host files, monitor-bound workspaces + monitor popup. Tested in `arch` with headless outputs (`hyprctl output create headless`). VM snapshot `hyprland`.
4. Bar: waybar with all modules.
5. Lock, idle, power: hyprlock, hypridle (laptop), power menu, idle inhibit. Lid/hibernate only partly testable.
6. Menus and tools: fuzzel, mako, cliphist, emoji, screenshots, recording, webcam (fake camera), battery menu (fake QEMU battery), WiFi/BT/audio TUIs, own scripts replacing `omarchy-*`.
7. Theme: Granite placeholder + JetBrainsMono NL, colors in one place.
8. Fedora on paper: Fedora name or TODO for every package of 2-7. No Fedora test VM (Rutger: only has to be theoretically correct).

Not in the VM, Rutger on hardware: battery/charger, lid, hibernate, real webcam, real monitors, GPU performance.

## 1. Test machines

- Hyprland in a VM: works headless on software rendering (llvmpipe) with `test/vm` (QEMU/KVM, no GPU needed; checked 2026-11-21: Hyprland 0.57.2 starts, keys via QMP, screenshots). Good for install runs, configs, bar, binds, hyprlock; not for performance. virgl (Hyprland wiki "Running in a VM") only on a host with a GPU.
- `test/vm arch`/`arch-luks`: real archinstall (UEFI, Limine, btrfs), so boot and snapshot work is testable. `arch-luks` adds `console=ttyS0 console=tty0 loglevel=7` (VM only) so `up` can see the LUKS prompt coming on serial.
- No Fedora test VM: Fedora only has to be theoretically correct (package names via `docker run --rm fedora dnf info`).

## 2. Desktop base (replaces what Omarchy provides)

- Done (part 2): paru; snapper (`install/snapper.sh`: weekly timer drop-in in `system/`, `TIMELINE_LIMIT_WEEKLY=3`, `NUMBER_LIMIT=10` = 5 updates since pre and post count separately); bootable snapshots (`install/limine.arch.sh`); no quiet/splash, no Plymouth, default stop timeouts; session (`install/login.sh`, `.zprofile`).
- Bootable snapshots: Limine + limine-snapper-sync, text menu only (Rutger OK'd over systemd-boot).
  - Why not systemd-boot: it only reads the FAT ESP, kernels live there and aren't in the btrfs snapshot. A plain `rootflags=subvol=<snapshot>` entry boots the current kernel against the snapshot's old `/usr/lib/modules` → missing modules after any kernel update. Needs a kernel + initramfs copy per snapshot on the ESP; limine-snapper-sync does exactly that, nothing maintained does it for systemd-boot.
  - ESP size: ≥ 2 GB for the per-snapshot kernel copies.
- Session pitfall: with plain autologin a Hyprland crash while locked respawns an unlocked session, hence autologin once per boot (`/run/workstation-autologin`).
- Fonts: none installed yet; ghostty embeds its own, fuzzel gets Adwaita Sans via a dependency. JetBrainsMono NL comes with the theme (`ttf-jetbrains-mono-nerd` is 232 MB installed, mind the VM disk).
- Done (part 3): `.config/hypr/` (`colors.lua` = the look's only colors, swap in the theme), `.config/uwsm/env`, `bin/workstation-launch-or-focus [--tui] CLASS CMD` (TUIs in ghostty with class `org.workstation.<name>`).
- Monitors (`.config/hypr/monitors.lua`): Hyprland's Lua `monitor.added`/`removed` events instead of a socket2 daemon. Unknown monitor (not in the host file, another one already on) → `workstation-monitors ask <output>` (fuzzel: extend right/left/above, mirror, only this monitor, disable); Super+Ctrl+D = `workstation-monitors` (pick a monitor first). Order: host file order, then left to right; never disables every screen.
- Host files: `.config/hypr/hosts/<hostname>.lua` call `require("monitors").set({...})` with the monitors in order. Names `rutger-desktop` / `rutger-laptop` (dev-env: `rutger-*-omarchy`): set that hostname at install. TODO: real modes/positions/scales from dev-env's untracked `monitors.lua` on each machine; desktop order assumed DP-1, DP-2, HDMI-A-1 (left to right).
- Machine type: `workstation-machine` prints `laptop` (a power supply of type Battery without scope Device) or `desktop`. Idle and bar use it; a fake QEMU battery makes the VM a laptop.
- Bound to scripts later parts must provide (exact names): `workstation-power-menu` (Super+Esc), `workstation-cheatsheet` (Super+F1, binds carry descriptions: `hyprctl binds`), `workstation-idle-toggle` (Super+Ctrl+I), `workstation-battery-menu` (Super+Ctrl+P), `workstation-screenshot` (Super+Ctrl+S, Print), `workstation-record` (Super+Ctrl+R), `workstation-clipboard` (Super+Ctrl+V), `workstation-emoji` (Super+Ctrl+E), `workstation-webcam` (Super+Ctrl+C). Packages still missing for binds: zen-browser, yazi, discord, spotatui, bitwarden (`bitwarden-desktop`), steam, impala, bluetui, wiremix, ydotool (Super+V), gpu-screen-recorder-ui + gsr-clip-share (Super+C), useful-autoclicker (Alt+F6).
- Bar: waybar. Custom modules: battery (watts + time-left/time-to-full format), battery menu on Super+Ctrl+P (charger W/V/A from `/sys/class/power_supply/ucsi-source-psy-*` or `/sys/class/typec`, fallback battery `voltage_now`/`current_now`; check what the laptop exposes), Claude usage (poll every few minutes), Tailscale (status only, no click action). mpris for now playing.
- Launcher and menus: fuzzel (also power menu, monitor popup, emoji, clipboard via cliphist). Lighter than walker, no background service.
- Notifications: mako, popups only.
- Lock, idle, wallpaper: hyprlock, hypridle on laptop only (dim 4m30s; 5m lock + suspend; lock before sleep), logind lid switch → suspend, hyprpaper.
  - Per-host: laptop suspend-then-hibernate (port dev-env's sleep.conf). hibernate-unlock only matters with LUKS; if ever needed, rewrite for hyprlock (its `omarchy-shell lock isLocked` and `/etc/pam.d/omarchy-lock-password` don't exist here). Desktop: no hypridle listeners at all (manual lock only).
  - Idle inhibit: Hyprland `idleinhibit fullscreen` window rule + Super+Ctrl+I toggle with a bar indicator.
- Monitor popup memory: `~/.local/state/workstation/monitors`, one `<choice> <description>` line per monitor (description = make model serial; outputs without one, like headless, by name), reapplied silently on reconnect.
- Screenshots and recording: grim, slurp, satty, gpu-screen-recorder.
- Webcam photo (Super+Ctrl+C): ffmpeg grabs one frame from v4l2 (skip first ~10 frames so auto-exposure settles, ~0.5-1s), saves to ~/Pictures/Webcam/<timestamp>.jpg, copies it to the clipboard (wl-copy) and opens it in imv. No shutter sound or flash. Desktop: only if a webcam is connected, else notify "no camera". Test in VM with a fake v4l2loopback device.
- Audio, bluetooth, network: pipewire + wireplumber + wiremix, bluez + bluetui, NetworkManager or iwd + impala.
- Theming: Granite palette, JetBrainsMono NL Nerd Font, cursor, GTK/Qt dark mode. No theme switcher.
- Own scripts for the `omarchy-*` commands dev-env calls: lock, shutdown, webapp install, tzupdate, Tailscale service.

## 3. Fedora specifics

- Hyprland stack: `hyprland` is not in the Fedora 45 repos (checked 2026-11-10), so COPR (solopasha/hyprland or similar). Check each hypr* package.
- AUR packages from dev-env (zen-browser, spotatui, visual-studio-code, ...): Flatpak, vendor repo or install script.
- Kernel/hibernate, sudo-rs, kanata, ydotool: check each one.
- Hyprland stack not in Fedora (checked 2026-11-27): hyprland, uwsm, xdg-desktop-portal-hyprland, hyprpolkitagent need a COPR (solopasha/hyprland or similar); now in `packages.arch.lst`.
- Snapshots: `snapper` (same name, in `packages.lst`) + `python3-dnf-plugin-snapper` instead of snap-pac; `install/snapper.sh` is shared. Check that the plugin's snapshots use cleanup "number".
- TODO: bootable snapshots. limine-snapper-sync isn't packaged for Fedora; Fedora's default is GRUB, so grub-btrfs is the likely route. Its kernel cmdline: no `rhgb quiet` (Fedora's default) via grubby.
- `install/login.sh` should work as is (agetty via PATH, zsh at /usr/bin/zsh).
- Part 3 packages: same names in `packages.lst` (fuzzel, wl-clipboard, brightnessctl, playerctl, pipewire, wireplumber, btop, jq); ghostty from COPR `scottames/ghostty` (in `fedora.sh`), `pipewire-pulseaudio` instead of `pipewire-pulse`.
- TODOs for features blocked on Fedora go here.

## 4. Port from dev-env

- Shell, tmux, nvim, git, ghostty, starship, lazygit, yazi configs: copy as-is, they barely depend on Omarchy (recolor to Granite).
- hypr bindings, input, looknfeel, host files, application rules: rewrite against our own base.
- Install scripts and optional groups: port one by one, split per distro where needed.
- Self-update timer (`workstation-update-self`) once a machine runs from a live checkout.

## 5. Decide

- Arch vs Fedora after using both for a while. Drop the loser's `.fedora`/`.arch` files and `install/distro/` entry, or keep both.
- Switch the desktop and laptop from dev-env once the prototype covers daily use.
