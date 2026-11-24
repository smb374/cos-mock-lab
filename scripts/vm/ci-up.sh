#!/usr/bin/env bash
# Runs inside the cos-mock VM, through the repo mount. See docs/setup.md.
# Starts Concourse, then installs fly from its web page and logs in (plan stage 4).
set -euo pipefail
cd "$(dirname "$0")/../.."

docker compose -f concourse/docker-compose.yml up -d --quiet-pull

addr=$(ip -4 -o addr show eth0 | awk '{print $4}' | cut -d/ -f1)
until curl -sf "http://$addr:8080/api/v1/info" >/dev/null; do sleep 3; done
if ! command -v fly >/dev/null; then
  sudo curl -sfLo /usr/local/bin/fly "http://$addr:8080/api/v1/cli?arch=amd64&platform=linux"
  sudo chmod +x /usr/local/bin/fly
fi
# The user and password come from CONCOURSE_ADD_LOCAL_USER in the compose file.
fly -t lab login -c "http://$addr:8080" -u test -p test
