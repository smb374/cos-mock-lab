# Reproduce the lab

This guide rebuilds the lab from an empty host. It works for Juju 3.6 and for Juju 4.0. The only difference is the channel that you give to `bootstrap`. For the plan and the reasons behind each stage, see [plan.md](plan.md). For the host and VM requirements, see [setup.md](setup.md).

All commands run on the host, in the repo root, unless the text says otherwise. `just vm-run <script>` runs `scripts/vm/<script>.sh` in the VM. `just vm-exec '<cmd>'` runs one shell command in the VM.

## Before you start

- Host: Ubuntu with `snapd`, `multipass` and `just`. Free: 6 CPU, 12 GB RAM, 60 GB disk.
- One VM at a time. The host needs about 12 GB of free RAM for each VM.
- The repo must be on a git host that the VM can reach without credentials. `gitsync.sh` clones it from inside the VM. A private repo blocks the sync.
- Copy `concourse/.env.example` to `concourse/.env` and set your own values. Git ignores `.env`.

## Steps

| # | Command | What it does | Check |
| --- | --- | --- | --- |
| 1 | `just vm-launch` | Creates the VM `cos-mock` and mounts the repo at `~/cos-mock-lab`. | `just vm-exec 'nproc; free -g'` shows 6 and about 12. |
| 2 | `just vm-run install-tools` | Installs `uv`, Terraform and Docker. | `just vm-exec 'terraform version; docker --version'` |
| 3 | `just vm-run bootstrap <channel>` | Installs MicroK8s `1.36-strict/stable`, the add-ons and MetalLB on the VM address. Installs Juju and bootstraps the controller `lab`. The channel is `3.6/stable` (default) or `4.0/stable`. | `just vm-exec 'juju controllers'` shows `lab` and the version. |
| 4 | `just vm-exec 'juju add-model cos-lite'` | Creates the model. | `just vm-exec 'juju models'` |
| 5 | `just vm-run tf-apply` | Deploys COS Lite with the Terraform module. 50 resources. | After 10 to 25 min: `just vm-exec 'juju status -m cos-lite'` shows 8 apps `active`. |
| 6 | Edit two files (see "VM address") | Puts the VM address in the repo files. | `just vm-ip` and the two files show the same address. |
| 7 | `just vm-run ci-up` | Starts Concourse, installs `fly` from its web page and logs in. | `just vm-exec 'curl -s localhost:9391/metrics \| grep -c concourse_builds_finished'` prints a number above 0. |
| 8 | `just vm-run ci-pipeline` | Sets and unpauses the pipeline `fake-image-build`. | `just vm-exec 'fly -t lab builds'` lists builds. |
| 9 | `just vm-run exporter` | Installs and starts the exporter as `lab-exporter` (port 9400). | `just vm-exec 'curl -s localhost:9400/metrics \| grep -c ^lab_'` prints 6. |
| 10 | `just vm-run scrape` | Deploys `scrape-concourse` and `scrape-exporter` with Juju topology labels. | In Prometheus, `up` is 1 for both targets. |
| 11 | `just vm-run gitsync <repo_url> main` | Deploys `cos-config`. It loads `dashboards/` and `alerts/` from git. It also sets the Alertmanager webhook. | `cos-config` is `active`. Prometheus lists 5 rules. Grafana lists the dashboard `CI health`. |
| 12 | `just vm-run central` (optional) | Stage 7. Model `central` with a Prometheus. The collector in `cos-lite` sends the scraped metrics there. | The central Prometheus returns `concourse_builds_finished_total` with `juju_model` and `juju_application` labels. |

Steps 4 and 5 use the model name `cos-lite`. `tf-apply` takes another name as its first argument, but the other scripts expect `cos-lite`.

### VM address

Two files hold the VM address, and `just vm-ip` shows it. Change both before step 7:

- `concourse/docker-compose.yml`: `CONCOURSE_EXTERNAL_URL: http://<address>:8080`
- `alertmanager/webhook.yml`: `url: http://<address>:9000/`

The scripts `scrape.sh` and `ci-up.sh` read the address from `eth0`. Multipass keeps the same address across `stop` and `start`. A purge gives a new address.

### URLs and passwords

- Grafana: `http://<address>/cos-lite-grafana`. The password: `just vm-exec 'juju run -m cos-lite grafana/leader get-admin-password'`.
- Prometheus: `http://<address>/cos-lite-prometheus-0`.
- Concourse: `http://<address>:8080`. User and password: `test` and `test`.

## Failure tests (stage 6)

Run a fault, wait for the alert, then undo the fault. Check the alerts in Alertmanager or in `http://<address>/cos-lite-prometheus-0/alerts`.

