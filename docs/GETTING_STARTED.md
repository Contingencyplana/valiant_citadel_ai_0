# Getting Started

- Set Git hooks path:
  - `git config core.hooksPath .githooks`
- Commit workflow:
  - The pre-commit hook runs `tools/ci/validate_safety_repo.ps1`
- Run the local safety watcher:
  - `pwsh -NoProfile -File tools/ci/safety_watcher.ps1`
  - Reads config from `policies/safety_config.yaml` (falls back to JSON mirror)

Artifacts
- Exchange interfaces: `exchange/interfaces.md`
- Templates: `exchange/templates/`
- Runbooks: `tools/runbooks/`
- Policies: `policies/`

Utilities
- Generate outbox items with stamped IDs/timestamps:
  - YAML/JSON config driven approvals: `tools/ci/new_exchange_item.ps1`
  - Example (PowerShell):
    - `pwsh -NoProfile -File tools/ci/new_exchange_item.ps1 -Type safety_onboarding_ack -FieldsJson '{"ack":{"message":"hello"}}'`
    - `pwsh -NoProfile -File tools/ci/new_exchange_item.ps1 -Type safety_policy_update -Approver A1,B2 -FieldsJson '{"policy":"update"}'`
