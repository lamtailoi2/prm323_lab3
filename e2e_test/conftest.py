"""Shared fixtures and helpers for the Internly ARTEMIS suite (Lab 3, section 7).

Every test sends ONE natural-language instruction, asks the agent for a JSON
object describing what is visible at the end (`expected_output`), and asserts on
those values, not on the run status alone. Each run is appended to
`artifacts/runs.jsonl` (test id, status, trace id, duration) for the evidence
table in docs/test-plan.md.
"""

from __future__ import annotations

import json
import os
import re
import subprocess
import time
from pathlib import Path
from typing import Any

import pytest
from artemis_client import ArtemisClient
from dotenv import load_dotenv

HERE = Path(__file__).parent
load_dotenv(HERE / ".env")

APP_PACKAGE = os.environ.get("APP_PACKAGE", "com.group3.internly")
DEVICE_SERIAL = os.environ.get("DEVICE_SERIAL") or None
TEST_ACCOUNT_EMAIL = os.environ.get("TEST_ACCOUNT_EMAIL", "")
ARTIFACTS = HERE / "artifacts"

# Shared preconditions, so tests never depend on each other's order.
SIGNED_IN = (
    "Open the Internly app. If the Login screen with 'Continue with Google' is "
    "shown, tap it and choose the Google account "
    f"'{TEST_ACCOUNT_EMAIL}' in the account picker, then wait for Home."
)
SIGNED_OUT = (
    "Open the Internly app. If the bottom navigation bar is visible, tap "
    "'Profile', scroll down to 'Settings & support', tap 'Sign out' and wait "
    "for the Login screen."
)


@pytest.fixture(scope="session")
def artemis() -> ArtemisClient:
    return ArtemisClient(
        os.environ.get("ARTEMIS_BASE_URL") or None,
        token=os.environ.get("ARTEMIS_TOKEN") or None,
        device_serial=DEVICE_SERIAL,
        default_profile=os.environ.get("ARTEMIS_PROFILE", "flash"),  # type: ignore[arg-type]
    )


async def run_case(
    artemis: ArtemisClient,
    test_id: str,
    instruction: str,
    *,
    expected_output: str,
) -> dict[str, Any]:
    """Runs one instruction and returns the agent's structured report."""
    started = time.monotonic()
    result = await artemis.run(
        instruction,
        expected_output=expected_output,
        locked_app_package=APP_PACKAGE,
    )
    _record(test_id, result, time.monotonic() - started)
    assert result.succeeded, (
        f"{test_id}: {result.status} {result.error or ''} (trace {result.trace_id})"
    )
    report = parse_report(result.output)
    assert report, f"{test_id}: no structured output (trace {result.trace_id})"
    return report


def parse_report(output: Any) -> dict[str, Any]:
    """Accepts a dict, a JSON string, or text that contains one JSON object."""
    if isinstance(output, dict):
        return output
    if isinstance(output, str):
        try:
            value = json.loads(output)
            return value if isinstance(value, dict) else {}
        except json.JSONDecodeError:
            match = re.search(r"\{.*\}", output, flags=re.DOTALL)
            if match:
                try:
                    value = json.loads(match.group(0))
                    return value if isinstance(value, dict) else {}
                except json.JSONDecodeError:
                    return {}
    return {}


def _record(test_id: str, result: Any, seconds: float) -> None:
    ARTIFACTS.mkdir(exist_ok=True)
    line = {
        "test_id": test_id,
        "status": result.status,
        "succeeded": result.succeeded,
        "trace_id": result.trace_id,
        "seconds": round(seconds, 1),
        "error": result.error,
    }
    with (ARTIFACTS / "runs.jsonl").open("a", encoding="utf-8") as file:
        file.write(json.dumps(line) + "\n")


# ---- Analytics check through Logcat (Lab 3: at least one test) -------------


def _adb(*args: str) -> str:
    serial = ["-s", DEVICE_SERIAL] if DEVICE_SERIAL else []
    return subprocess.run(
        ["adb", *serial, *args], capture_output=True, text=True, check=True
    ).stdout


def enable_analytics_debug() -> None:
    """Turns on Analytics debug mode and verbose FA logs, then clears Logcat."""
    _adb("shell", "setprop", "debug.firebase.analytics.app", APP_PACKAGE)
    _adb("shell", "setprop", "log.tag.FA", "VERBOSE")
    _adb("shell", "setprop", "log.tag.FA-SVC", "VERBOSE")
    _adb("logcat", "-c")


def logged_analytics_events() -> list[str]:
    """Event names logged since the last `enable_analytics_debug()`."""
    dump = _adb("logcat", "-d", "-s", "FA", "FA-SVC")
    return re.findall(r"Logging event: origin=app,name=([a-z0-9_]+)", dump)
