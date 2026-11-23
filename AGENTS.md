# cos-mock-lab

## Commands

- Format: just fmt
- Lint: just lint
- Check: just check

## Plan

Follow `docs/plan.md`. Rules for the executor:

- Run each command and read its output before the next step.
- Do not claim a step is done before its check passes.
- Use only a strict MicroK8s channel. `juju bootstrap` fails on the classic channel.
- Log each failed step and its fix in `lab-log.md`.

## Agent skills

### Issue tracker

Issues live in GitHub Issues (smb374/cos-mock-lab), via the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Issue types

Each issue has one `type:*` label and a matching title prefix: `[Epic]`, `[Bug]`, `[Feature]`, `[Task]`, `[Ticket]`. Wayfinder child issues have no `type:*` label and use `[WF]`. See `docs/agents/issue-types.md`.

### Triage labels

Default five-label vocabulary (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: one `GLOSSARY.md` and `docs/adr/` at the repo root. See `docs/agents/domain.md`.

### Commits

Conventional Commits with an issue footer (`Refs: #N`, `Fixes #N`). See `CONTRIBUTING.md`.