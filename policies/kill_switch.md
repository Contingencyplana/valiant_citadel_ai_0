# Kill-Switch Protocol

Purpose: Provide a rapid, auditable mechanism to halt risky activity and later re-enable it safely.

States
- `armed`: Kill-switch active and ready to assert blocks.
- `disabled`: Temporarily off with documented reason and approvals.

Disable Procedure (Dual-Key)
1. Propose `safety_policy_update` with field `kill_switch.state: disabled` and `disabled_reason`.
2. Obtain approvals from Safety Lead and Duty Commander (distinct approvers).
3. Commit policy update and broadcast to exchange with `acceptance: blocked` lifted where appropriate.
4. Record in ledger/journal with reference IDs.

Re-enable Procedure (Dual-Key)
1. Propose `safety_policy_update` with `kill_switch.state: armed`.
2. Obtain the same dual approvals.
3. Post readiness check results; confirm gates and watcher are healthy.
4. Gradually re-enable lanes via canary procedure per runbooks.

Local Repo Guard
- Presence of `safety_kill_switch_disabled.flag` will block commits via pre-commit validator.

References
- `policies/safety_config.yaml`
- `tools/runbooks/incident_freeze.md`
- `tools/runbooks/incident_rollback.md`
