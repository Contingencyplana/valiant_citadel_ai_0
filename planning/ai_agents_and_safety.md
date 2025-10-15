# AI Agents, Roles, and Safety

Principles
- Constitutional rules: no harm, consent, fairness.
- Least privilege: scoped capabilities and expiry.
- Dual-key approvals for elevated actions.
- Transparent logs and reproducibility.

Roles
- Author: drafts proposals/patches.
- Reviewer: code/content review, checks risk.
- Safety Officer: validates safety gates, can freeze/rollback.
- Release Steward: executes canary/GA after gates pass.

Capability Caps (examples)
- Rate: N actions/minute; Scope: limited directories or rituals.
- Data: size limits; Environment: sandbox-only unless approved.

Approval Chains
- Normal: Author → Reviewer → Steward
- Elevated: Author → Reviewer → Safety Officer → Steward

Enforcement
- Pre-commit and CI hooks enforce gates.
- Audit trail via exchange orders/acks/reports.
- Kill-switch and throttling for anomalies.

## Safety Notes (valiant_citadel_ai_0)

Linkage
- Policies: see `policies/agent_registry.md` for agent identities, capabilities, and leases.
- Gates: see `policies/policy_engine.md` for dual-key approvals and role/authority caps.
- Runbooks: `tools/runbooks/incident_freeze.md`, `incident_rollback.md` for response.

Acceptance Gates
- Pre-commit validator enforces presence of policies/runbooks and kill-switch mention.
- Safety watcher flags missing dual approvals on `safety_freeze` and abnormal rates.

Operationalization
- Elevated actions require two distinct approvers recorded in exchange payloads.
- Capabilities must include explicit scope and expiry (leases); revocation supported via policy update.
- All significant changes go through “change-as-order” with gates in the exchange.
