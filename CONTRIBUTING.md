## Commits

Write commit messages in [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/) format: `<type>(<scope>)!: <description>`.

Refer to the issue in the commit footer:

- `Refs: #N` for a commit that works on issue N.
- `Fixes #N` or `Closes #N` for the commit that completes issue N.

`docs`, `chore`, `ci`, `build`, `style`, and `revert` commits can have no issue footer. Write a revert as `revert: <header of the reverted commit>`, not as the default `Revert "..."` message of git.

## Branches

Name a branch `<type>/<issue>-<slug>`, for example `feat/123-add-login`. `<type>` is a Conventional Commits type.

## Git hooks

[pre-commit](https://pre-commit.com/) scans the staged changes for secrets and checks the commit header and the issue footer. Install pre-commit, then run this command once in each clone:

```bash
pre-commit install
```
