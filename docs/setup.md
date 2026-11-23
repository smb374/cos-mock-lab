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

Clone this repo in the VM. Then install the software for each stage of [plan.md](plan.md):

| Stage | Software | Install |
| --- | --- | --- |
| 2 | MicroK8s | `sudo snap install microk8s --channel=<version>-strict/stable` |
| 2 | Juju | `sudo snap install juju --channel=3.6/stable` |
| 3 | Terraform | `sudo snap install terraform --classic` |
| 4 | Docker | `sudo apt-get install -y docker.io docker-compose-v2` |
| 4 | fly | Download from the Concourse web page |
| 5 | uv | See the README for the install link |

Use a strict MicroK8s channel only. `juju bootstrap` fails on the classic channel. Follow the plan for the add-ons, the bootstrap, and the check of each step.

Recipes marked "in VM" in the `justfile` run inside the VM. Recipes that start with `vm-` run on the host.
