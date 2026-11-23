# COS mock lab: execution plan

Date: 2026-11-23

## Goal

Build a disposable lab that runs COS Lite for a mock CI service. Use it to test dashboards, alert rules, and the link to a central COS before work on the real CI instance.

Done means all of these are true:
- COS Lite runs on Juju 3.6 in a Multipass VM, and Grafana shows Concourse metrics.
- Dashboard JSON and alert rules live in git and load from git.
- Each failure test in stage 6 fires its alert.
- A second model receives telemetry from the lab through an OpenTelemetry Collector.
- Stage 8 records whether the same stack works on Juju 4.0.

## Decisions (fixed)

| Item | Choice |
|---|---|
| Substrate | Multipass VM, Ubuntu 24.04 |
| Kubernetes | MicroK8s, strict channel |
| Juju | 3.6 first, 4.0 in stage 8 |
| COS | COS Lite, deployed with the Terraform module |
| Mock CI | Concourse quickstart in Docker, outside Juju, in the same VM |
| Fake signals | One Python exporter for Swift, LP and GitHub signals |

## Rules for the executor

- Run each command and read its output before you go to the next step.
- Do not claim a step is done without its check passing.
- Do not use the classic MicroK8s channel. `juju bootstrap` fails on it.
- If a charm config name below does not exist, run `juju config <app>` and use the real name. Record the difference in the log.
- Keep a run log in `lab-log.md` in the lab repo. Write each failed step and its fix.

## Stage 0: lab repo

1. Create a git repo `cos-mock-lab` with these paths: `terraform/`, `concourse/`, `exporter/`, `dashboards/`, `alerts/`, `lab-log.md`.
2. Commit after each stage.

Check: `git log` shows one commit per finished stage.

## Stage 1: VM

1. Run `multipass launch 24.04 --name cos-mock --cpus 6 --memory 12G --disk 60G`.
2. Run `multipass shell cos-mock`.

Why this size: the COS Lite tutorial needs 4 CPU, 8 GB RAM and 40 GB disk. Concourse and Docker need 2 CPU and 4 GB more.

Check: `nproc` prints 6 and `free -g` shows about 12.

## Stage 2: MicroK8s and Juju 3.6

1. Find the newest strict channel: `snap info microk8s`. Look for `<version>-strict/stable`.
2. Run `sudo snap install microk8s --channel=<version>-strict/stable`.
3. Run `sudo usermod -a -G snap_microk8s $USER` and `newgrp snap_microk8s`.
4. Run `sudo apt-get update && sudo apt-get install -y jq`.
5. Enable the add-ons: `microk8s enable dns hostpath-storage`.
6. Enable MetalLB on the VM address: `IPADDR=$(ip -4 -j route get 2.2.2.2 | jq -r '.[] | .prefsrc')` then `microk8s enable metallb:$IPADDR-$IPADDR`.
7. Wait for rollout: `microk8s kubectl rollout status deployments/hostpath-provisioner -n kube-system -w`, then the same for `deployments/coredns -n kube-system` and `daemonset.apps/speaker -n metallb-system`.
8. Run `sudo snap install juju --channel=3.6/stable`.
9. Run `juju bootstrap microk8s lab`.

Check: `microk8s status` lists the three add-ons as enabled. `juju controllers` shows `lab` and version 3.6.x.

Snapshot: stop the VM and run `multipass snapshot cos-mock --name s2-juju36-bootstrapped`. Restart it.

## Stage 3: COS Lite

1. Install Terraform: `sudo snap install terraform --classic`.
2. In `terraform/main.tf`, copy the root module from the COS Lite MicroK8s tutorial (section "Deploy COS Lite using Terraform"). Use `source = "git::https://github.com/canonical/observability-stack//terraform/cos-lite"`, `risk = "stable"`, and `internal_tls = true`.
3. Run `juju add-model cos-lite`. Run `terraform init` and `terraform apply -var="model=cos-lite"`.
4. Run `juju status --relations --watch=5s` until all apps are `active`.
5. Get the Grafana password: `juju run grafana/leader get-admin-password --model cos-lite`.
6. Get the URLs: `juju run traefik/0 show-proxied-endpoints --format=yaml --model cos-lite`.

Check: Grafana opens from the host (use `multipass info cos-mock` for the VM address; the Traefik URL uses the MetalLB address, so the host can reach it directly) and shows the Prometheus and Loki data sources.

Snapshot: `s3-cos-lite`.

## Stage 4: mock CI

1. Install Docker in the VM: `sudo apt-get install -y docker.io docker-compose-v2`, then `sudo usermod -aG docker $USER` and `newgrp docker`.
2. Put the Concourse quickstart compose file in `concourse/docker-compose.yml`. Add these web settings: `CONCOURSE_PROMETHEUS_BIND_IP=0.0.0.0` and `CONCOURSE_PROMETHEUS_BIND_PORT=9391`. Set `CONCOURSE_EXTERNAL_URL` to `http://<vm-address>:8080`.
3. Run `docker compose up -d` in `concourse/`.
4. Install `fly` from the Concourse web page. Log in: `fly -t lab login -c http://<vm-address>:8080 -u test -p test`.
5. Set pipeline `fake-image-build` from `concourse/fake-pipeline.yml`. The pipeline has these jobs:
   - `base`: runs a task that sleeps 30 s, and fails when the minute is a multiple of 7.
   - `sideload`: triggered by `base`, sleeps 20 s.
   - `sidedish`: triggered by `sideload`, sleeps 20 s.
   - A `time` resource triggers `base` every 5 minutes.
