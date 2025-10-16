# Red-Team Exercise Stub

Purpose: Run safety drills in a non-production shard to validate gates, watcher checks, and incident runbooks.

Scenarios
- Missing approvals on protected orders
- Abnormal rate spikes
- Schema violations (missing owner/timestamp)
- Gameplay exploit probes (griefing, infinite farm, pay-to-win)

Run
- `pwsh -NoProfile -File tools/ci/red_team/simulate.ps1`
  - Seeds exchange items to exercise watcher and policy gates
  - See `scenarios/` for manual gameplay test checklists
