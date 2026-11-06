"""TC-09/TC-10 Flow 3 Track: Application Detail, and the list while offline."""

import pytest
from conftest import SIGNED_IN, run_case, set_network


async def test_tc09_application_detail_matches_the_list(artemis):
    report = await run_case(
        artemis,
        "TC-09",
        f"{SIGNED_IN} Tap 'Applications' in the bottom navigation. If the "
        "screen says 'You have not applied yet', create an application first: "
        "tap 'Home', open the first internship card, tap 'Apply now', tap "
        "'Continue to review', wait for the CV check to finish, tap 'Submit "
        "application', then tap 'View my applications'. Read the first "
        "application card: its position, company, the text that starts with "
        "'Applied', and its status badge. Then tap the card to open "
        "'Application Detail' and read the position, company and status badge "
        "shown there.",
        expected_output=(
            'JSON: {"list": {"position": string, "company": string, '
            '"applied_text": string, "status": string}, "detail": '
            '{"position": string, "company": string, "status": string}}'
        ),
    )
    listed = report["list"]
    detail = report["detail"]

    assert listed["position"].strip()
    assert listed["company"].strip()
    assert listed["applied_text"].strip()
    assert listed["status"].strip()
    assert detail["position"] == listed["position"]
    assert detail["company"] == listed["company"]
    assert detail["status"] == listed["status"]


@pytest.mark.error_path
async def test_tc10_application_list_stays_visible_offline(artemis):
    # Firestore keeps the list in its offline cache, so offline the app shows
    # the applications it already has instead of an error (2026-11-06 run
    # f1e857a4). The network goes off with adb, not through Quick Settings:
    # the agent needed 11 swipes there and the case is about the app.
    set_network(False)
    try:
        report = await run_case(
            artemis,
            "TC-10",
            f"{SIGNED_IN} The device is offline. Tap 'Applications' in the "
            "bottom navigation and wait 5 seconds. Note whether an application "
            "card is visible and the position on the first card, the line "
            "that ends with 'application' or 'applications', and whether an "
            "error message or a 'Retry' button is visible.",
            expected_output=(
                'JSON: {"card_visible": boolean, "first_position": string, '
                '"count_text": string, "error_visible": boolean, '
                '"retry_visible": boolean}'
            ),
        )
    finally:
        set_network(True)

    assert report["card_visible"] is True
    assert report["first_position"].strip()
    assert report["count_text"].endswith(("application", "applications"))
    assert report["error_visible"] is False
    assert report["retry_visible"] is False
