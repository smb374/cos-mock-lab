#!/usr/bin/env bash
# Runs inside the cos-mock VM, through the repo mount. See docs/setup.md.
set -euo pipefail
cd "$(dirname "$0")/../.."

command -v uv >/dev/null || curl -LsSf https://astral.sh/uv/install.sh | sh
command -v terraform >/dev/null || sudo snap install terraform --classic
command -v docker >/dev/null || {
  sudo apt-get update
  sudo apt-get install -y docker.io docker-compose-v2
  sudo usermod -aG docker "$USER"
}
