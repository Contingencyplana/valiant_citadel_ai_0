# Exchange Interfaces

Orders
- `safety_freeze`
- `safety_rollback`
- `safety_red_team_exercise`
- `safety_policy_update`

Reports
- `safety_incident_report`
- `safety_postmortem`
- `safety_readiness`

Alerts
- Gate failure → set acceptance to `blocked` and provide remediation notes

Conventions
- JSON or YAML payloads with `type`, `id`, `timestamp`, `owner`, `approvals[]` (as required)
- High-impact orders require dual approvals from distinct approvers
