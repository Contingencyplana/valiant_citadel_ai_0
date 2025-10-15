# Getting Started

- Set Git hooks path:
  - `git config core.hooksPath .githooks`
- Commit workflow:
  - The pre-commit hook runs `tools/ci/validate_safety_repo.ps1`
- Run the local safety watcher:
  - `pwsh -NoProfile -File tools/ci/safety_watcher.ps1`

Artifacts
- Exchange interfaces: `exchange/interfaces.md`
- Templates: `exchange/templates/`
- Runbooks: `tools/runbooks/`
- Policies: `policies/`