| Alert | Fault | Undo |
| --- | --- | --- |
| `ConcourseJobFailing` | `just vm-run ci-pipeline true` (the `base` job fails) | `just vm-run ci-pipeline` |
| `NoSuccessfulBuild` | `just vm-exec 'fly -t lab pause-pipeline -p fake-image-build'` and wait 2 h | `just vm-exec 'fly -t lab unpause-pipeline -p fake-image-build'` |
| `WorkerMissing` | `just vm-exec 'docker compose -f ~/cos-mock-lab/concourse/docker-compose.yml stop concourse'` | Same command with `start`. Also fires `ScrapeTargetDown` for the Concourse target. |
| `ArtifactStale` | `just vm-run exporter 108000` (age frozen at 30 h) | `just vm-run exporter` |
| `ScrapeTargetDown` | Stop Concourse as in the `WorkerMissing` row (tested). Stopping `lab-exporter` with `just vm-exec 'sudo systemctl stop lab-exporter'` should work too, but was not tested. | Start it again. |

`WorkerMissing` and `ScrapeTargetDown` have `for: 5m`, so each needs about 6 min to fire. `ConcourseJobFailing` and `NoSuccessfulBuild` were never tested to the end: the first needs a fault of more than 20 min, the second a pause of 2 h. The pause command in the table was not run.

Receiver test: start the sink with `just vm-exec 'sudo systemd-run --uid=ubuntu --unit webhook-sink bash ~/cos-mock-lab/scripts/vm/webhook-sink.sh'`. Run it as `ubuntu`, because `/tmp/webhook.log` belongs to that user. Cause an alert, then read `/tmp/webhook.log` in the VM. Stop the sink with `sudo systemctl stop webhook-sink`.

## Snapshots

`just vm-snapshot <name>` stops the VM, takes the snapshot and starts the VM. After each snapshot the lab recreated the Concourse container with `just vm-exec 'docker compose -f ~/cos-mock-lab/concourse/docker-compose.yml up -d --force-recreate concourse'`. Nobody tested whether this is needed. MicroK8s needs a few minutes before `juju` commands work again.

`just vm-purge` deletes the VM and all its snapshots.

## A second VM for another Juju version

The repo mount carries `terraform/terraform.tfstate` and the VM address. Two VMs cannot share one mount. Use a git worktree for the second VM:

```bash
git worktree add ../cos-mock-lab-40 -b juju-4.0
cp concourse/.env ../cos-mock-lab-40/concourse/.env
just --justfile ../cos-mock-lab-40/justfile vm=cos-mock-40 vm-launch
```

Run the other steps the same way: `just --justfile ../cos-mock-lab-40/justfile vm=cos-mock-40 vm-run <script>`. In the worktree, change the VM address in the two files (step 6) and commit that change on the worktree branch only. Stop the first VM before you launch the second one, because the host cannot hold two 12 GB VMs plus its own load.

## Known problems

- `microk8s enable` needs `sudo` on the strict snap. The scripts already do this.
- Image pulls are slow behind a VPN (1 MiB/s or less). Step 5 took about 20 min on Juju 4.0. The other steps that deploy charms (10 and 11) also wait for pulls.
- A deploy can fail once with a DNS timeout to `api.charmhub.io`. Run the same script again. If a script stops after the failed `deploy`, nothing was created.
- After a long outage, `grafana`, `loki` and `prometheus` can stay `blocked` with `401 Unauthorized`. `sudo microk8s stop` and `sudo microk8s start` fixed it once.
- `terraform apply` fails with `unknown model` when an old `terraform/terraform.tfstate` is in the repo. Move the file away and run it again.
- The scripts in steps 10, 11 and 12 do not check for existing apps. Run each one once on a fresh model.
- Do not start a background process in `just vm-exec`. The call waits for the process and never returns. Use `systemd-run`.

## Juju 3.6 and 4.0

The same scripts and the same Terraform module (`tf-cos-lite-3.1.3`, provider `juju/juju` 2.4.1) work on both versions. The list of 4.0 changes that touch this lab is in [lab-log.md](../lab-log.md), stage 8.

| Item | 3.6 | 4.0 |
| --- | --- | --- |
| Bootstrap channel | `3.6/stable` (3.6.29 tested) | `4.0/stable` (4.0.16 tested) |
| New model | No notice | Prints a notice about `juju add-ssh-key`. This lab does not need it. |
| `scrape.sh` | Works | Works. The charm prints the warning `declares no containers`. |
| Alert tests | Tested for 3 of 5 alerts (`ArtifactStale`, `WorkerMissing`, `ScrapeTargetDown`) | Not tested |
| Step 12 (`central.sh`) | Run by hand, with the same commands as the script. The script itself was never run end to end. | Not tested |

An upgrade from 3.6 to 4.0 is a model migration to a 4.0 controller. `juju upgrade-controller` cannot jump from 3.6 to 4.0. This guide does not cover the migration, and the lab did not test it.
