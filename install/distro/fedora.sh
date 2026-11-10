# Sourced by install.sh. Defines setup_repos and install_packages.

# COPR repos, owner/project
coprs=(
)

setup_repos() {
  local copr
  sudo dnf install -y dnf-plugins-core
  sudo dnf install -y \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
  for copr in "${coprs[@]}"; do
    sudo dnf copr enable -y "$copr"
  done
  sudo dnf upgrade -y --refresh
}

install_packages() {
  sudo dnf install -y "$@"
}
