# Agent Registry

Tracks AI agents, capabilities, leases, and revocations.

Registry Fields (suggested)
- `agent_id`: unique ID
- `display_name`: human-friendly name
- `capabilities`: list of verbs/resources
- `lease`: start/end validity
- `owner`: accountable human/team
- `revoked`: boolean + reason

Operations
- Provision: add agent with bounded capabilities and lease
- Update: adjust capabilities via `safety_policy_update`
- Revoke: immediate disable with cause and exchange note
