#!/bin/bash
set -euo pipefail

if [ ! -f /etc/snapper/configs/root ]; then
  sudo snapper -c root create-config /
fi

# Update snapshots (cleanup "number") and weekly ones (cleanup "timeline") rotate separately.
# NUMBER_LIMIT counts pre and post snapshots one by one: 10 is the last 5 updates.
# The weekly timer makes every timeline snapshot the first of its week; 3 of them means the oldest is always over a week old.
sudo snapper -c root set-config \
  NUMBER_LIMIT=10 \
  TIMELINE_CREATE=yes \
  TIMELINE_LIMIT_HOURLY=0 \
  TIMELINE_LIMIT_DAILY=0 \
  TIMELINE_LIMIT_WEEKLY=3 \
  TIMELINE_LIMIT_MONTHLY=0 \
  TIMELINE_LIMIT_QUARTERLY=0 \
  TIMELINE_LIMIT_YEARLY=0

sudo systemctl enable snapper-timeline.timer snapper-cleanup.timer
