"""TC-13 open a notification from the shade; TC-15 the notification
permission dialog (Flow 4 notifications, PR #24)."""

import time

import pytest
from conftest import (
    APP_PACKAGE,
    SIGNED_IN,
    app_notification_titles,
    grant_notification_permission,
    notification_permission_granted,
    reset_notification_permission,
    run_case,
    send_app_to_background,
)

# The suite cannot send FCM itself: the admin dashboard and the Firebase
# console need project credentials the suite must not hold. The case waits
# while the operator sends one message with this route to the test account.
TC13_ROUTE = "/saved"
TC13_SCREEN = "Saved"
TC13_WAIT_SECONDS = 180


@pytest.mark.native
async def test_tc13_open_notification_from_shade(artemis, capsys):
    send_app_to_background()
    before = app_notification_titles()
    with capsys.disabled():
        print(
            f"\nTC-13: send one FCM message to the test account now, with route "
            f"'{TC13_ROUTE}' (tools/admin-dashboard → Send notification, or "
            "Firebase console → test message to the token from Profile → "
            "Firebase demo → Copy FCM token). Waiting up to "
            f"{TC13_WAIT_SECONDS} s…",
            flush=True,
        )
    deadline = time.monotonic() + TC13_WAIT_SECONDS
    new_titles: set[str] = set()
    while time.monotonic() < deadline and not new_titles:
        time.sleep(2)
        new_titles = app_notification_titles() - before
    assert new_titles, (
        f"TC-13: no new {APP_PACKAGE} notification within {TC13_WAIT_SECONDS} s"
    )
    title = sorted(new_titles)[0]

    report = await run_case(
        artemis,
        "TC-13",
        "The internly app is in the background. Swipe down from the top of "
        "the screen to open the notification shade and tap the internly "
        f"notification titled '{title}'. Wait until the app is open and note "
        "the title in the top app bar. Then tap the bell icon at the top right "
        "(tooltip 'Notifications'). On the 'Notifications' screen note whether "
        f"a notification titled '{title}' is listed and whether it is marked "
        "'Read' or 'Unread'.",
        expected_output=(
            'JSON: {"opened_screen_title": string, "listed": boolean, '
            '"read_state": "Read" | "Unread" | null}'
        ),
    )
    assert report["opened_screen_title"] == TC13_SCREEN
    assert report["listed"] is True
    # Opening a notification marks it read (NotificationCoordinator._open).
    assert report["read_state"] == "Read"


@pytest.mark.native
async def test_tc15_notification_permission_dialog(artemis):
    reset_notification_permission()
    try:
        report = await run_case(
            artemis,
            "TC-15",
            f"{SIGNED_IN} Once signed in, the app asks for the notification "
            "permission with an Android dialog (wait up to 10 seconds if it is "
            "not visible yet; do not reopen the app). Before tapping anything "
            "in it, note the question text of the dialog and the labels of its "
            "two buttons. Then tap 'Allow' and note which bottom navigation "
            "item is highlighted after the dialog closes.",
            expected_output=(
                'JSON: {"dialog_visible": boolean, "dialog_text": string, '
                '"buttons": [string], "selected_tab": string}'
            ),
        )
        granted = notification_permission_granted()
    finally:
        # Never leave the permission revoked: later cases would meet the
        # dialog in the middle of their steps.
        grant_notification_permission()

    assert report["dialog_visible"] is True
    assert "send you notifications" in report["dialog_text"].lower()
    assert "Allow" in report["buttons"]
    # Home's header shows a greeting, not "Home" (UI v2, DC-31).
    assert report["selected_tab"] == "Home"
    assert granted is True
