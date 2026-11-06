"""TC-06 Flow 2 + 2d: CV Match Check, Validate CV and submission. TC-07
Flow 2c: a listing already applied to shows its application."""

import pytest
from conftest import (
    FILL_PERSONAL,
    SIGNED_IN,
    UPLOAD_SAMPLE_CV,
    push_sample_cv,
    run_case,
)

# Every run submits a real application, which cannot be deleted. The listing
# needs skill tags, or CV match has nothing to compare ("Nothing to compare
# yet", no gaps).
CHOOSE_LISTING = (
    "Tap 'Search' in the bottom navigation, type 'Developer' in the search "
    "field and tap 'Find Internships'. Tap the first internship card that has "
    "no 'Applied' badge and shows at least three skill tags (scroll down if "
    "needed). Note its job title and company name."
)


@pytest.mark.native
async def test_tc06_cv_match_then_validate_and_submit(artemis):
    # The fictional CV replaces the Profile CV for this application: the
    # 2026-11-02 Profile sample is too short for `validateCv` ("CV appears to
    # be empty or unreadable"), and no personal CV is sent to the functions.
    push_sample_cv()
    report = await run_case(
        artemis,
        "TC-06",
        f"{SIGNED_IN} {CHOOSE_LISTING} Tap 'Apply now'. {UPLOAD_SAMPLE_CV} "
        f"{FILL_PERSONAL} Scroll down and tap 'Continue to review'. On the 'CV "
        "match' screen, read the percentage, the line that contains "
        "'requirements matched', every skill under 'Gaps to review' and the "
        "suggestion under each gap. Note whether the 'Continue' button is "
        "visible before the check finishes. Tap 'Continue'. The 'Validate CV' "
        "screen moves on by itself to 'Review application' when the CV is "
        "accepted: wait up to 60 seconds. On 'Review application' tap 'Submit "
        "application' and read the title and company shown in the success "
        "recap.",
        expected_output=(
            'JSON: {"card_title": string, "card_company": string, '
            '"match_percent": string, "match_summary": string, '
            '"gap_count": integer, "suggestion_count": integer, '
            '"continue_visible_while_checking": boolean, '
            '"success_title": string, "success_company": string}'
        ),
    )

    assert "%" in report["match_percent"]
    assert "requirements matched" in report["match_summary"]
    assert report["gap_count"] >= 1
    assert report["suggestion_count"] >= 1
    assert report["continue_visible_while_checking"] is True
    assert report["success_title"].strip()
    assert report["success_company"].strip()
    # The success recap names the listing the run started from.
    assert report["success_title"] == report["card_title"]
    assert report["success_company"] == report["card_company"]


# TC-07 only reads: any applied listing among the 'Intern' results will do.
FIND_INTERN = (
    "Tap 'Search' in the bottom navigation, type 'Intern' in the search "
    "field and tap 'Find Internships'."
)


async def test_tc07_applied_listing_shows_its_application(artemis):
    report = await run_case(
        artemis,
        "TC-07",
        f"{SIGNED_IN} {FIND_INTERN} Find the first internship card that "
        "shows the 'Applied' badge (scroll down up to three screens). If there "
        "is none, report applied_card_found false and stop. Note its job title "
        "and company name and tap it. On the detail screen read the banner "
        "title that starts with 'You applied on', the status in the banner "
        "sentence 'Status: … .', and whether 'Apply now' and 'View "
        "application' are visible at the bottom. Tap 'View application'. Read "
        "the top app bar title, the position, the company and the status badge "
        "on that screen.",
        expected_output=(
            'JSON: {"applied_card_found": boolean, "card_title": string, '
            '"card_company": string, "banner_title": string, '
            '"banner_status": string, "apply_now_visible": boolean, '
            '"view_application_visible": boolean, '
            '"detail_app_bar_title": string, "detail_position": string, '
            '"detail_company": string, "detail_status": string}'
        ),
    )
    assert report["applied_card_found"] is True, (
        "TC-07: no applied 'Intern' listing; run TC-06 first"
    )
    assert report["banner_title"].startswith("You applied on ")
    assert report["apply_now_visible"] is False
    assert report["view_application_visible"] is True
    assert report["detail_app_bar_title"] == "Application Detail"
    assert report["detail_position"] == report["card_title"]
    assert report["detail_company"] == report["card_company"]
    assert report["detail_status"] == report["banner_status"]
