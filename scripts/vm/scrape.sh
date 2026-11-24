#!/usr/bin/env bash
# Runs inside the cos-mock VM, through the repo mount. See docs/setup.md.
# Deploys the two scrape-target apps (plan stage 5) with Juju topology labels (stage 7).
# Run once on a fresh model. It does not check for existing apps.
set -euo pipefail
cd "$(dirname "$0")/../.."
source scripts/vm/lib.sh

scrape() { # name job port application
  juju deploy prometheus-scrape-target-k8s "scrape-$1" --channel 3.0/stable --trust -m cos-lite \
    --config job_name="$2" --config targets="$VM_ADDR:$3" \
    --config labels="juju_model:cos-lite,juju_application:$4"
  juju integrate -m cos-lite "scrape-$1:metrics-endpoint" prometheus:metrics-endpoint
}

scrape concourse concourse 9391 concourse
scrape exporter exporter 9400 lab-exporter
