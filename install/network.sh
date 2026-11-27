#!/bin/bash
# WiFi: iwd only authenticates, systemd-networkd from the base install does DHCP on every link (20-wlan.network)
set -euo pipefail

sudo systemctl enable iwd.service bluetooth.service
