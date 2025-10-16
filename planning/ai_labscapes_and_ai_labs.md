# 🧪 ai_labscapes_and_ai_labs.md — AI Labscapes & Labs Guide  
*Frontline Handbook — `high_command_ai_0/planning/`*
---
## 🌍 Purpose
Defines the AI Labscape and its Labs so squads share a clear model of how hypotheses, prototypes, and field drills interlock across the lattice (Alfa → Juliett). Complements battlefield and war‑room guides without duplicating them.
---
## 📚 Core Definitions
- AI Lab (Alfa): A 1×1 cell running a concrete hypothesis as a playable micro‑experiment (code + config + telemetry).
- AI Labscape: A themed collection of Labs arranged on the lattice (e.g., Golf 16×16 = 256; Juliett 64×64 = 4,096).
- Battlefield (Field Alfa): A Lab oriented to action/emergence under live drills (see `planning/field_workspaces.md`).
- War‑Room (HQ Alfa): A Lab oriented to deliberation/doctrine drafting (see `planning/high_command.md`).
- Mind/Dreamscapes: Concept terrains that inspire Lab design (see `planning/mindscapes_and_dreamscapes.md`).
---
## 🧭 Labscape Geometry
- Alfa: 1×1 — single Lab.
- Golf: 16×16 = 256 Labs — pilot scale for stable loops.
- Four Golfs: ~1,000 Labs — diversified pilots and comparative trials.
- Juliett: 64×64 = 4,096 Labs — full lattice for emergent behaviors.
- Mirrors doctrine: “Alfa 1×1 up to Juliett 64×64” and Phase 3 targets (4,096).
---
## 🔄 Lab Lifecycle (Hypothesis → Archive)
1. Hypothesis: Question, risks, expected signals, exit criteria.
2. Prototype: Mint via Toyfoundry Forge rituals; record build info and manifests.
3. Drill/Trial: Run in field cadence; emit structured telemetry.
4. Roll‑Up: Quilt telemetry into composite exports for review.
5. Deliberation: R&D war‑tables evaluate efficacy, tone, and safety.
6. Decision: Promote, iterate, quarantine (Nightland), or archive with provenance.
Artifacts: `RFC.md`, `experiment.manifest.json`, `risk_notebook.json`, build info, and quilt rollups (see Toyfoundry telemetry exports).
---
## 🧵 Interfaces & Telemetry
- Manufacturing: Use Toyfoundry Forge to mint/upgrade Labs (see `planning/toyfoundry/` scrolls).
- Telemetry: Emit Alfa reports and composite quilt exports (e.g., `.imports/toyfoundry/telemetry/quilt/exports/samples/composite_export.sample.csv`).
- Governance: Route decisions through R&D War‑Tables and the rank structure.
---
## 👥 Roles
- Scientist: Frames hypotheses and evaluation criteria.
- Engineer: Implements prototypes and automation hooks.
- Safety Officer: Rates risk, watches tone/entropy; guards Nightland edges.
- Archivist: Maintains provenance, schemas, reproducibility.
- Squad (Toysoldiers): Exercises the experiment under live cadence.
---
## 🚀 Phased Growth Path
- Phase 1 — 256 Labs: Establish safe loops and reporting.
- Phase 2 — ~1,000 Labs: Diversify trials; compare families and doctrines.
- Phase 3 — 4,096 Labs: Full lattice; enable networked emergence with safeguards.
---
## 🌄 Field Maxim
> Keep the Labscape reproducible and the Labs speaking; emergence stays safe and legible across the lattice.
## Safety Notes (valiant_citadel_ai_0)

Linkage
- Policies: `policies/policy_engine.md` (change-as-order, approvals, rate caps), `policies/agent_registry.md` (capability leases), `policies/kill_switch.md` (lab kill-switch + dual-key re-enable)
- Runbooks: `tools/runbooks/incident_freeze.md`, `tools/runbooks/incident_rollback.md`
- Exchange: `exchange/interfaces.md` (orders/reports/acks); schemas under `exchange/schemas/`

Lab Safety Scope
- Use a dedicated safety shard for simulations/red-team; never run drills on live lanes.
- All experiments must be reproducible (seeded runs, build_info, manifests) and emit structured telemetry.
- Dataset governance: no PII; license checks required; attach provenance in `experiment.manifest.json`.
- Agents run under capability leases with explicit scope and expiry; revocations via `safety_policy_update`.

Gates & Acceptance
- Required fields: `owner`, `timestamp`, `id`, `type` (validated by watcher and schemas)
- Protected orders (freeze/rollback/policy) require dual-key approvals
- Rollout path: lab → canary → production with rollback option verified

Operationalization
- Represent risky changes as exchange orders; watcher enforces approvals/rates; validator blocks missing runbooks/policies.
- Use red-team stub `tools/ci/red_team/simulate.ps1` to exercise gates safely.

*End of Scroll - `ai_labscapes_and_ai_labs.md`*
