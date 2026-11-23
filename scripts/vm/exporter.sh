#!/usr/bin/env bash
# Runs inside the cos-mock VM, through the repo mount. See docs/setup.md.
# Installs and starts the exporter as the systemd unit lab-exporter.
# Usage: exporter.sh [frozen_age_seconds]
# With an age, every fake artifact age stays at that value. Without one, the ages grow and reset.
set -euo pipefail
cd "$(dirname "$0")/../.."

dropin=/etc/systemd/system/lab-exporter.service.d/frozen-age.conf
sudo cp exporter/lab-exporter.service /etc/systemd/system/lab-exporter.service
if [[ -n "${1:-}" ]]; then
  sudo mkdir -p "$(dirname "$dropin")"
  printf '[Service]\nEnvironment=LAB_FROZEN_AGE_SECONDS=%s\n' "$1" | sudo tee "$dropin" >/dev/null
else
  sudo rm -f "$dropin"
fi
sudo systemctl daemon-reload
sudo systemctl enable lab-exporter
sudo systemctl restart lab-exporter
