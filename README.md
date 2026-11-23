# cos-mock-lab

COS stack mocking lab with Juju + MicroK8S + ConcourseCI.

The plan is in [docs/plan.md](docs/plan.md). Run `just` to list the common recipes.

## Dev tools

These tools are for working on this repo. They do not include the lab environment (see [docs/setup.md](docs/setup.md)).

- **Nix users:** run `direnv allow`. `flake.nix` provides all the tools.
- **Other users:** install these tools yourself.

| Tool | Use |
| --- | --- |
| [just](https://github.com/casey/just) | Run the recipes in `justfile` |
| [ruff](https://docs.astral.sh/ruff/) | Format and lint Python |
| [shellcheck](https://www.shellcheck.net/) | Lint shell scripts |
| [pre-commit](https://pre-commit.com/) | Commit hooks (`pre-commit install`) |
| [gh](https://cli.github.com/) | GitHub CLI |
| [jq](https://jqlang.github.io/jq/) | JSON in shell commands |
| [OpenTofu](https://opentofu.org/) | Format Terraform files locally (the VM runs Terraform) |
| [tflint](https://github.com/terraform-linters/tflint) | Lint Terraform files |