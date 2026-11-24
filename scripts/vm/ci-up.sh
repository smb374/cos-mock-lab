#!/usr/bin/env bash
# Runs inside the cos-mock VM, through the repo mount. See docs/setup.md.
# Starts Concourse, then installs fly from its web page and logs in (plan stage 4).
# Extra arguments go to `docker compose up -d`, e.g. ci-up.sh --force-recreate concourse
set -euo pipefail
cd "$(dirname "$0")/../.."
source scripts/vm/lib.sh

docker compose -f concourse/docker-compose.yml up -d --quiet-pull "$@"

until curl -sf "http://$VM_ADDR:8080/api/v1/info" >/dev/null; do sleep 3; done
if ! command -v fly >/dev/null; then
  sudo curl -sfLo /usr/local/bin/fly "http://$VM_ADDR:8080/api/v1/cli?arch=amd64&platform=linux"
  sudo chmod +x /usr/local/bin/fly
fi
# The user and password come from CONCOURSE_ADD_LOCAL_USER in the compose file.
fly -t lab login -c "http://$VM_ADDR:8080" -u test -p test
