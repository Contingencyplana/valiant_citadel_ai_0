# Incident Digest

## 2025-11-17 - Daily Doc Refresh

- **Status:** Green. No safety incidents; Alfa M01 hydration for Order `order-2025-11-14-055` completed locally with readiness + smoke evidence logged in `logs/ops_readiness.json` and `production/mass_alfa_batch1/alfa_m01/telemetry.json`.
- **Focus:** Daily Doc Refresh sweep to keep citadel doctrine synced with Toyfoundry's Batch 1 push and the new hydration obligations for Valiant (Delta slot).
- **Actions Logged:**
  - Created hydration evidence set (`production/mass_alfa_batch1/**`, `outbox/acks/order-2025-11-14-055-ack.json`, `outbox/reports/order-2025-11-14-055-report.json`, `outbox/reports/hello-Alfa-M01-20251117T155859Z.json`) and referenced it from `exchange/ledger/index.json`.
  - Refreshed `docs/integration/README.md` to describe the Alfa Batch 1 wiring plus exchange obligations for Toyfoundry <> Valiant <> High Command.
  - Added a Daily Doc Refresh procedure to `RUNBOOK.md` so every session re-validates docs/emergency coverage, ledger entries, and exchange sync before additional orders dispatch.
  - Logged today’s slice inside `planning/change_log.md`.
- **Follow-Up:** Publish the staged ack/report/hello bundle via `python tools/exchange_all.py`, then chase the remaining Batch 1 hydration orders (Delta -> Theta -> Zeta -> Gamma -> Alpha). Update this digest again once remote telemetry arrives or if any incidents occur.
