#!/usr/bin/env python3
"""Glyph to VO auditor for Pivot Five monitoring.

Validates that narrated transcripts remain aligned with the payload summary and
that narration cadence mirrors the glyph chain length. Repeated discrepancies
over a 24 hour window escalate to alert severity so High Command can intervene
quickly.
"""

from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any, Dict, List

LOG_DEFAULT = Path("logs/guardrail_audit/glyph_vo_discrepancies.log")
STATE_DEFAULT = Path("logs/guardrail_audit/glyph_vo_audit.state")
ALERT_THRESHOLD = 3  # Third occurrence triggers an alert
WINDOW_HOURS = 24


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


def utc_iso() -> str:
    return utc_now().isoformat()


def ensure_parent(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)


def load_payload(path: Path) -> Dict[str, Any] | None:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        print(f"ERROR: payload not found at {path}", file=sys.stderr)
        return None
    except json.JSONDecodeError as exc:
        print(f"ERROR: failed to parse payload: {exc}", file=sys.stderr)
        return None


def load_state(path: Path) -> Dict[str, Any]:
    if not path.exists():
        return {"issue_windows": {}}
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        data = {}
    data.setdefault("issue_windows", {})
    return data


def save_state(path: Path, state: Dict[str, Any]) -> None:
    ensure_parent(path)
    path.write_text(json.dumps(state, indent=2, sort_keys=True), encoding="utf-8")


def prune_state(state: Dict[str, Any]) -> None:
    window = state.setdefault("issue_windows", {})
    cutoff = utc_now() - timedelta(hours=WINDOW_HOURS)
    stale_keys: List[str] = []
    for key, events in window.items():
        refreshed: List[str] = []
        for stamp in events:
            try:
                ts = datetime.fromisoformat(stamp)
            except ValueError:
                continue
            if ts >= cutoff:
                refreshed.append(stamp)
        if refreshed:
            window[key] = refreshed[-ALERT_THRESHOLD:]
        else:
            stale_keys.append(key)
    for key in stale_keys:
        window.pop(key, None)


def append_log(path: Path, record: Dict[str, Any]) -> None:
    ensure_parent(path)
    with path.open("a", encoding="utf-8") as fh:
        fh.write(json.dumps(record, separators=(",", ":")) + "\n")


def extract_beats(narration: Dict[str, Any]) -> List[str]:
    beats = None
    for key in ("beats", "cadence", "cadence_beats"):
        value = narration.get(key)
        if value:
            beats = value
            break
    if beats is None:
        return []
    if isinstance(beats, list):
        return [str(item) for item in beats]
    if isinstance(beats, str):
        parts = [segment.strip() for segment in beats.split("|") if segment.strip()]
        if not parts:
            parts = [segment.strip() for segment in beats.split(" ") if segment.strip()]
        return parts
    return []


def register_issue(state: Dict[str, Any], issue_key: str) -> int:
    window = state.setdefault("issue_windows", {})
    events = window.setdefault(issue_key, [])
    cutoff = utc_now() - timedelta(hours=WINDOW_HOURS)
    filtered = []
    for stamp in events:
        try:
            ts = datetime.fromisoformat(stamp)
        except ValueError:
            continue
        if ts >= cutoff:
            filtered.append(stamp)
    filtered.append(utc_iso())
    window[issue_key] = filtered[-ALERT_THRESHOLD:]
    return len(filtered)


def build_issue_key(issue: str, identifier: str | None) -> str:
    return f"{issue}:{identifier or 'unknown'}"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Audit glyph to VO alignment")
    parser.add_argument("--payload", required=True, help="Path to payload JSON file")
    parser.add_argument(
        "--log-file",
        default=str(LOG_DEFAULT),
        help="Structured discrepancy log destination",
    )
    parser.add_argument(
        "--state-file",
        default=str(STATE_DEFAULT),
        help="State file tracking recent discrepancies",
    )
    args = parser.parse_args(argv)

    payload = load_payload(Path(args.payload))
    if payload is None:
        return 1
    if payload.get("schema") != "factory-order@1.0":
        return 0

    narration = payload.get("narration")
    if not isinstance(narration, dict):
        return 0

    summary = payload.get("summary", "")
    transcript = narration.get("transcript") or narration.get("script") or narration.get("copy")
    allow_divergence = bool(
        narration.get("allow_divergence") or payload.get("allow_narration_divergence")
    )
    glyph_chain = payload.get("glyph_chain") if isinstance(payload.get("glyph_chain"), list) else []
    beats = extract_beats(narration)

    batch_id = None
    telemetry_stub = payload.get("telemetry_stub")
    if isinstance(telemetry_stub, dict):
        batch_id = telemetry_stub.get("batch_id")

    state_path = Path(args.state_file)
    state = load_state(state_path)
    prune_state(state)

    log_path = Path(args.log_file)
    issues_triggered = False

    def log_discrepancy(level: str, message: str, code: str) -> None:
        record = {
            "timestamp": utc_iso(),
            "level": level,
            "code": code,
            "message": message,
            "order_id": payload.get("order_id"),
            "batch_id": batch_id,
        }
        append_log(log_path, record)
        print(f"{level.upper()}: {message}")

    if isinstance(transcript, str) and summary.strip() and not allow_divergence:
        if transcript.strip() != summary.strip():
            issue_key = build_issue_key("summary_mismatch", batch_id or payload.get("order_id"))
            count = register_issue(state, issue_key)
            level = "warning"
            if count >= ALERT_THRESHOLD:
                level = "alert"
            log_discrepancy(
                level,
                "Narration transcript diverges from payload summary",
                "glyph_vo.summary_mismatch",
            )
            issues_triggered = True

    if glyph_chain and beats:
        if len(glyph_chain) != len(beats):
            issue_key = build_issue_key("cadence_mismatch", batch_id or payload.get("order_id"))
            count = register_issue(state, issue_key)
            level = "warning"
            if count >= ALERT_THRESHOLD:
                level = "alert"
            log_discrepancy(
                level,
                "Glyph chain length differs from narration cadence beats",
                "glyph_vo.cadence_mismatch",
            )
            issues_triggered = True

    if issues_triggered:
        save_state(state_path, state)
    else:
        save_state(state_path, state)

    return 0


if __name__ == "__main__":
    sys.exit(main())
