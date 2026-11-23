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
| 3 | 4 | Image pulls took 5 minutes or more. The VPN to `REDACTED-HOST` routes all host traffic and the speed fell to 1 MiB/s or less | None. Wait for the pulls. |
| 3 | 5, 6 | None | All 8 apps `active`. Grafana is at `http://10.69.190.128/cos-lite-grafana`. The host check showed the Prometheus, Loki and Alertmanager data sources. |
