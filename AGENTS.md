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
- Arch: official repos, chaotic-aur, AUR via yay.
  Fedora: Fedora, RPM Fusion, COPRs listed in `install/distro/fedora.sh`.
  Not packaged anywhere: an install script.
- Configs (`.config/`) are shared.
  If a path or binary differs per distro, solve it in the install script (symlink, alternative), not with two config copies.

## Layout

- `install.sh`: the installer.
  Sets up repos, stows the configs, picks optional groups with fzf, installs the lists, then runs `install/*.sh` and the chosen `install/optional/*.sh`.
  One run plus a reboot must give a finished machine.
- `install/distro/<id>.sh`: package manager layer.
- `install/packages*.lst`: packages every machine gets.
  One per line, `#` comments allowed.
- `install/optional/<group>[.<distro>].lst` / `.sh`: optional groups.
  The group name is the file name without the distro suffix.
- `install/*.sh`: setup steps, run alphabetically after the packages are installed.
- `bin/`: on `PATH`, not stowed.
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

- `test/vm arch|arch-luks install|up|ssh|key|type|shot|down|save|restore|reset|status` (usage at the top of the script, README).
  Headless QEMU/KVM + OVMF; look at the screen via `shot`, kernel log in `~/.cache/workstation-vm/<distro>.serial.log` (arch-luks).
  Always `test/vm <distro> down` when done.
- `install`: latest ISO (sha256 checked), root SSH via a cloud-init seed, archinstall with `test/archinstall/*.json`, snapshot `base`. `reset` = `restore base`.
- Guest: user/password arch (sudo), root locked, 2 GB (`VM_MEM`), Limine + btrfs, ESP 2 GiB at /boot. `arch-luks`: LUKS root, passphrase arch, `up` types it.
- archinstall JSON schema changes per release: check it against the ISO's archinstall when `install` breaks.
- Disk: each installed qcow2 ~2 GB, ISO 1.3 GB; delete what's not needed (`install` recreates).
- Host needs `qemu-hw-display-virtio-vga` (not in qemu-base). virgl impossible without a host GPU. `test/vm fedora`: TODO.
- Not testable in the VM: battery, lid, suspend, multi-monitor, real GPU → real hardware.
