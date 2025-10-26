#!/usr/bin/env python3
"""Narrator usage logger for Pivot Five monitoring.

Captures narrator persona, locale, and audio asset metadata for every narration
payload embedded within a `factory-order@1.0` event. The logger writes
structured JSON lines to the guardrail audit log and keeps a rolling metrics
snapshot that can be scraped by the Prometheus exporter planned in the
monitoring guide.
"""

from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict

LOG_PATH_DEFAULT = Path("logs/guardrail_audit/narrator_usage.log")
METRICS_PATH_DEFAULT = Path("logs/guardrail_audit/narrator_metrics.json")
KNOWN_PERSONAS = {"war_office_herald", "frontline_correspondent"}


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def ensure_parent(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)


def load_payload(path: Path) -> Dict[str, Any] | None:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        print(f"ERROR: payload not found at {path}", file=sys.stderr)
        return None
    except json.JSONDecodeError as exc:
        print(f"ERROR: failed to parse narration payload: {exc}", file=sys.stderr)
        return None


def load_metrics(path: Path) -> Dict[str, Any]:
    if not path.exists():
        return {
            "narrator_invocations_total": 0,
            "narrator_locale_mismatch_total": 0,
            "narrator_fallback_total": 0,
            "narrator_unknown_persona_total": 0,
            "updated_at": utc_now(),
        }
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        data = {}
    data.setdefault("narrator_invocations_total", 0)
    data.setdefault("narrator_locale_mismatch_total", 0)
    data.setdefault("narrator_fallback_total", 0)
    data.setdefault("narrator_unknown_persona_total", 0)
    return data


def write_metrics(path: Path, metrics: Dict[str, Any]) -> None:
    ensure_parent(path)
    metrics["updated_at"] = utc_now()
    path.write_text(json.dumps(metrics, indent=2, sort_keys=True), encoding="utf-8")


def append_log(path: Path, record: Dict[str, Any]) -> None:
    ensure_parent(path)
    with path.open("a", encoding="utf-8") as fh:
        fh.write(json.dumps(record, separators=(",", ":")) + "\n")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Log narrator usage events")
    parser.add_argument("--payload", required=True, help="Path to payload JSON file")
    parser.add_argument(
        "--log-file",
        default=str(LOG_PATH_DEFAULT),
        help="Destination log file for structured narrator usage entries",
    )
    parser.add_argument(
        "--metrics-file",
        default=str(METRICS_PATH_DEFAULT),
        help="Metrics snapshot file path",
    )
    args = parser.parse_args(argv)

    payload = load_payload(Path(args.payload))
    if payload is None:
        return 1
    if payload.get("schema") != "factory-order@1.0":
        return 0

    narration = payload.get("narration")
    if not isinstance(narration, dict):
        # Not every payload will carry narration metadata; treat as no-op.
        return 0

    persona = narration.get("persona") or "unknown"
    locale = narration.get("locale") or "unknown"
    expected_locale = (
        payload.get("locale")
        or payload.get("telemetry_stub", {}).get("locale")
        if isinstance(payload.get("telemetry_stub"), dict)
        else None
    )
    audio_asset_id = narration.get("audio_asset_id") or narration.get("asset_id")
    fallback = bool(narration.get("fallback") or narration.get("is_fallback"))
    persona_unknown = persona not in KNOWN_PERSONAS

    metrics_path = Path(args.metrics_file)
    metrics = load_metrics(metrics_path)
    metrics["narrator_invocations_total"] += 1

    locale_mismatch = bool(expected_locale and locale and expected_locale != locale)
    if locale_mismatch:
        metrics["narrator_locale_mismatch_total"] += 1

    if fallback:
        metrics["narrator_fallback_total"] += 1
    if persona_unknown:
        metrics["narrator_unknown_persona_total"] += 1

    write_metrics(metrics_path, metrics)

    record = {
        "timestamp": utc_now(),
        "order_id": payload.get("order_id"),
        "batch_id": payload.get("telemetry_stub", {}).get("batch_id")
        if isinstance(payload.get("telemetry_stub"), dict)
        else None,
        "persona": persona,
        "locale": locale,
        "expected_locale": expected_locale,
        "audio_asset_id": audio_asset_id,
        "fallback": fallback,
    "summary": payload.get("summary"),
    "persona_unknown": persona_unknown,
    }

    append_log(Path(args.log_file), record)

    if locale_mismatch:
        print("WARNING: narrator locale mismatch detected")
    if fallback:
        print("WARNING: narrator fallback voice engaged")
    if persona_unknown:
        print("WARNING: narrator persona outside known set")

    return 0


if __name__ == "__main__":
    sys.exit(main())
