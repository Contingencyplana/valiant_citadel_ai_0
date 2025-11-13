# valiant_citadel_ai_0 – Runbook (v1)

Purpose: operate the safety citadel for all Genesis workspaces by keeping kill-switch tooling, monitoring, and emergency communications active around the clock.

Core Objectives
- Keep `python -m tools.ops_readiness` green before acknowledging or issuing any safety directive.
- Audit every exchange artifact for safety posture (orders, acknowledgements, reports) and mirror results into `exchange/ledger/index.json`.
- Maintain 24/7 alerting on kill-switch systems, dual-key approvals, and the Nightlands monitoring grid.
- Publish clear response notes for High Command, Toyfoundry, Toysoldiers, and R&D whenever a safety issue is opened or closed.

Operator Loop (per session)
1. **Heartbeat** – Run readiness; unblock missing docs or staged metadata immediately. Confirm hub path matches `C:\Users\Admin\high_command_exchange`.
2. **Intake** – Pull the latest exchange payloads; inspect `exchange/orders/dispatched/` and reconcile with the ledger.
3. **Audit** – Review staged orders/reports and validate kill-switch + monitoring hooks (golf_00–golf_03 directories). Document findings in `planning/safety_board/`.
4. **Respond** – Update policies or emergency procedures as needed, file reports in `outbox/reports/`, and pair acknowledgements for each handled order.
5. **Sync** – Rerun readiness, then `python tools/exchange_all.py` to push new artifacts. Verify `logs/exchange_all.json` records the run.
6. **Signal** – Post safety status (green/yellow/red) plus key notes in `planning/change_log.md` or via High Command if escalation is required.

Safety Gates
- **Documentation** – This runbook, `README.md`, and `policies/README.md` must exist and be current before declaring “green.”
- **Kill-switch Readiness** – `golf_00/delta_00/kill_switch/` configs must include timestamps <24h old.
- **Incident Digest** – Latest entry under `docs/emergency/incident_digest.md` should reference the current date cycle.
- **Ledger** – Every outbound order/report gets a line in `exchange/ledger/index.json` referencing evidence, kill-switch coverage, and sign-off.

Evidence & Logging
- Readiness: `logs/ops_readiness.json`
- Exchange pushes: `logs/exchange_all.json`
- Safety notes: `policies/`, `docs/emergency/`
- Ledger + attachments: `exchange/ledger/`, `exchange/attachments/`

Escalation
1. Trigger local kill-switch (document in `docs/emergency/README.md`).
2. Page High Command duty officer.
3. Notify Toyfoundry/Toysoldiers leads when manufacturing or field operations are affected.

References
- `README.md`
- `policies/README.md`
- `docs/emergency/`
- `golf_00`–`golf_03` safety architecture READMEs
- `new_major_pivots/` (esp. pivot five emoji safety cues)
