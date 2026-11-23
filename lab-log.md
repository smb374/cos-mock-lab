# Lab log

Record each failed step and its fix. Record each charm config name that differs from the plan.

| Stage | Step | Failure or difference | Fix |
| --- | --- | --- | --- |
| 2 | 1 | Newest strict channel | Used `1.36-strict/stable` (v1.36.2). |
| 2 | 5, 6 | `microk8s enable` fails with "Elevated permissions are needed" on the strict snap | Run it with `sudo`. |
| 2 | 3 | `newgrp` does not carry over between `multipass exec` calls | Not needed: each exec starts a new session with the group. |
| 2 | 9 | None | `juju bootstrap microk8s lab` worked. Controller `lab`, Juju 3.6.29. Snapshot `s2-juju36-bootstrapped` taken. |
