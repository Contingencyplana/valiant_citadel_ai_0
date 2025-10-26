# Pivot Five Monitoring Hooks

## Purpose

Provide Valiant Citadel with actionable monitoring guidance for the emoji-first computing language rollout. These hooks ensure every `factory-order@1.0` payload remains in lockstep with narration delivery and that schema drift is surfaced to High Command immediately.

## Hook Catalog

1. **Schema Guard (`schema_guard`)**  
   Watches translator output for schema drift against the `factory-order@1.0` contract.
   - Validate payloads with JSON Schema + custom glyph lexicon checks.
   - Emit `schema_guard.alert` events when new fields, missing fields, or reordered chains are detected.
   - Persist last-known-good schema hash in `logs/guardrail_audit/schema_guard.state` for comparison.

2. **Narrator Usage Logger (`narrator_log`)**  
   Captures narrator persona, locale, and audio asset identifiers for every narration playback.
   - Append structured entries to `logs/guardrail_audit/narrator_usage.log`.
   - Expose metrics (`narrator_invocations_total`, `narrator_locale_mismatch_total`).
   - Flag missing or fallback narrations with severity `warning`.

3. **Glyph/VO Auditor (`glyph_vo_audit`)**  
   Correlates glyph chains with delivered narration text.
   - Compare payload `summary` with narrated transcript; enforce equality unless override flag present.
   - Highlight cadence mismatches (glyph count vs. spoken beats) in `logs/guardrail_audit/glyph_vo_discrepancies.log`.
   - Raise High Command alert with payload excerpt when discrepancy repeats more than twice within 24 hours.

## Data Collection Pipeline

| Source | Hook | Storage | Retention |
| --- | --- | --- | --- |
| Translator export (`exchange/outbox`) | Schema Guard | `logs/guardrail_audit/schema_guard.log` | 30 days |
| Narration playback bus | Narrator Usage Logger | `logs/guardrail_audit/narrator_usage.log` | 14 days |
| VO transcript service | Glyph/VO Auditor | `logs/guardrail_audit/glyph_vo_discrepancies.log` | 30 days |

## Alerting Rules

- **Critical:** Schema drift or glyph mismatch persists for 3 consecutive payloads.
- **High:** Narrator fallback voice triggered more than 2 times per hour.
- **Medium:** Payload summary diverges from narration copy once; requires manual review.
- **Low:** Locale metadata missing; auto-ticket filed for localization follow-up.

Alerts route to:

- `#citadel-alerts` (internal)
- `#high-command-ops` (external escalation)

## Implementation Steps

1. Deploy hook scripts under `tools/monitoring/` (create `schema_guard.py`, `narrator_log.py`, `glyph_vo_audit.py`).
2. Register hooks in `tools/ci/safety_watcher.ps1` execution chain.
3. Configure log rotation via `logs/guardrail_audit/.config/rotation.json` (new file if absent).
4. Add Prometheus exporters for hook metrics (`tools/monitoring/exporters/pivot_five_metrics.py`).
5. Update incident runbooks to reference new log paths and escalation thresholds.

## Validation Checklist

- [ ] Replay archived emoji payloads (Order-032 to Order-036) and confirm zero schema drift alerts.
- [ ] Trigger sample narrator playback across War Office herald + frontline correspondent voices.
- [ ] Inject deliberate glyph summary mismatch and verify alert propagation to High Command.
- [ ] Confirm metrics appear in Grafana dashboard `Citadel ▸ Pivot Five Hooks`.

## Reporting

- Include hook status in daily `safety_watcher` summary.
- File weekly report to High Command documenting alert counts, false positives, and remediation timelines.
- Annotate `quint_synced/README.md` once downstream workspaces deploy identical hooks.

## Version Control

**Version:** 1.0  
**Last Updated:** 2025-10-26  
**Next Review:** 2025-11-26
