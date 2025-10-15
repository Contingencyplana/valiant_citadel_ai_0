# Policies

Safety policy documents governing agents, approvals, and gates.

- `policy_engine.md` — Guardrails and gate definitions
- `agent_registry.md` — Agent identities, capabilities, leases, revocations

## Config Sync (YAML ↔ JSON)

- Source of truth: `safety_config.yaml`
- JSON mirror for environments without YAML support: `safety_config.json`
- To regenerate JSON (PowerShell with YAML cmdlet available):
  - `pwsh -NoProfile -File tools/ci/sync_safety_config.ps1`
  - or one-liner: `Get-Content policies/safety_config.yaml -Raw | ConvertFrom-Yaml | ConvertTo-Json -Depth 8 | Set-Content policies/safety_config.json`
- If `ConvertFrom-Yaml` is unavailable, update the JSON mirror manually to match the YAML.
