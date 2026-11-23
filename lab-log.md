# Lab log

Record each failed step and its fix. Record each charm config name that differs from the plan.

| Stage | Step | Failure or difference | Fix |
| --- | --- | --- | --- |
| 2 | 1 | Newest strict channel | Used `1.36-strict/stable` (v1.36.2). |
| 2 | 5, 6 | `microk8s enable` fails with "Elevated permissions are needed" on the strict snap | Run it with `sudo`. |
| 2 | 3 | `newgrp` does not carry over between `multipass exec` calls | Not needed: each exec starts a new session with the group. |
| 2 | 9 | None | `juju bootstrap microk8s lab` worked. Controller `lab`, Juju 3.6.29. Snapshot `s2-juju36-bootstrapped` taken. |
| 3 | 2 | The plan module `source` has no tag | Pinned `?ref=tf-cos-lite-3.1.3`. |
| 3 | 3 | `terraform apply` waits for a prompt, and `multipass exec` has no TTY | Added `-auto-approve` in `scripts/vm/tf-apply.sh`. |
| 3 | 4 | `grafana`, `loki` and `prometheus` stayed blocked with `401 Unauthorized` on the StatefulSet patch. Pods stayed `Terminating` and `PodInitializing` for about 10 minutes | Ran `sudo microk8s stop` and `start`. The pods came back. I did not prove why the first calls got 401. |
| 3 | 4 | Image pulls took 5 minutes or more. A work VPN routes all host traffic and the speed fell to 1 MiB/s or less | None. Wait for the pulls. |
| 3 | 5, 6 | None | All 8 apps `active`. Grafana is at `http://10.69.190.128/cos-lite-grafana`. The host check showed the Prometheus, Loki and Alertmanager data sources. |
| 4 | 1 | `docker` is missing in the VM, so `just vm-run ci-up` could not run | Ran `just vm-run install-tools` first. |
| 4 | 2 | The Concourse quickstart does not publish the metrics port | Added `9391:9391` to `ports` in `concourse/docker-compose.yml`. |
| 4 | 5 | The plan makes `base` fail when the minute is a multiple of 7. That depends on the clock, and it is fragile | `base` reads the pipeline variable `base_fail`. `just vm-run ci-pipeline true` makes it fail. |
| 4 | 5 | `BUILD_NAME` is empty inside a task, so my first try (fail on every 3rd build) always failed | Dropped it. Concourse sets that variable in resource containers, not in tasks. |
| 4 | check | None | `concourse_builds_finished` shows `failed` and `succeeded` for `base`, and `succeeded` for `sideload` and `sidedish`. |
| 5 | 3, 4 | `prometheus-scrape-config-k8s` has no target or job options. It only overrides settings on jobs that come from another charm | Used `prometheus-scrape-target-k8s` (3.0/stable). It has `job_name` and `targets`, one job per app. Deployed two apps: `scrape-concourse` (`10.69.190.128:9391`) and `scrape-exporter` (`10.69.190.128:9400`). |
| 5 | 3 | `juju remove-application` waits for a prompt, and `multipass exec` has no TTY | Added `--no-prompt`. |
| 5 | check | The Concourse metrics have their own `job` label (`base`, `sideload`, `sidedish`). It replaces the scrape job label, so `job="concourse"` does not exist | Select Concourse series by `instance="10.69.190.128:9391"` or by metric name. Remember this for the stage 6 dashboards. |
| 5 | check | `up` is 1 for both targets. `concourse_builds_finished` and the `lab_*` gauges return data | None. |
| 6 | 1 | `ci.oem` host name was in the git history, and the repo was private | Removed the name from the files. Rewrote the history with `git-filter-repo` (run with `uvx`) and force pushed. Made the repo public. GitHub still serves the old commit `11fdd1e` by hash. Ask GitHub Support to run garbage collection. |
| 6 | 3 | The plan names no charm for Git sync | Used `cos-configuration-k8s` 3.0/stable as `cos-config`. Config: `git_repo`, `git_branch=main`, `prometheus_alert_rules_path=alerts`, `grafana_dashboards_path=dashboards`. Integrations: `grafana-dashboards` to `grafana:grafana-dashboard`, `prometheus-config` to `prometheus:metrics-endpoint`. I first deployed channel `2/stable` (Ubuntu 24.04) by mistake and replaced it. |
| 6 | 3 | The `ci-health` dashboard and the five rules loaded from git | Grafana lists `CI health` and Prometheus lists the five rules. |
| 6 | tests | After a VM restart, `docker start` leaves the Concourse worker crashed (`containerd.sock: connection refused`). The compose file has no restart policy | Run `docker compose up -d --force-recreate concourse` in `concourse/`. The database volume keeps the pipeline. |
| 6 | tests | The Concourse quickstart runs web and worker in one container, so `docker compose stop worker` does not exist | Stopped the `concourse` container. `WorkerMissing` and `ScrapeTargetDown` fired and cleared. |
| 6 | tests | `ArtifactStale` needs a fixed age. The fake age resets at random | `scripts/vm/exporter.sh <seconds>` freezes the age. With no argument it removes the freeze. The alert fired and cleared. |
| 6 | tests | Webhook receiver test | `alertmanager/webhook.yml` and `scripts/vm/webhook-sink.sh` (`nc`). The sink logged a POST from Alertmanager. |
| 6 | tests | `concourse_builds_finished` restarts at 1 after a Concourse restart. A series with no new sample gives `increase() == 0`, so `NoSuccessfulBuild` matches right after a restart. The "time since last success" panel has no data until a job succeeds twice | Not fixed. `ConcourseJobFailing` (3 failures in 1 h with no success) and `NoSuccessfulBuild` (no success in 2 h) were not tested. The fault for the first was running for 20 min. The second needs a 2 h pause. |
| 6 | tests | `promtool` is not on the host | Checked each rule expression with the Prometheus query API. |
