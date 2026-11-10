#!/bin/bash
set -euo pipefail

cd "$(dirname "$(realpath "$0")")/install"

optional_file="${XDG_CONFIG_HOME:-$HOME/.config}/workstation/optional-packages.conf"

WORKSTATION_DISTRO=$(. /etc/os-release && echo "$ID")
if [ ! -f "distro/$WORKSTATION_DISTRO.sh" ]; then
  echo "Unsupported distro: $WORKSTATION_DISTRO" >&2
  exit 1
fi
export WORKSTATION_DISTRO
# shellcheck source=/dev/null
. "distro/$WORKSTATION_DISTRO.sh"

# Files for the other distro are skipped: foo.lst and foo.sh run everywhere, foo.<distro>.lst/.sh only on that distro
for_this_distro() {
  local file name
  for file in "$@"; do
    [ -e "$file" ] || continue
    name=$(basename "$file")
    name=${name%.*}
    case "$name" in
      *.*) [ "${name##*.}" = "$WORKSTATION_DISTRO" ] && echo "$file" ;;
      *) echo "$file" ;;
    esac
  done
}

select_optional_groups() {
  local groups current preselect="" i=0 selected
  groups=$(for file in $(for_this_distro optional/*); do name=$(basename "${file%.*}"); echo "${name%%.*}"; done | sort -u)
  current=$(cat "$optional_file" 2>/dev/null || true)

  while read -r group; do
    i=$((i + 1))
    if grep -qxF "$group" <<<"$current"; then
      preselect+="pos($i)+toggle+"
    fi
  done <<<"$groups"

  # fzf returns the item under the cursor when nothing is marked, so an empty selection needs become(true)
  selected=$(fzf --multi --prompt="Optional packages: " \
    --header="SPACE to toggle, ENTER to confirm" \
    --bind "load:${preselect}first" \
    --bind "j:down,k:up,ctrl-a:select-all,ctrl-d:deselect-all,space:toggle" \
    --bind 'enter:transform:[ "$FZF_SELECT_COUNT" -eq 0 ] && echo "become(true)" || echo accept' \
    --preview 'cat optional/{}.* 2>/dev/null | head -n 50' \
    <<<"$groups")

  mkdir -p "$(dirname "$optional_file")"
  echo "$selected" >"$optional_file"
}

link_configs() {
  # Missing directories get folded into a symlink to the repo, and apps write keys, credentials and unit links into these
  mkdir -p -m 700 "$HOME/.ssh" "$HOME/.claude" "$HOME/.local/bin" "$HOME/.config/systemd/user"
  ../bin/workstation-stow
}

setup_repos
install_packages fzf stow git
link_configs
select_optional_groups

mapfile -t lists < <(for_this_distro packages.lst "packages.$WORKSTATION_DISTRO.lst")
mapfile -t scripts < <(for_this_distro ./*.sh)
while read -r group; do
  [ -n "$group" ] || continue
  mapfile -t -O "${#lists[@]}" lists < <(for_this_distro "optional/$group.lst" "optional/$group.$WORKSTATION_DISTRO.lst")
  mapfile -t -O "${#scripts[@]}" scripts < <(for_this_distro "optional/$group.sh" "optional/$group.$WORKSTATION_DISTRO.sh")
done <"$optional_file"

mapfile -t packages < <(sed 's/#.*//; s/[[:space:]]*$//' "${lists[@]}" | grep .)
if [ "${#packages[@]}" -gt 0 ]; then
  install_packages "${packages[@]}"
fi

for script in "${scripts[@]}"; do
  echo "Running $script"
  "./$script"
done

echo "Done. Reboot to start the session."
