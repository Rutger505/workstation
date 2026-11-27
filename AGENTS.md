# workstation

Setup for my own Hyprland desktop on Arch and Fedora: packages, dotfiles linked with GNU Stow, and a few scripts.
Successor to dev-env (Omarchy), but without Omarchy: nothing may depend on Omarchy's scripts, defaults, themes or `OMARCHY_PATH`.
Prototype, not on any machine yet; dev-env stays the live setup. Status and what's left: `PLAN.md`.
Don't port things from dev-env unless asked.

## Git workflow

Commit directly to `main`, no feature branch or PR; push when done.
This overrides the global branch-first rule for this repo.
One branch for both distros, never arch/fedora branches.

## Distros

`install.sh` reads `ID` from `/etc/os-release` and sources `install/distro/<id>.sh`, which defines `setup_repos` and `install_packages`.
Scripts see the distro in `$WORKSTATION_DISTRO`.
Arch leads: if Fedora blocks a feature, no hoops; build it for Arch and add a Fedora TODO under step 3 in `PLAN.md`.

- A file without a distro suffix runs everywhere: `packages.lst`, `install/foo.sh`, `optional/<group>.lst`.
- `<name>.arch.<ext>` / `<name>.fedora.<ext>` only on that distro.
  Use this when the package name or setup differs, instead of `if` blocks in shared scripts.
- A package goes in `packages.lst` only if the name is identical on both.
  Otherwise one line in `packages.arch.lst` and one in `packages.fedora.lst`.
- Arch: official repos, chaotic-aur, AUR via paru.
  Fedora: Fedora, RPM Fusion, COPRs listed in `install/distro/fedora.sh`.
  Not packaged anywhere: an install script.
- Configs (`.config/`) are shared.
  If a path or binary differs per distro, solve it in the install script (symlink, alternative), not with two config copies.

## Layout

- `install.sh`: the installer.
  Sets up repos, stows the configs, picks optional groups with fzf (without a terminal: keeps the saved choice), installs the lists, copies `system/`, then runs `install/*.sh` and the chosen `install/optional/*.sh`.
  One run plus a reboot must give a finished machine.
- `install/distro/<id>.sh`: package manager layer.
- `install/packages*.lst`: packages every machine gets.
  One per line, `#` comments allowed.
- `install/optional/<group>[.<distro>].lst` / `.sh`: optional groups.
  The group name is the file name without the distro suffix.
- `install/*.sh`: setup steps, run alphabetically after the packages are installed.
- `system/`: files for outside `$HOME` (mirrors `/`), copied as root by `install.sh`; removing one here doesn't remove it from machines. Files that need the user or machine (getty autologin, kernel cmdline) are written by their install script instead.
- `bin/`: on `PATH` (via `.config/uwsm/env`), not stowed. Scripts are named `workstation-<thing>`.
- `.config/hypr/`: Lua config; per-machine bits in `hosts/<hostname>.lua` (loaded if present), monitors and monitor-bound workspaces in `monitors.lua`, colors only in `colors.lua` (waybar: `.config/waybar/colors.css`; hyprlock, mako: top of their config).
- `test/vm`: headless test VM (QEMU/KVM + OVMF, Hyprland on llvmpipe), see README; `test/archinstall/`: its archinstall config.
- Everything else (`.config/`, `.claude/`, `.ssh/`) is stowed into `$HOME`.
  `.stow-local-ignore` lists what isn't.

## Rules

- Keep it minimal.
  No comments unless they explain a non-obvious why, no logging, no feature flags, no fallbacks for situations that can't happen on Arch or Fedora.
- Every install script must be safe to rerun.
- Install scripts can rely on the configs being stowed, but not on anything that only exists after a reboot or re-login.
  Enable user units without `--now`, the reboot starts them.
- Test on both distros before calling something done (VMs are fine).

## Commands

- `workstation-stow`: restow the configs, which also prunes links to deleted files.
  Add `--adopt` when stow reports conflicts with existing files, then check `git diff`.
- `bash -n` and `shellcheck` (via `bunx shellcheck`) for scripts.
- Package names: check both distros (`pacman -Si` / aur.archlinux.org, packages.fedoraproject.org or `docker run --rm fedora dnf info <pkg>`).

## Test VM

- `test/vm arch|arch-luks install|up|ssh|sync|key|type|shot|down|save|restore|reset|status` (usage at the top of the script, README).
- Test a change: `sync` (working tree incl. uncommitted changes → guest `~/.local/share/workstation`), then `test/vm arch ssh '~/.local/share/workstation/install.sh'` (quote the `~`).
- Snapshots: `base` (fresh archinstall), `system` (`arch`: part 2 installed and booted once), `hyprland` (`arch`: part 3), `tools` (`arch`: part 6). Delete extra ones (`qemu-img snapshot -d`), host disk is tight. UEFI vars aren't in snapshots: the `Limine` boot entry stays after `restore base`, OVMF skips it.
- After part 2 Hyprland runs on tty1 via autologin (once per boot). Over ssh: `hyprctl -i 0 ...`; Lua dispatch syntax, e.g. `hyprctl -i 0 dispatch 'hl.dsp.exit()'`.
  Extra monitor: `hyprctl -i 0 output create headless NAME` / `output remove NAME` (fires the monitor events; only the first QEMU head shows in `shot`).
  Headless QEMU/KVM + OVMF; look at the screen via `shot`, kernel log in `~/.cache/workstation-vm/<distro>.serial.log` (arch-luks).
  Always `test/vm <distro> down` when done.
- `install`: latest ISO (sha256 checked), root SSH via a cloud-init seed, archinstall with `test/archinstall/*.json`, snapshot `base`. `reset` = `restore base`.
- Guest: user/password arch (passwordless sudo, set by `up`), root locked, 2 GB (`VM_MEM`), Limine + btrfs, ESP 2 GiB at /boot. `arch-luks`: LUKS root, passphrase arch, `up` types it.
- archinstall JSON schema changes per release: check it against the ISO's archinstall when `install` breaks.
- Disk: each installed qcow2 ~2 GB, ISO 1.3 GB; delete what's not needed (`install` recreates).
- Host needs `qemu-hw-display-virtio-vga` (not in qemu-base). virgl impossible without a host GPU. `test/vm fedora`: TODO.
- Not testable in the VM: battery (scripts: fake dir via `WORKSTATION_POWER_SUPPLY`, PLAN step 2; for user units `systemctl --user set-environment`), lid, backlight, hibernate resume (S3 suspend works: QMP `system_wakeup`), real monitors (headless outputs cover the monitor logic), real GPU → real hardware.
