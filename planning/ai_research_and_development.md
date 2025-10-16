# 🧫 ai_research_and_development.md — AI R&D Doctrine  
*Frontline Handbook — `high_command_ai_0/planning/`*
---
## 🎯 Purpose
Establishes how R&D operates across the lattice: how ideas are proposed, prototyped, trialed, measured, and either promoted or retired with safety and provenance.
---
## 🧩 R&D Cells (War‑Tables)
- Location: High Command war‑rooms host an **R&D** table (see `planning/war_rooms_and_war_tables.md`).
- Mission: Turn field signals into hypotheses and doctrine updates without breaking cadence or tone.
- Interface: Pair each R&D table with Field Alfas running drills (see `planning/field_workspaces.md`).
---
## 🔧 Operating Model
1) Intake & Triage: Capture proposals with hypothesis, risks, evaluation metrics, and expected signals.
2) Design Review (RFC): Lightweight RFC with scope, safety notes (Dayland/Nightland), exit criteria.
3) Prototype & Manufacturing: Use Toyfoundry Forge to mint versioned builds with manifests and build info.
4) Trial Execution: Schedule drills; run limited ticks; collect structured telemetry.
5) Telemetry & Loom: Roll up via quilt looms into composite exports for comparative analysis.
6) Deliberation & Decision: R&D tables review efficacy, tone, and risk; decide Promote / Iterate / Quarantine / Archive.
7) Promotion & Doctrine: Emit doctrine update or order; wire into automation; record provenance.
---
## 📦 Standard Artifacts
- `RFC.md` — intent, scope, risks, exit criteria.
- `experiment.manifest.json` — parameters, inputs, outputs, versioning.
- `risk_notebook.json` — hazards, mitigations, checkpoints.
- `build_info.json` — commit, timestamp, forge recipe, reproducibility hash.
- `run_logs.jsonl` — trial events; Alfa reports.
- Quilt rollups — composite CSV/JSON exports (e.g., `.imports/toyfoundry/telemetry/quilt/exports/samples/composite_export.sample.csv`).
- `decision_memo.md` — R&D verdict and next actions.
---
## 🛡️ Governance & Safety
- Lattice Alignment: Mirror rank and lattice structure (see `planning/rank_structure.md`, `planning/high_command.md`).
- Tone & Entropy: Monitor Daylands/Nightlands thresholds (see `planning/daylands_and_nightlands.md`).
- Dark Signs: Use `planning/heart_of_darkness.md` checks during trials; pause on flags.
- Containment: Quarantine Nightland Alfas; never delete—repair or archive with notes.
---
## 📊 Metrics & Signals (examples)
- `entropy_index`, morale/tonal indicators, terrain balance.
- success/defect rates, stability across ticks, emergence notes.
- build provenance coverage and schema compliance.
---
## 🚀 Phased Capacity
- Phase 1 — 256 trials (1 Golf): Validate loops, schemas, and tone management.
- Phase 2 — ~1,000 trials (4 Golfs): Comparative experiments; cross‑family coordination.
- Phase 3 — 4,096 trials (Juliett): Networked emergence with strong safeguards and automation.
---
## 🌄 Field Maxim
> R&D advances only as fast as safety, clarity, and provenance allow—measure twice, trial once, promote when rhythm holds.
## Safety Notes (valiant_citadel_ai_0)

Linkage
- Policies: `policies/policy_engine.md` (change-as-order, approvals, rate caps), `policies/agent_registry.md` (model/agent registry, leases), `policies/kill_switch.md`
- Runbooks: `tools/runbooks/incident_freeze.md`, `tools/runbooks/incident_rollback.md`
- Exchange: `exchange/interfaces.md` and schemas under `exchange/schemas/`

Experiment Governance
- Proposals include risks, safety gates, exit criteria; all risky changes ship as exchange orders.
- Experiments run in safety shard; red-team drills never touch live lanes.
- Datasets: PII banned, license checks mandatory, provenance recorded in manifests.
- Capabilities leased per agent/model with scope/expiry; revocation via policy update.

Gates & Rollout
- Required fields enforced by watcher (owner, timestamp, id, type) with legacy grace until cutoff.
- Protected orders require dual-key approvals; canary rollout before promotion.
- Rollback path validated; freeze procedure ready if dark signs appear.

Operationalization
- Use schemas + watcher to block malformed messages; validator ensures runbooks/policies remain present and current.
- Readiness reports include status and links to governing policies.

*End of Scroll - `ai_research_and_development.md`*
