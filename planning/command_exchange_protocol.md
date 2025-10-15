# ≡ƒ¢░∩╕Å command_exchange_protocol.md ΓÇö High Command & Toyfoundry Signal Network

*Doctrine Scroll ΓÇö `high_command_ai_0/planning/`*

---

## ≡ƒîì Purpose

Codifies the shared communications substrate that links High Command (`high_command_ai_0`), Toyfoundry manufacturing workspaces (`toyfoundry_ai_*`), and all field workspaces (e.g., `toysoldiers_ai_*`). Defines directory structure, message lifecycles, and JSON schemas so every order, report, and acknowledgement remains traceable, auditable, and production-ready.

---

## ≡ƒ¢á∩╕Å 1. Transport Layer

| Layer | Current Implementation | Upgrade Path | Notes |
|-------|------------------------|--------------|-------|
| Storage | Dedicated git repository `high_command_exchange` mounted by every workspace | Object store or secure document DB | Keeps manufacturing orders/reports immutable and auditable. |
| Access | Git submodule or checkout at `exchange/` inside each workspace | Dedicated sync daemon or API client | Allows offline work with eventual sync across doctrine, manufacturing, and field theatres. |
| Auth | GitHub SSH/HTTPS credentials | Secrets broker or service principal | Same credentials as doctrine repos for now. |
| Telemetry | `tools/exchange_watcher.py` (local polling utility) | Push-based notification service | Provides lightweight automation for detecting new manufacturing orders, batch reports, and field artefacts. |

**Directory Layout (`exchange/`)**

```plaintext
exchange/
 Γö£ΓöÇ orders/
 Γöé   Γö£ΓöÇ pending/
 Γöé   ΓööΓöÇ dispatched/
 Γö£ΓöÇ reports/
 Γöé   Γö£ΓöÇ inbox/
 Γöé   ΓööΓöÇ archived/
 Γö£ΓöÇ acknowledgements/
 Γöé   Γö£ΓöÇ pending/
 Γöé   ΓööΓöÇ logged/
 ΓööΓöÇ ledger/
     Γö£ΓöÇ journal.md
     ΓööΓöÇ index.json
```

- `orders/` holds outbound directives from High Command.

## Safety Notes (valiant_citadel_ai_0)

Message Types → Gates
- Orders: `safety_freeze`, `safety_rollback`, `safety_policy_update` require dual-key approvals; schema and DQ checks enforced.
- Reports: `safety_incident_report`, `safety_postmortem`, `safety_readiness` must include `owner`, `id`, `timestamp`.

Operationalization
- All risky changes must ship as “change-as-order” through the exchange; acceptance gates block until approvals present.
- Gate definitions live in `policies/policy_engine.md`; kill-switch protocol in `policies/kill_switch.md`.

Acceptance Checks
- Watcher validates approvals for protected orders and flags abnormal `rate` or missing fields.
- Validator ensures runbooks/policies are present and README documents kill-switch.
- `reports/` stores manufacturing and field submissions awaiting review plus long-term archive.
- `acknowledgements/` tracks delivery confirmations to prevent silent loops.
- `ledger/` keeps a rolling human-auditable summary and machine index.

≡ƒôî *Version Control:* The `exchange/` directory is initialized as its own git repository so it can be promoted to the shared `high_command_exchange` submodule. Each workspace ΓÇö doctrine, manufacturing, or field ΓÇö should add a remote and synchronize this repo independently of the doctrine codebase.

---

## ≡ƒº╛ 2. Message Schemas

All payloads are versioned JSON documents encoded in UTF-8, newline-terminated. Keys use `snake_case`. Timestamps are ISO 8601 UTC.

### 2.1 Order Schema (`orders/pending/*.json`)

```json
{
  "schema": "high-command-order@1.0",
  "order_id": "order-2025-10-12-001",
  "issued_by": "high_command_ai_0",
  "target": "toysoldiers_ai_0",
  "priority": "standard",
  "timestamp_issued": "2025-10-12T16:20:00Z",
  "summary": "Initialize git repository and confirm readiness",
  "directives": [
    {
      "step": 1,
      "action": "run_command",
      "command": "git init",
      "notes": "Execute at workspace root"
    }
  ],
  "dependencies": [],
  "requires_ack": true,
  "expires_at": "2025-10-15T00:00:00Z",
  "attachments": [
    {
      "type": "markdown",
      "path": "attachments/setup_notes.md"
    }
  ]
}
```

Valid `priority` values: `standard`, `urgent`, `hold`. Orders move from `pending/` to `dispatched/` after receipt is logged.

### 2.2 Report Schema (`reports/inbox/*.json`)

```json
{
  "schema": "field-report@1.0",
  "report_id": "report-2025-10-12-017",
  "origin": "toysoldiers_ai_0",
  "relates_to": "order-2025-10-12-001",
  "timestamp_submitted": "2025-10-12T16:35:00Z",
  "status": "completed",
  "summary": "Repository initialized with .gitignore staged",
  "metrics": {
    "execution_time_s": 45,
    "files_touched": 2,
    "entropy_index": 0.12
  },
  "artifacts": [
    {
      "type": "git_status",
      "path": "artifacts/git_status.txt"
    }
  ],
  "follow_up": [
    {
      "suggestion": "Define shared .gitignore template",
      "priority": "standard"
    }
  ]
}
```

`status` values: `completed`, `blocked`, `partial`, `aborted`.

