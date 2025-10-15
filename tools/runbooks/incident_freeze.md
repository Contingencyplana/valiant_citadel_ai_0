# Incident Freeze Runbook

Goal: Safely halt risky activity and prevent propagation.

- Signal: Raise `safety_freeze` order to the exchange; set acceptance to `blocked`.
- Scope: Define lanes/components to freeze (explicit include list).
- Dual-key: Obtain approvals from Safety Lead + Duty Commander.
- Actions:
  - Disable autonomous jobs and agent leases in affected lanes.
  - Lock deployments and write-protect critical stores.
  - Snapshot current state (artifacts, configs, ledger entries).
- Verification: Confirm no new orders/events emitted from frozen scope.
- Comms: Post `safety_incident_report` with freeze details and owners.

Exit criteria: Root cause bounded + rollback plan prepared.
