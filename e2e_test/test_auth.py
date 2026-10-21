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
        "app finishes signing in. Report which screen is shown and the labels "
        "of the bottom navigation bar from left to right.",
        expected_output=(
            'JSON: {"screen_title": string, "bottom_nav_labels": [string], '
            '"login_button_visible": boolean}'
        ),
    )
    assert report["screen_title"] == "Home"
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
        f"{SIGNED_IN} Tap 'Profile' in the bottom navigation, then tap "
        "'Sign out'. After the Login screen appears, press the Android Back "
        "button once. Report what is visible.",
        expected_output=(
            'JSON: {"login_button_visible": boolean, '
            '"bottom_nav_visible": boolean, "app_still_open": boolean}'
        ),
    )
    assert report["login_button_visible"] is True
    assert report["bottom_nav_visible"] is False
