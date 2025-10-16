# 30/60/90 Roadmap (Safety)

## Day 0–30 (MVP)
- Exchange mirror + pre-commit validator + watcher online
- Define kill-switch procedure and dual-key approvals
- Ship `safety_onboarding_ack` and `safety_readiness` to exchange

## Day 31–60 (Gates & Governance)
- Expand policy engine: role caps, leases, revocation protocol
- Add schema/DQ gates for top 3 message types
- Red-team dry run in safety shard (no live lanes)

## Day 61–90 (Reliability & Drills)
- Canary re-enable protocol after freeze/rollback
- Pager + runbook rehearsal; postmortem quality bar
- Baseline dashboards and anomaly alerts for safety signals

## OKRs (Four Pivotal Fronts)

Front One — Tons of Fun
- KR1: Ship 3 canary balance changes with zero critical exploit regressions.
- KR2: Improve D+7 return rate by +3% in canary cohorts.
- KR3: Complete rollback drill within 10 minutes SLO twice.

Front Two — AI Safety
- KR1: Dual‑key approvals enforced on 100% protected orders.
- KR2: Kill‑switch drill executed successfully within 5 minutes SLO.
- KR3: Zero BLOCKED → published exceptions across 2 consecutive weeks.

Front Three — Documentation
- KR1: 100% new planning docs contain a “Safety Notes (valiant_citadel_ai_0)” section.
- KR2: All exchange message types covered by minimal JSON schemas.
- KR3: Validator guidance documented and discoverable in docs.

Enabler — Operations
- KR1: Pre‑push hook prevents publishing malformed outbox 100% of the time.
- KR2: Watcher daily scans complete with <1% false positives.
- KR3: YAML↔JSON config mirror stays in sync (no drift for 30 days).
