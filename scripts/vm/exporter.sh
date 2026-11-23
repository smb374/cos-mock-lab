#!/usr/bin/env bash
# Runs inside the cos-mock VM, through the repo mount. See docs/setup.md.
# Installs and starts the exporter as the systemd unit lab-exporter.
set -euo pipefail
cd "$(dirname "$0")/../.."

sudo cp exporter/lab-exporter.service /etc/systemd/system/lab-exporter.service
sudo systemctl daemon-reload
sudo systemctl enable lab-exporter
sudo systemctl restart lab-exporter
