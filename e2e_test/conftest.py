"""Shared fixtures and helpers for the Internly ARTEMIS suite (Lab 3, section 7).

Every test sends ONE natural-language instruction, asks the agent for a JSON
object describing what is visible at the end (`expected_output`), and asserts on
those values, not on the run status alone. Each run is appended to
`artifacts/runs.jsonl` (test id, ARTEMIS status, trace id, duration, pytest
result and failure) for the evidence table in docs/test-plan.md.
"""

from __future__ import annotations

import json
import os
import re
import subprocess
import time
from collections.abc import Generator
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

# ARTEMIS 351ca84 accepts `expected_output` but never runs its Outputter, so a
# run returns no `output`. The agent is asked to put the JSON in its final
# status report instead, which `final_report()` reads back.
REPORT_AS_JSON = (
    " Finish by calling report_task_status. Its explanation must be exactly "
    "one JSON object and nothing else, no sentence before or after it, with "
    "every key filled in from what you saw: "
)


@pytest.fixture(scope="session")
def artemis() -> ArtemisClient:
    return ArtemisClient(
        os.environ.get("ARTEMIS_BASE_URL") or None,
        token=os.environ.get("ARTEMIS_TOKEN") or None,
        device_serial=DEVICE_SERIAL,
        default_profile=os.environ.get("ARTEMIS_PROFILE", "flash"),  # type: ignore[arg-type]
    )


@pytest.fixture(autouse=True)
def cold_start_app() -> None:
    """Every run starts from a cold app (the sign-in session is kept), so text
    or screens left by the previous run cannot make a case pass."""
    _adb("shell", "am", "force-stop", APP_PACKAGE)
    # A debug build starts slowly; input during its splash raises an "isn't
    # responding" dialog, so the app is launched and left to settle first.
    _adb("shell", "am", "start", "-W", "-n", f"{APP_PACKAGE}/.MainActivity")
    time.sleep(10)


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
        f"{instruction}{REPORT_AS_JSON}{expected_output}",
        expected_output=expected_output,
        locked_app_package=APP_PACKAGE,
    )
    _record(test_id, result, time.monotonic() - started)
    assert result.succeeded, (
        f"{test_id}: {result.status} {result.error or ''} (trace {result.trace_id})"
    )
    report = parse_report(result.output) or parse_report(
        await final_report(artemis, result.task_id)
    )
    assert report, f"{test_id}: no structured output (trace {result.trace_id})"
    return report


async def final_report(artemis: ArtemisClient, task_id: str) -> str | None:
    """Explanation of the agent's last `report_task_status` step, read from the
    daemon's step history (`GET /api/sessions/{id}/steps`)."""
    # The pinned client has no public call for the step history.
    steps = await artemis._request("GET", f"/api/sessions/{task_id}/steps")
    for step in reversed(steps if isinstance(steps, list) else []):
        action = step.get("action_taken") or {}
        if action.get("action") == "report_task_status":
            return (action.get("args") or {}).get("explanation")
    return None


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


# The current test's run; written to runs.jsonl once its pytest result is known.
_pending_run: dict[str, Any] | None = None


def _record(test_id: str, result: Any, seconds: float) -> None:
    global _pending_run
    _pending_run = {
        "test_id": test_id,
        "status": result.status,
        "succeeded": result.succeeded,
        "trace_id": result.trace_id,
        "seconds": round(seconds, 1),
        "error": result.error,
    }


@pytest.hookimpl(hookwrapper=True)
def pytest_runtest_makereport(
    item: pytest.Item, call: pytest.CallInfo[None]
) -> Generator[None, Any, None]:
    """Appends the run with its pytest result: `succeeded` is only ARTEMIS's
    status and stays true when the report or an assertion fails."""
    outcome = yield
    report = outcome.get_result()
    if report.when != "call":
        return
    global _pending_run
    line = _pending_run or {"test_id": item.name}
    _pending_run = None
    line["pytest"] = report.outcome
    if report.failed:
        crash = getattr(report.longrepr, "reprcrash", None)
        line["failure"] = (crash.message if crash else str(report.longrepr))[:300]
    ARTIFACTS.mkdir(exist_ok=True)
    with (ARTIFACTS / "runs.jsonl").open("a", encoding="utf-8") as file:
        file.write(json.dumps(line, ensure_ascii=False) + "\n")


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


# ---- Sample CV on the device ------------------------------------------------

SAMPLE_CV_NAME = "Sample_CV.pdf"

