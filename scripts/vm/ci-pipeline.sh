#!/usr/bin/env bash
# Runs inside the cos-mock VM, through the repo mount. See docs/setup.md.
# Usage: ci-pipeline [true|false]. true makes the `base` job fail.
set -euo pipefail
cd "$(dirname "$0")/../.."

fly -t lab set-pipeline -n -p fake-image-build -c concourse/fake-pipeline.yml -v "base_fail=${1:-false}"
fly -t lab unpause-pipeline -p fake-image-build
