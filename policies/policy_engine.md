# Policy Engine

Purpose: Enforce safety gates and decision policies across exchanges and lanes.

Key Policies
- Role/cap caps: Limit authority per role and per time window.
- Dual-key approvals: High-impact orders (freeze/rollback/policy) require 2 distinct approvers.
- Change-as-order: All risky changes must be represented as exchange orders with gates.
- Kill-switch: A global block can be asserted from the safety workspace.

Gates
- Schema & DQ pass for exchanged payloads
- Approvals present for protected orders
- Ledger invariants hold (no duplicate or out-of-order critical events)

Interfaces
- `safety_policy_update` order to add/change policies
- `safety_readiness` report to attest active gate coverage

See also: `policies/kill_switch.md` for disable/reenable protocol and dual-key requirements.
