#!/usr/bin/env bash
# Runs inside the cos-mock VM, through the repo mount. See docs/setup.md.
# Logs each request that Alertmanager sends to port 9000 in /tmp/webhook.log. Stop it with Ctrl-C.
set -euo pipefail
: >/tmp/webhook.log
while true; do
  nc -l 9000 >>/tmp/webhook.log
  echo >>/tmp/webhook.log
done
