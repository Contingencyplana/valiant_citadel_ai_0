# Toyfoundry Baseline Snapshot – Batch 1

Toyfoundry froze Forge at `forge-alfa@2025-11-13-054` while issuing `order-2025-11-13-054`. This note records what Valiant verified before hydrating Alfa M01.

## Source Notes
- Tag: `forge-alfa@2025-11-13-054`
- Manifest digest: `sha256:6404c2d85b74dbee3f2af8ca36fbfdb68c3bb98f7f08c3f5e6dfb33db1af7c46`
- Attachments observed: `templates/alfa_mass/v1/`, `ops/smoke_plan.md`, `exchange/hooks/hello_packet.json`

## Validation
1. Compared Toyfoundry manifest to our copy; no drift detected.
2. Matched kill-switch wiring guidance with `golf_00/delta_00/README.md`.
3. Confirmed Delta slot is pinned to Alfa M01 and expects readiness + smoke proof before ledger updates.

## Local Mirror
- Working copy: `production/mass_alfa_batch1/alfa_m01`
- Telemetry: `production/mass_alfa_batch1/alfa_m01/telemetry.json`
- Exchange artefacts: `outbox/reports`

Rehydrate using the same tag if a rebuild is required; do not promote altered bits without Toyfoundry sign-off.
