# Sourced by install.sh. Defines setup_repos and install_packages.

setup_repos() {
  if ! grep -q '^\[chaotic-aur\]' /etc/pacman.conf; then
    sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
    sudo pacman-key --lsign-key 3056513887B78AEB
    sudo pacman -U --needed --noconfirm \
      https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst \
      https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst
    printf '[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist\n' | sudo tee -a /etc/pacman.conf >/dev/null
  fi
  sudo pacman -Syu --needed --noconfirm yay
}

install_packages() {
  yay -S --needed --noconfirm "$@"
}
