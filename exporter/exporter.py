# /// script
# requires-python = ">=3.12"
# dependencies = ["prometheus-client"]
# ///
"""Fake Swift, Launchpad and GitHub signals for docs/plan.md stage 5."""

import random
import os
import time

from prometheus_client import Gauge, start_http_server

PORT = 9400
TICK_SECONDS = 5

# Set LAB_FROZEN_AGE_SECONDS to pin every artifact age, for the ArtifactStale test.
FROZEN_AGE = os.environ.get("LAB_FROZEN_AGE_SECONDS")

# Stage 6 changes these values to trigger the alerts.
STATE = {
    "swift_artifact_age_seconds": {"ubuntu-server": 0.0, "ubuntu-core": 0.0},
    "lp_build_state": {"ubuntu-server": 1, "ubuntu-core": 1},
    "github_run_state": {"build-image": 1, "publish": 1},
}

swift_age = Gauge("lab_swift_artifact_age_seconds", "Age of the artifact", ["artifact"])
lp_state = Gauge(
    "lab_lp_build_state", "Launchpad livefs build state, 0 or 1", ["livefs"]
)
gh_state = Gauge(
    "lab_github_run_state", "GitHub workflow run state, 0 or 1", ["workflow"]
)


def tick() -> None:
    ages = STATE["swift_artifact_age_seconds"]
    for name in ages:
        if FROZEN_AGE is not None:
            ages[name] = float(FROZEN_AGE)
            swift_age.labels(artifact=name).set(ages[name])
            continue
        # Reset at random times, about once every 10 minutes per artifact.
        ages[name] = (
            0.0 if random.random() < TICK_SECONDS / 600 else ages[name] + TICK_SECONDS
        )
        swift_age.labels(artifact=name).set(ages[name])
    for key, gauge, label in (
        ("lp_build_state", lp_state, "livefs"),
        ("github_run_state", gh_state, "workflow"),
    ):
        for name in STATE[key]:
            STATE[key][name] = random.randint(0, 1)
            gauge.labels(**{label: name}).set(STATE[key][name])


if __name__ == "__main__":
    start_http_server(PORT)
    while True:
        tick()
        time.sleep(TICK_SECONDS)
