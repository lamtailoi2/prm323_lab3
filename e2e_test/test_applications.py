"""TC-09/TC-10 Flow 3 Track: Application Detail (with the submitted CV), and
the list while offline."""

import pytest
from conftest import SIGNED_IN, run_case, set_network


def _same_position(left: str, right: str) -> bool:
    """Card titles may add skills or punctuation; compare the core text."""

    def norm(value: str) -> str:
        return "".join(char for char in value.lower() if char.isalnum())

    normalized_left = norm(left)
    normalized_right = norm(right)
    return normalized_left in normalized_right or normalized_right in normalized_left


async def test_tc09_application_detail_matches_the_list(artemis):
    report = await run_case(
        artemis,
        "TC-09",
        f"{SIGNED_IN} Tap 'Applications' in the bottom navigation. If the "
        "screen says 'You have not applied yet', report has_application false "
        "and stop. Otherwise read the first application card: its position, "
        "company, the text that starts with 'Applied', and its status badge. "
        "Then tap the card to open 'Application Detail' and read the position, "
        "company and status badge shown there. Read the section titled "
        "'Applicant & Submitted CV': the CV file name, the details line under "
        "it, whether a 'Preview' button is visible, and whether a 'Replace CV' "
        "button is visible.",
        expected_output=(
            'JSON: {"has_application": boolean, "list": {"position": string, '
            '"company": string, "applied_text": string, "status": string}, '
            '"detail": {"position": string, "company": string, '
            '"status": string, "cv_section": string, "cv_file_name": string, '
            '"cv_details": string, "preview_visible": boolean, '
            '"replace_cv_visible": boolean}}'
        ),
    )
    # The case only reads: an application cannot be deleted, so it never
    # creates one (TC-06 does, and its newest application carries a CV).
    assert report["has_application"] is True, "TC-09: no application; run TC-06"
    listed = report["list"]
    detail = report["detail"]

    assert listed["position"].strip()
    assert listed["company"].strip()
    assert listed["applied_text"].strip()
    assert listed["status"].strip()
    # The list card may append the skills; the detail shows the core position.
    assert _same_position(listed["position"], detail["position"])
    assert detail["company"] == listed["company"]
    assert detail["status"] == listed["status"]
    # BR-T6: the submitted CV snapshot is shown view-only.
    assert detail["cv_section"] == "Applicant & Submitted CV"
    assert detail["cv_file_name"].strip(), (
        "TC-09: newest application has no CV snapshot; run TC-06 first"
    )
    assert "Uploaded" in detail["cv_details"] or "Submitted" in detail["cv_details"]
    assert detail["preview_visible"] is True
    assert detail["replace_cv_visible"] is False


async def test_tc21_student_reports_a_stage(artemis):
    # `Save status` is disabled while the picked stage equals the stored one,
    # so the case picks a stage different from the one it reads and puts the
    # original back at the end; otherwise the second of the three runs would
    # find `Interview` already set and could not save.
    report = await run_case(
        artemis,
        "TC-21",
        f"{SIGNED_IN} Tap 'Applications' in the bottom navigation. If the "
        "screen says 'You have not applied yet', or no card has a status badge "
        "other than 'Withdrawn', 'Accepted' or 'Rejected', report "
        "has_application false and stop. Otherwise open the first card whose "
        "status badge is not 'Withdrawn', 'Accepted' or 'Rejected', note its "
        "title and read the status badge on Application Detail as "
        "before_status. The target stage is 'Interview', or 'Under review' if "
        "before_status is already 'Interview'. Tap the pencil button labelled "
        "'Update status'. In the sheet, tap the target stage and then 'Save "
        "status'. Wait 2 seconds, then read the status badge on Application "
        "Detail as detail_status. Use the back arrow to return to the "
        "Applications list and read the status badge of the card with the "
        "same title as list_status. Then open that card again, tap 'Update "
        "status', tap the stage named in before_status, tap 'Save status', "
        "wait 2 seconds and read the status badge as restored_status.",
        expected_output=(
            'JSON: {"has_application": boolean, "title": string, '
            '"before_status": string, "target_status": string, '
            '"detail_status": string, "list_status": string, '
            '"restored_status": string}'
        ),
    )
    assert report["has_application"] is True, "TC-21: no application; run TC-06"

    before = report["before_status"].strip()
    target = "Under review" if before == "Interview" else "Interview"
    assert report["target_status"].strip() == target

    # The tracker is student-reported (BR-T8, DC-35): the app writes what the
    # student picked and both the detail and the list follow the document.
    assert report["detail_status"].strip() == target
    assert report["list_status"].strip() == target
    assert report["restored_status"].strip() == before


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