# Fictional details only. The structure (contact, education, skills,
# projects) is what the `validateCv` Gemini rubric accepts as a CV, and the
# text is well over its 50-character minimum, so `Validate CV` accepts it.
# Unused since the Apply Form was removed (DC-31); kept for the CV library
# cases that will pick a file from the device.
SAMPLE_CV_LINES = [
    "Test Student - Software Engineering Intern",
    "Email: test.student@example.com | Phone: 0900 000 000 | Ho Chi Minh City",
    "",
    "EDUCATION",
    "BSc Software Engineering, Example University, 2023 - 2027 (GPA 3.4 / 4.0)",
    "",
    "SKILLS",
    "Flutter, Dart, Firebase, REST APIs, Git, SQL, English (IELTS 6.5)",
    "",
    "PROJECTS",
    "Campus Events app (Flutter, Firestore): event list, search and reminders.",
    "Library REST API (Node.js): book loans with JWT sign-in and unit tests.",
    "",
    "EXPERIENCE",
    "Teaching assistant, Mobile Programming lab, Example University, 2025.",
]


def _sample_pdf() -> bytes:
    """A one-page PDF CV with fictional data, to upload as a test CV."""

    def literal(line: str) -> bytes:
        escaped = line.replace("\\", "\\\\").replace("(", "\\(").replace(")", "\\)")
        return b"(" + escaped.encode("latin-1") + b") Tj T*"

    content = (
        b"BT /F1 11 Tf 16 TL 56 760 Td "
        + b" ".join(literal(line) for line in SAMPLE_CV_LINES)
        + b" ET"
    )
    objects = [
        b"<< /Type /Catalog /Pages 2 0 R >>",
        b"<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
        b"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] "
        b"/Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>",
        b"<< /Length %d >>\nstream\n" % len(content) + content + b"\nendstream",
        b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>",
    ]
    out = bytearray(b"%PDF-1.4\n")
    offsets = []
    for number, body in enumerate(objects, 1):
        offsets.append(len(out))
        out += b"%d 0 obj\n" % number + body + b"\nendobj\n"
    xref = len(out)
    out += b"xref\n0 %d\n0000000000 65535 f \n" % (len(objects) + 1)
    for offset in offsets:
        out += b"%010d 00000 n \n" % offset
    out += b"trailer\n<< /Size %d /Root 1 0 R >>\nstartxref\n%d\n%%%%EOF\n" % (
        len(objects) + 1,
        xref,
    )
    return bytes(out)


def push_sample_cv() -> None:
    """Puts `Sample_CV.pdf` in the device's Downloads, where the Android
    document picker lists it."""
    ARTIFACTS.mkdir(exist_ok=True)
    local = ARTIFACTS / SAMPLE_CV_NAME
    local.write_bytes(_sample_pdf())
    _adb("push", str(local), f"/sdcard/Download/{SAMPLE_CV_NAME}")
    _adb(
        "shell",
        "am",
        "broadcast",
        "-a",
        "android.intent.action.MEDIA_SCANNER_SCAN_FILE",
        "-d",
        f"file:///sdcard/Download/{SAMPLE_CV_NAME}",
    )


def set_network(enabled: bool) -> None:
    """Turns Wi-Fi and mobile data on or off (emulator / test device only)."""
    state = "enable" if enabled else "disable"
    _adb("shell", "svc", "wifi", state)
    _adb("shell", "svc", "data", state)


# ---- Notifications (TC-13, TC-15) -------------------------------------------

NOTIFICATION_PERMISSION = "android.permission.POST_NOTIFICATIONS"


def reset_notification_permission() -> None:
    """Puts the notification permission back to "never asked", as after a
    fresh install, and leaves the app stopped. The case's own "Open the
    Internly app" then starts it once and it asks once signed in: a launch
    here as well made ARTEMIS reopen the app over the system dialog, which
    closed it (TC-15, 2026-11-06)."""
    _adb("shell", "am", "force-stop", APP_PACKAGE)
    _adb("shell", "pm", "revoke", APP_PACKAGE, NOTIFICATION_PERMISSION)
    _adb(
        "shell",
        "pm",
        "clear-permission-flags",
        APP_PACKAGE,
        NOTIFICATION_PERMISSION,
        "user-set",
        "user-fixed",
    )


def grant_notification_permission() -> None:
    _adb("shell", "pm", "grant", APP_PACKAGE, NOTIFICATION_PERMISSION)


def notification_permission_granted() -> bool:
    dump = _adb("shell", "dumpsys", "package", APP_PACKAGE)
    return f"{NOTIFICATION_PERMISSION}: granted=true" in dump


def app_notification_titles() -> set[str]:
    """Titles of this app's notifications currently in the shade."""
    dump = _adb("shell", "dumpsys", "notification", "--noredact")
    titles = set()
    for record in dump.split("NotificationRecord(")[1:]:
        if f"pkg={APP_PACKAGE} " not in record.split("\n", 1)[0]:
            continue
        match = re.search(r"android\.title=String \((.*)\)", record)
        if match:
            titles.add(match.group(1))
    return titles


def send_app_to_background() -> None:
    _adb("shell", "input", "keyevent", "KEYCODE_HOME")
