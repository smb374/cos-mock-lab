#!/usr/bin/env bash
# Runs inside the cos-mock VM, through the repo mount. See docs/setup.md.
# Plan stage 6: sync dashboards and alert rules from git with cos-configuration-k8s,
# and set the webhook receiver in Alertmanager.
# Usage: gitsync.sh <git_repo_url> [branch]   Run once. It does not check for existing apps.
set -euo pipefail
cd "$(dirname "$0")/../.."
source scripts/vm/lib.sh

repo=${1:?usage: gitsync.sh <git_repo_url> [branch]}
branch=${2:-main}

juju deploy cos-configuration-k8s cos-config --channel 3.0/stable --trust -m cos-lite \
  --config git_repo="$repo" --config git_branch="$branch" \
  --config prometheus_alert_rules_path=alerts --config grafana_dashboards_path=dashboards
juju integrate -m cos-lite cos-config:grafana-dashboards grafana:grafana-dashboard
juju integrate -m cos-lite cos-config:prometheus-config prometheus:metrics-endpoint

# VM_ADDR in the file is a placeholder for the address of this VM.
# The juju snap reads files only under $HOME.
webhook=$(mktemp -p "$HOME")
sed "s/VM_ADDR/$VM_ADDR/" alertmanager/webhook.yml >"$webhook"
juju config -m cos-lite alertmanager config_file=@"$webhook"
rm "$webhook"
