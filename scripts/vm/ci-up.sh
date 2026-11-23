#!/usr/bin/env bash
# Runs inside the cos-mock VM, through the repo mount. See docs/setup.md.
set -euo pipefail
cd "$(dirname "$0")/../.."

docker compose -f concourse/docker-compose.yml up -d
