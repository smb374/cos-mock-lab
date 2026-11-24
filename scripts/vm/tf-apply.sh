#!/usr/bin/env bash
# Runs inside the cos-mock VM, through the repo mount. See docs/setup.md.
# Creates the Juju model if it is missing, then deploys COS Lite with Terraform.
# The state and the plugin directory stay in the VM, so a purged VM leaves no stale state in the repo.
set -euo pipefail
cd "$(dirname "$0")/../.."

model=${1:-cos-lite}
export TF_DATA_DIR=$HOME/.terraform-data

juju show-model "$model" >/dev/null 2>&1 || juju add-model "$model"
terraform -chdir=terraform init
terraform -chdir=terraform apply -auto-approve -var="model=$model" -state="$HOME/$model.tfstate"
