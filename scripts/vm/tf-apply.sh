#!/usr/bin/env bash
# Runs inside the cos-mock VM, through the repo mount. See docs/setup.md.
set -euo pipefail
cd "$(dirname "$0")/../.."

terraform -chdir=terraform init
terraform -chdir=terraform apply -auto-approve -var="model=${1:-cos-lite}"