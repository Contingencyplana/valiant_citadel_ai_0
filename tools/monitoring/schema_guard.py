#!/usr/bin/env python3
"""Pivot Five schema drift guard.

Validates `factory-order@1.0` payloads emitted by the translator pipeline and
emits structured alerts when the shape or cadence drifts from the documented
contract. The guard persists a baseline signature so that deliberate schema
migrations can be promoted by resetting the saved state after review.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
from collections import deque
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any, Dict, Iterable, List, Tuple

# Required/optional fields driven by docs/quint_synced/payload_alignment.md
REQUIRED_TOP_KEYS = {
    "schema",
    "summary",
    "glyph_chain",
    "intent",
    "telemetry_stub",
}

ALLOWED_OPTIONAL_TOP_KEYS = {
    "order_id",
    "narration",
    "metadata",
    "meta",
    "source",
    "context",
    "links",
    "tags",
    "type",
    "id",
    "timestamp",
    "owner",
}

REQUIRED_INTENT_KEYS = {"actor", "action", "target", "outcome"}
OPTIONAL_INTENT_KEYS = {"qualifiers"}

REQUIRED_TELEMETRY_KEYS = {
    "batch_id",
    "ritual",
    "units_processed",
    "status",
    "duration_ms",
}
OPTIONAL_TELEMETRY_KEYS = {"locale", "warnings", "alert_state"}

STATE_MAX_RECENT = 250
RECENT_RETENTION_HOURS = 48
DEFAULT_STATE = {
    "schema_hash": None,
    "expected_signature": None,
    "recent_batches": {},
}


class GuardLogger:
    """Lightweight JSONL logger that mirrors alerts to stdout."""

    def __init__(self, log_path: Path) -> None:
        self._log_path = log_path
        self._ensure_parent(log_path)

    @staticmethod
    def _ensure_parent(path: Path) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)

    @staticmethod
    def _utc_now() -> str:
        return datetime.now(timezone.utc).isoformat()

    def emit(self, level: str, message: str, *, order_id: str | None = None,
             batch_id: str | None = None, code: str | None = None,
             details: Dict[str, Any] | None = None) -> None:
        record = {
            "timestamp": self._utc_now(),
            "level": level,
            "message": message,
        }
        if order_id:
            record["order_id"] = order_id
        if batch_id:
            record["batch_id"] = batch_id
        if code:
            record["code"] = code
        if details:
            record["details"] = details
        line = json.dumps(record, separators=(",", ":"))
        with self._log_path.open("a", encoding="utf-8") as fh:
            fh.write(line + "\n")
        if level.lower() != "info":
            print(f"{level.upper()}: {message}")


def load_json(path: Path) -> Dict[str, Any] | None:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        return None
    except json.JSONDecodeError as exc:
        print(f"ERROR: Failed to parse JSON payload: {exc}", file=sys.stderr)
        return None


def load_state(path: Path) -> Dict[str, Any]:
    if not path.exists():
        return dict(DEFAULT_STATE)
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return dict(DEFAULT_STATE)


def save_state(path: Path, state: Dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(state, indent=2, sort_keys=True), encoding="utf-8")


def compute_signature(payload: Dict[str, Any]) -> Dict[str, Any]:
    signature = {
        "top_keys": sorted(payload.keys()),
        "intent_keys": sorted(payload.get("intent", {}).keys())
        if isinstance(payload.get("intent"), dict)
        else [],
        "telemetry_keys": sorted(payload.get("telemetry_stub", {}).keys())
        if isinstance(payload.get("telemetry_stub"), dict)
        else [],
    }
    narration = payload.get("narration")
    if isinstance(narration, dict):
        signature["narration_keys"] = sorted(narration.keys())
    return signature


def signature_hash(signature: Dict[str, Any]) -> str:
    normalized = {
        "top_keys": signature.get("top_keys", []),
        "intent_keys": sorted(
            key
            for key in signature.get("intent_keys", [])
            if key not in OPTIONAL_INTENT_KEYS
        ),
        "telemetry_keys": sorted(
            key
            for key in signature.get("telemetry_keys", [])
            if key not in OPTIONAL_TELEMETRY_KEYS
        ),
    }
    serialized = json.dumps(normalized, sort_keys=True, separators=(",", ":"))
    return hashlib.sha256(serialized.encode("utf-8")).hexdigest()


def prune_recent(state: Dict[str, Any]) -> None:
    recent = state.setdefault("recent_batches", {})
    if not isinstance(recent, dict):
        state["recent_batches"] = {}
        return
    cutoff = datetime.now(timezone.utc) - timedelta(hours=RECENT_RETENTION_HOURS)
    to_delete = []
    for batch_id, info in recent.items():
        try:
            last_seen = datetime.fromisoformat(info.get("last_seen"))
        except Exception:  # noqa: BLE001 - defensive parsing wrapper
            to_delete.append(batch_id)
            continue
        if last_seen < cutoff:
            to_delete.append(batch_id)
    for batch_id in to_delete:
        recent.pop(batch_id, None)
    # Trim to max entries (oldest first)
    if len(recent) > STATE_MAX_RECENT:
        ordered = sorted(
            recent.items(),
            key=lambda item: item[1].get("last_seen", ""),
        )
        for batch_id, _ in ordered[: len(recent) - STATE_MAX_RECENT]:
            recent.pop(batch_id, None)


def record_batch(state: Dict[str, Any], batch_id: str, glyph_chain: List[str]) -> None:
    recent = state.setdefault("recent_batches", {})
    now = datetime.now(timezone.utc).isoformat()
    recent[batch_id] = {
        "glyph_chain": list(glyph_chain),
        "last_seen": now,
    }


def detect_reorder(state: Dict[str, Any], batch_id: str, glyph_chain: List[str]) -> bool:
    recent = state.get("recent_batches", {})
    if not isinstance(recent, dict) or batch_id not in recent:
        return False
    prev = recent[batch_id].get("glyph_chain")
    return list(prev) != list(glyph_chain)


def validate_payload(payload: Dict[str, Any], state: Dict[str, Any], logger: GuardLogger,
                     *, state_path: Path) -> Tuple[bool, bool]:
    order_id = payload.get("order_id")
    telemetry = payload.get("telemetry_stub")
    batch_id = None
    if isinstance(telemetry, dict):
        batch_id = telemetry.get("batch_id")
    signature = compute_signature(payload)
    sig_hash = signature_hash(signature)
    baseline = state.get("expected_signature")
    baseline_hash = state.get("schema_hash")
    if baseline:
        recalculated = signature_hash(baseline)
        if baseline_hash != recalculated:
            baseline_hash = recalculated
            state["schema_hash"] = recalculated

    alerts: deque[str] = deque()
    warnings: deque[str] = deque()

    top_keys = set(payload.keys())
    missing = sorted(REQUIRED_TOP_KEYS - top_keys)
    if missing:
        alerts.append(f"missing required fields: {', '.join(missing)}")
    unexpected = sorted(
        key for key in top_keys
        if key not in REQUIRED_TOP_KEYS and key not in ALLOWED_OPTIONAL_TOP_KEYS
    )
    if unexpected:
        alerts.append(f"unexpected fields detected: {', '.join(unexpected)}")

    intent = payload.get("intent")
    if not isinstance(intent, dict):
        alerts.append("intent block absent or malformed")
        intent_keys: Iterable[str] = []
    else:
        intent_keys = intent.keys()
        intent_missing = sorted(REQUIRED_INTENT_KEYS - set(intent_keys))
        if intent_missing:
            alerts.append(
                "intent missing keys: " + ", ".join(intent_missing)
            )
        unexpected_intent = sorted(
            key for key in intent_keys if key not in REQUIRED_INTENT_KEYS | OPTIONAL_INTENT_KEYS
        )
        if unexpected_intent:
            warnings.append(
                "intent unexpected keys: " + ", ".join(unexpected_intent)
            )

    glyph_chain = payload.get("glyph_chain")
    if not isinstance(glyph_chain, list) or not all(isinstance(g, str) for g in glyph_chain):
        alerts.append("glyph_chain must be an array of strings")
    elif len(glyph_chain) == 0:
        alerts.append("glyph_chain cannot be empty")

    telemetry_stub = payload.get("telemetry_stub")
    if not isinstance(telemetry_stub, dict):
        alerts.append("telemetry_stub block absent or malformed")
        telemetry_keys: Iterable[str] = []
    else:
        telemetry_keys = telemetry_stub.keys()
        telemetry_missing = sorted(REQUIRED_TELEMETRY_KEYS - set(telemetry_keys))
        if telemetry_missing:
            alerts.append(
                "telemetry_stub missing keys: " + ", ".join(telemetry_missing)
            )
        duration = telemetry_stub.get("duration_ms")
        if isinstance(duration, int) and duration < 0:
            warnings.append("telemetry_stub duration_ms is negative")
        if telemetry_stub.get("status") not in {"success", "warning", "error"}:
            warnings.append("telemetry_stub status outside expected set")

    narration = payload.get("narration")
    if narration is not None and not isinstance(narration, dict):
        warnings.append("narration block present but not an object")

    summary = payload.get("summary")
    if not isinstance(summary, str) or not summary.strip():
        alerts.append("summary is missing or empty")

    if batch_id and isinstance(glyph_chain, list) and len(glyph_chain) > 0:
        if detect_reorder(state, batch_id, glyph_chain):
            alerts.append("glyph_chain reordered for batch")

    # Schema signature validation
    if baseline is None and baseline_hash is None:
        # Seed the baseline only when no alerts triggered.
        if not alerts:
            state["expected_signature"] = signature
            state["schema_hash"] = sig_hash
    else:
        if baseline_hash and baseline_hash != sig_hash:
            alerts.append("schema signature drift detected")
        if baseline:
            expected_intent = set(baseline.get("intent_keys") or [])
            current_intent = set(signature.get("intent_keys") or [])
            missing_intent = sorted(
                key for key in expected_intent - current_intent
                if key not in OPTIONAL_INTENT_KEYS
            )
            unexpected_intent = sorted(
                key for key in current_intent - expected_intent
                if key not in OPTIONAL_INTENT_KEYS
            )
            if missing_intent:
                alerts.append(
                    "intent key set drift detected (missing: "
                    + ", ".join(missing_intent)
                    + ")"
                )
            if unexpected_intent:
                alerts.append(
                    "intent key set drift detected (unexpected: "
                    + ", ".join(unexpected_intent)
                    + ")"
                )

            expected_t = set(baseline.get("telemetry_keys") or [])
            current_t = set(signature.get("telemetry_keys") or [])
            missing_t = sorted(
                key for key in expected_t - current_t
                if key not in OPTIONAL_TELEMETRY_KEYS
            )
            unexpected_t = sorted(
                key for key in current_t - expected_t
                if key not in OPTIONAL_TELEMETRY_KEYS
            )
            if missing_t:
                alerts.append(
                    "telemetry key set drift detected (missing: "
                    + ", ".join(missing_t)
                    + ")"
                )
            if unexpected_t:
                alerts.append(
                    "telemetry key set drift detected (unexpected: "
                    + ", ".join(unexpected_t)
                    + ")"
                )

    # Emit logs in severity order
    alert_count = len(alerts)
    while alerts:
        message = alerts.popleft()
        logger.emit(
            "alert",
            message,
            order_id=order_id,
            batch_id=batch_id,
            code="schema_guard.alert",
        )

    if alert_count == 0:  # only persist state updates when in a clean state
        prune_recent(state)
        if batch_id and isinstance(glyph_chain, list) and len(glyph_chain) > 0:
            record_batch(state, batch_id, glyph_chain)
        save_state(state_path, state)

    # Drain warnings after state persistence to avoid blocking future updates
    warning_count = len(warnings)
    while warnings:
        message = warnings.popleft()
        logger.emit(
            "warning",
            message,
            order_id=order_id,
            batch_id=batch_id,
            code="schema_guard.warn",
        )

    return (alert_count == 0, warning_count == 0)


def main(argv: List[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Validate factory-order@1.0 payloads")
    parser.add_argument("--payload", required=True, help="Path to payload JSON file")
    parser.add_argument(
        "--log-file",
        default="logs/guardrail_audit/schema_guard.log",
        help="Destination log file for schema guard events",
    )
    parser.add_argument(
        "--state-file",
        default="logs/guardrail_audit/schema_guard.state",
        help="State file used to store baseline signature information",
    )
    args = parser.parse_args(argv)

    payload_path = Path(args.payload)
    payload = load_json(payload_path)
    if payload is None:
        return 1
    if payload.get("schema") != "factory-order@1.0":
        return 0

    logger = GuardLogger(Path(args.log_file))
    state_path = Path(args.state_file)
    state = load_state(state_path)

    validate_payload(payload, state, logger, state_path=state_path)
    return 0


if __name__ == "__main__":
    sys.exit(main())