6. Unpause the pipeline.

Check: `curl -s http://<vm-address>:9391/metrics` prints `concourse_builds_finished`. `fly -t lab builds` shows both success and failure builds.

## Stage 5: scrape Concourse and the exporter

1. Write `exporter/exporter.py` with `prometheus_client`. Expose these gauges on port 9400:
   - `lab_swift_artifact_age_seconds{artifact}`: the age grows with time. Reset it to 0 at random times.
   - `lab_lp_build_state{livefs}`, values 0 or 1 at random.
   - `lab_github_run_state{workflow}`, values 0 or 1 at random.
   Keep the fake values in one dict so stage 6 can change them.
2. Run it as a systemd unit in the VM.
3. Deploy the scrape charm into the model: `juju deploy prometheus-scrape-config-k8s scrape-lab --channel=<risk> --trust --model cos-lite`. Run `juju config scrape-lab` and read the config names.
4. Set two scrape jobs: `<vm-address>:9391` (Concourse) and `<vm-address>:9400` (exporter). Use the VM address that pods can reach.
5. Integrate it: `juju integrate scrape-lab:metrics-endpoint prometheus:metrics-endpoint`.

Check: in Prometheus, `up{job=~".*"}` is 1 for both targets, and `concourse_builds_finished` returns data.

Snapshot: `s5-mock-ci`.

## Stage 6: dashboards and alerts

Take the signal list from the research report (section 2 summary and section 4). Build these first. Every panel has a short title and a unit.

Dashboard `ci-health` (file `dashboards/ci-health.json`):
1. Build success rate by job, last 24 h.
2. Build duration p50 and p95 by job.
3. Time since the last successful build, by job.
4. Workers: count and state.
5. Exporter panels: Swift artifact age, LP build state, GitHub run state.

Alert rules (files in `alerts/`, Prometheus rule format):

| Alert | Fires when | Test |
|---|---|---|
| `ConcourseJobFailing` | A job fails 3 times in a row | Make `base` fail 3 times |
| `NoSuccessfulBuild` | No success for 2 h | Pause the pipeline |
| `WorkerMissing` | Worker count is 0 for 5 min | `docker compose stop worker` |
| `ArtifactStale` | Artifact age is over 26 h | Set the fake age to 30 h |
| `ScrapeTargetDown` | `up == 0` for 5 min | Stop the exporter |

Load from git:
1. Push the repo to a git host that the VM can reach.
2. Follow the COS how-to "Sync alert rules from Git". Record the config names you used.
3. Load the dashboard through the Grafana dashboard relation, not by hand in the Grafana UI.

Check: each test row above fires the alert in Alertmanager, and the alert clears when you undo the fault.

Receiver test: add a webhook receiver to Alertmanager and use `https://webhook.site` or a local `nc -l` to prove an alert arrives.

Snapshot: `s6-dashboards-alerts`.

## Stage 7: central COS link

1. Add a model: `juju add-model central`. Deploy a second, small COS Lite there as the stand-in central COS, or use an OpenTelemetry Collector with local Prometheus remote-write only.
2. Follow the COS how-to "Send telemetry to external backends". Use the OpenTelemetry Collector in `cos-lite`.
3. Create a cross-model offer from `central` and consume it in `cos-lite`.

Check: the central Prometheus shows `concourse_builds_finished` with the Juju topology labels from the lab model.

Record: which labels arrive, the telemetry volume (use "Evaluate telemetry volume"), and the extra memory use.

## Stage 8: Juju 4.0 pass

1. Read the Juju 4.0 release notes and the "Upgrade your deployment from 3.6 to 4.0" how-to. Write the breaking changes that touch COS in `lab-log.md`.
2. Restore the snapshot `s6-dashboards-alerts` as a clone. Upgrade the controller and model by the how-to. This tests the upgrade path.
3. Make a second fresh VM `cos-mock-40`. Repeat stages 2, 3, 5 and 6 with `juju` from channel `4.0/stable`. Use the same Terraform module.
4. Check the `juju/juju` Terraform provider version. Record whether it supports Juju 4.0.

Check: for both paths, write one line in `lab-log.md`: works, works with changes (list them), or fails (give the error).

## Outputs

1. `lab-log.md` with problems and fixes.
2. The final dashboard JSON and alert rules in `dashboards/` and `alerts/`.
3. A short report in `docs/report.md` with: the final sizing (CPU, RAM, disk used), the Juju 3.6 and 4.0 result, the Concourse metrics that were useful, and what to change for the real instance.

## Not covered

- Real data from Swift, GitHub and Launchpad. The exporter uses fake values.
- TLS with the real CA, SSO, and Canonical's central COS access.
- High availability and backups.
- Jenkins. It is out of scope (see the research report).

## Open items

- The exact strict MicroK8s channel, found in stage 2.
- The config names of `prometheus-scrape-config-k8s`, found in stage 5.
- Whether Juju 4.0 supports the COS charms, found in stage 8.