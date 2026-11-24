# Sourced by the other scripts in scripts/vm/. Sets VM_ADDR to the VM address on eth0.
VM_ADDR=$(ip -4 -o addr show eth0 | awk '{print $4}' | cut -d/ -f1)
export VM_ADDR
