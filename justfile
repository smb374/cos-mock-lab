# Recipes marked "in VM" run inside the cos-mock VM (see docs/setup.md).
vm := "cos-mock"
cpus := "6"
memory := "12G"
disk := "60G"

default:
    @just --list

# Launch the lab VM (plan stage 1).
vm-up:
    multipass launch 24.04 --name {{vm}} --cpus {{cpus}} --memory {{memory}} --disk {{disk}}

vm-shell:
    multipass shell {{vm}}

vm-ip:
    multipass info {{vm}}

# Snapshot needs a stopped VM; the VM restarts after.
vm-snapshot name:
    multipass stop {{vm}}
    multipass snapshot {{vm}} --name {{name}}
    multipass start {{vm}}

vm-down:
    multipass delete --purge {{vm}}

# In VM: deploy COS Lite (plan stage 3).
tf-apply:
    terraform -chdir=terraform init
    terraform -chdir=terraform apply -var="model=cos-lite"

# In VM: start or stop mock Concourse (plan stage 4).
ci-up:
    docker compose -f concourse/docker-compose.yml up -d

ci-down:
    docker compose -f concourse/docker-compose.yml down

# In VM: run the fake signal exporter (plan stage 5).
exporter:
    uv run exporter/exporter.py

lint:
    ruff check
    ruff format --check

fmt:
    ruff format
    ruff check --fix

check:
    pre-commit run --all-files