### 2.3 Acknowledgement Schema (`acknowledgements/pending/*.json`)

```json
{
  "schema": "signal-ack@1.0",
  "ack_id": "ack-2025-10-12-003",
  "referenced_id": "order-2025-10-12-001",
  "sender": "toysoldiers_ai_0",
  "receiver": "high_command_ai_0",
  "timestamp_sent": "2025-10-12T16:21:30Z",
  "status": "received",
  "notes": "Order queued for execution"
}
```

Valid `status` values: `received`, `in-progress`, `completed`, `declined`.

---

## ≡ƒöä 3. Message Lifecycle

1. **Draft** ΓÇö High Command composes JSON order with unique `order_id` targeting Toyfoundry or field recipients.
2. **Commit** ΓÇö Order placed in `orders/pending/` and committed to exchange repo.
3. **Sync** ΓÇö Field workspace pulls exchange repo, reads new orders.
4. **Acknowledge** ΓÇö Field posts `signal-ack@1.0`; order moves to `dispatched/`.
5. **Execute** ΓÇö Manufacturing or field unit carries out directives, logs artifacts.
6. **Report** ΓÇö Manufacturing units submit production telemetry (`field-report@1.0` or factory variant) and field units return deployment feedback; High Command reviews and moves report to `reports/archived/`.
7. **Close-Out** ΓÇö High Command issues closure note in `ledger/journal.md` and updates `ledger/index.json`.

≡ƒôí *Automation Hook:* Field workspaces should run `python -m tools.exchange_watcher --watch` (or equivalent scheduling) so new orders, pending acknowledgements, and inbox reports surface immediately without manual polling.

Every state transition must leave a git commit trail for full auditability.

---

## ≡ƒôÜ 4. Indexing & Retrieval

`ledger/index.json` contains a compact manifest for fast lookups:

```json
{
  "version": "1.0.0",
  "orders": {
    "order-2025-10-12-003": {
      "status": "closed",
      "order_path": "orders/dispatched/order-2025-10-12-003.json",
      "ack_path": "acknowledgements/logged/order-2025-10-12-003-ack.json",
      "report_path": "reports/archived/order-2025-10-12-003-report.json"
    }
  },
  "acks": {
    "order-2025-10-12-003-ack": "acknowledgements/logged/order-2025-10-12-003-ack.json"
  },
  "reports": {
    "order-2025-10-12-003-report": "reports/archived/order-2025-10-12-003-report.json"
  }
}
```

Automation scripts should regenerate the index after each sync to guarantee references are current.

---

## ≡ƒ¢í∩╕Å 5. Governance

- **Unique IDs:** All message IDs are deterministic: `type-YYYY-MM-DD-###`.
- **Time Discipline:** Clocks sync via UTC; drift beyond 5 seconds triggers warning.
- **Human Checkpoint:** Orders with `priority = urgent` require human sign-off recorded in `ledger/journal.md`.
- **Retention:** Reports stay in `archived/` indefinitely; attachments may be pruned via rolling hash audit after 90 days.
- **Encryption (Future):** When secrets emerge, encapsulate attachments with workspace-specific keys and store only fingerprints in the exchange repo.
- **Governance Collateral:** Every workspace interacting with the exchange must surface `LICENSE`, `CODE_OF_CONDUCT.md`, and `CONTRIBUTING.md` aligned with High CommandΓÇÖs templates; include links in `exchange/README.md`.

---

## ∩┐╜ 6. Automation Aides

- **Exchange Watcher (`tools/exchange_watcher.py`):** Polls the exchange tree, tracks the last-seen snapshot, and prints new orders, pending acknowledgements, and inbox reports. Supports one-shot checks or continuous monitoring via `--watch`.
- **Schema Validator (`tools/schema_validator.py`):** Validates payloads against canonical schemas prior to commit; integrate into CI or pre-commit flows.
- **Forge Logs:** Events recorded in `logs/forge.log` provide cross-reference between doctrine automation and exchange activity.

---

## ≡ƒÜÇ 7. Immediate Tasks

1. **Deploy exchange watcher scheduling** ΓÇö Embed the watcher in each manufacturing and field workspace (cron, scheduled task, or daemon) so operators receive near-real-time order prompts.
2. **Maintain governance parity** ΓÇö Whenever doctrine evolves (licenses, conduct, contribution flow), issue orders to downstream workspaces and log completion in the ledger.
3. **Plan Toyfoundry integration** ΓÇö Define manufacturing pipeline requirements and map how Toyfoundry will consume exchange directives, report production telemetry, and ship certified batches to toysoldiers.

With these actions, High Command and field theatres operate from a shared doctrine, automated alerting, and evolving strategic roadmap.

---

## See Also

- Daylands Charter and Safety Checklist: `planning/daylands_and_nightlands.md:1`
- In-Game Pipeline and Gates: `planning/internal_alfa_architecture.md:2`
- AI Agents and Safety: `planning/ai_agents_and_safety.md:1`
- Safety Gate Template: `planning/templates/safety_gate_template.md:1`
- Change-as-Order Templates:
  - Order: `exchange/orders/templates/change-order.template.json:1`
  - Acknowledgement: `exchange/acknowledgements/templates/change-ack.template.json:1`
  - Report: `exchange/reports/templates/change-report.template.json:1`
- Lanes Config Sample: `tools/telemetry/canary_sandbox.sample.json:1`
