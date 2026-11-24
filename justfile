# vm-* recipes run on the host. Scripts in scripts/vm/ run inside the VM
# through the repo mount; start them with: just vm-run <script> [args]
vm := "cos-mock"
vm_repo := "/home/ubuntu/cos-mock-lab"
cpus := "6"
memory := "12G"
disk := "60G"

default:
    @just --list

# Create the lab VM and mount the repo (plan stage 1).
vm-launch:
    multipass launch 24.04 --name {{vm}} --cpus {{cpus}} --memory {{memory}} --disk {{disk}}
    multipass mount . {{vm}}:{{vm_repo}}

vm-shell:
    multipass shell {{vm}}

vm-ip:
    multipass info {{vm}}

# Snapshot needs a stopped VM; the VM restarts after.
vm-snapshot name:
    multipass stop {{vm}}
    multipass snapshot {{vm}} --name {{name}}
    multipass start {{vm}}

# Delete the VM and all its snapshots. This cannot be undone.
vm-purge:
    multipass delete --purge {{vm}}

vm-up:
    multipass start {{vm}}

vm-down:
    multipass stop {{vm}}

# Run scripts/vm/<script>.sh in the VM, e.g. just vm-run tf-apply (plan stages 3-5).
vm-run script *args:
    multipass exec {{vm}} -- {{vm_repo}}/scripts/vm/{{script}}.sh {{args}}

# Run one shell command in the VM, e.g. just vm-exec 'juju controllers'.
vm-exec cmd:
    multipass exec {{vm}} -- bash -c {{quote(cmd)}}

lint:
    ruff check
    ruff format --check
    tofu fmt -check -recursive terraform
    tflint --chdir terraform

fmt:
    ruff format
    ruff check --fix
    tofu fmt -recursive terraform

check:
    pre-commit run --all-files