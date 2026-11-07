"""TC-01 sign-in (native account picker + analytics) and TC-14 sign-out."""

import pytest
from conftest import (
    SIGNED_IN,
    SIGNED_OUT,
    TEST_ACCOUNT_EMAIL,
    enable_analytics_debug,
    logged_analytics_events,
    run_case,
)


@pytest.mark.native
async def test_tc01_google_sign_in_opens_home(artemis):
    enable_analytics_debug()
    report = await run_case(
        artemis,
        "TC-01",
        f"{SIGNED_OUT} On the Login screen tap 'Continue with Google'. In the "
        f"Google account picker choose '{TEST_ACCOUNT_EMAIL}'. Wait until the "
        "app finishes signing in. Report which bottom navigation item is "
        "highlighted and the labels of the bottom navigation bar from left to "
        "right.",
        expected_output=(
            'JSON: {"selected_tab": string, "bottom_nav_labels": [string], '
            '"login_button_visible": boolean}'
        ),
    )
    # Home's header shows a greeting and the student's name (UI v2, DC-31),
    # not the word "Home", so the highlighted tab says where sign-in landed.
    assert report["selected_tab"] == "Home"
    assert report["bottom_nav_labels"] == [
        "Home",
        "Search",
        "Saved",
        "Applications",
        "Profile",
    ]
    assert report["login_button_visible"] is False
    # The login event from the analytics plan reached Firebase (debug mode).
    assert "login" in logged_analytics_events()


async def test_tc14_sign_out_returns_to_login(artemis):
    report = await run_case(
        artemis,
        "TC-14",
        f"{SIGNED_IN} Tap 'Profile' in the bottom navigation, scroll down to "
        "'Settings & support' and tap 'Sign out'. Note whether the Login "
        "screen with 'Continue with Google' appears. Press the Android Back "
        "button once and note what is on screen now: the Internly Login "
        "screen, the Android home screen with app icons, or another Internly "
        "screen; and whether a bottom navigation bar is visible. If the "
        "Internly app is no longer on screen, open the Internly app again. "
        "Finally note whether the Login screen with 'Continue with Google' "
        "is shown.",
        expected_output=(
            'JSON: {"login_after_sign_out": boolean, '
            '"after_back": "login" | "android_home" | "other_app_screen", '
            '"bottom_nav_visible_after_back": boolean, '
            '"login_after_reopen": boolean}'
        ),
    )
    assert report["login_after_sign_out"] is True
    # Login is the root after sign-out: Back may close the app (Android
    # behaviour), but must never reveal a signed-in screen.
    assert report["after_back"] in ("login", "android_home")
    assert report["bottom_nav_visible_after_back"] is False
    # Signed out for real: the next launch starts on Login, not Home.
    assert report["login_after_reopen"] is True
