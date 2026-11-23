# Environment setup

Install this software with snap or apt, not with nix. The lab needs it on the host and in the VM. For the dev tools, see the README.

## Host

Requirements: Ubuntu with snapd, 6 CPU, 12 GB RAM, and 60 GB free disk.

```bash
sudo snap install multipass
just vm-up
just vm-shell
```

## Inside the VM

`just vm-up` mounts this repo in the VM at `~/cos-mock-lab`. Run `just vm-run install-tools` on the host to install `uv`, Terraform, and Docker in the VM. Install the rest for each stage of [plan.md](plan.md):

| Stage | Software | Install |
| --- | --- | --- |
| 2 | MicroK8s | `sudo snap install microk8s --channel=<version>-strict/stable` |
| 2 | Juju | `sudo snap install juju --channel=3.6/stable` |
| 4 | fly | Download from the Concourse web page |

Use a strict MicroK8s channel only. `juju bootstrap` fails on the classic channel. Follow the plan for the add-ons, the bootstrap, and the check of each step.

Scripts in `scripts/vm/` run inside the VM. Start them from the host with `just vm-run <script>`: `tf-apply`, `ci-up`, `ci-down`, `exporter`. Recipes that start with `vm-` run on the host.