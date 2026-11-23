# vm-* recipes run on the host. Scripts in scripts/vm/ run inside the VM
# through the repo mount; start them with: just vm-run <script> [args]
vm := "cos-mock"
vm_repo := "/home/ubuntu/cos-mock-lab"
cpus := "6"
memory := "12G"
disk := "60G"

default:
    @just --list

# Launch the lab VM (plan stage 1).
vm-up:
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

vm-down:
    multipass delete --purge {{vm}}

# Run scripts/vm/<script>.sh in the VM, e.g. just vm-run tf-apply (plan stages 3-5).
vm-run script *args:
    multipass exec {{vm}} -- {{vm_repo}}/scripts/vm/{{script}}.sh {{args}}

lint:
    ruff check
    ruff format --check

fmt:
    ruff format
    ruff check --fix

check:
    pre-commit run --all-files