#!/usr/bin/env bash
# Runs inside the cos-mock VM, through the repo mount. See docs/setup.md.
# Plan stage 7, light option: a central Prometheus in model `central`. The collector in `cos-lite`
# scrapes the two scrape-target apps and sends the metrics there by remote write.
# Run once, after scrape.sh. It does not check for existing apps.
set -euo pipefail

juju add-model central
juju deploy prometheus-k8s prometheus --channel 3.14/stable --trust -m central
juju offer central.prometheus:receive-remote-write
juju consume admin/central.prometheus central-prom -m cos-lite
juju integrate -m cos-lite otelcol:send-remote-write central-prom
juju integrate -m cos-lite scrape-concourse:metrics-endpoint otelcol:metrics-endpoint
juju integrate -m cos-lite scrape-exporter:metrics-endpoint otelcol:metrics-endpoint
