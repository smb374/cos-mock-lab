#!/usr/bin/env bash
# Runs inside the VM, through the repo mount. See docs/setup.md.
# Plan stage 2: MicroK8s (strict channel), add-ons, MetalLB on the VM address, Juju, bootstrap.
# Usage: bootstrap.sh [juju_channel]   (default 3.6/stable)
set -euo pipefail

channel=${1:-3.6/stable}
mk8s=1.36-strict/stable

sudo snap install microk8s --channel="$mk8s"
sudo usermod -a -G snap_microk8s "$USER"
sudo apt-get update
sudo apt-get install -y jq
# sg: the new group is not active in this session yet.
sg snap_microk8s -c "
  set -e
  sudo microk8s enable dns hostpath-storage
  addr=\$(ip -4 -j route get 2.2.2.2 | jq -r '.[] | .prefsrc')
  sudo microk8s enable metallb:\$addr-\$addr
  microk8s kubectl rollout status deployments/hostpath-provisioner -n kube-system -w
  microk8s kubectl rollout status deployments/coredns -n kube-system -w
  microk8s kubectl rollout status daemonset.apps/speaker -n metallb-system -w
"
sudo snap install juju --channel="$channel"
mkdir -p ~/.local/share/juju
sg snap_microk8s -c "juju bootstrap microk8s lab"
