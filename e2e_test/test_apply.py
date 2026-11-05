"""TC-06 Flow 4 Application: Apply Form → Validate CV → Review → Submit →
Success. TC-07 Flow 2c: a listing already applied to shows its application."""

import pytest
from conftest import (
    FILL_PERSONAL,
    SIGNED_IN,
    UPLOAD_SAMPLE_CV,
    enable_analytics_debug,
    logged_analytics_events,
    push_sample_cv,
    run_case,
)

# Every TC-06 run applies to a new 'Developer' listing (an application cannot
# be deleted), so TC-05's 'Intern' listing keeps its `Apply now` button.
FIND_DEVELOPER = (
    "Tap 'Search' in the bottom navigation, type 'Developer' in the search "
    "field and tap 'Find Internships'."
)


@pytest.mark.native
async def test_tc06_apply_validate_review_submit(artemis):
    push_sample_cv()
    enable_analytics_debug()
    report = await run_case(
        artemis,
        "TC-06",
        f"{SIGNED_IN} {FIND_DEVELOPER} Tap the first internship card that has "
        "no 'Applied' badge (scroll down if needed) and note its job title and "
        f"company name. Tap 'Apply now'. {UPLOAD_SAMPLE_CV} {FILL_PERSONAL} "
        "Tap 'Continue to review'. The 'Validate CV' screen shows 'Checking "
        "your CV…' and opens the next screen by itself: wait up to 60 seconds. "
        "If it stays on 'Validate CV', read its title and message and stop. On "
        "the next screen read the top app bar title and whether 'Ready to "
        "submit' is shown, then tap 'Submit application' at the bottom. Wait "
        "for the next screen and read its heading, the sentence under the "
        "heading, and whether 'View my applications' is visible.",
        expected_output=(
            'JSON: {"card_title": string, "card_company": string, '
            '"validate_cv_message": string | null, '
            '"review_app_bar_title": string, "ready_to_submit": boolean, '
            '"success_heading": string, "success_message": string, '
            '"view_my_applications_visible": boolean}'
        ),
    )
    assert not report["validate_cv_message"], (
        f"TC-06: stopped on Validate CV: {report['validate_cv_message']}"
    )
    assert report["review_app_bar_title"] == "Review application"
    assert report["ready_to_submit"] is True
    assert report["success_heading"] == "Application submitted!"
    assert report["success_message"] == (
        f"Your application for {report['card_title']} at "
        f"{report['card_company']} is saved in My Applications."
    )
    assert report["view_my_applications_visible"] is True
    assert "application_create" in logged_analytics_events()


async def test_tc07_applied_listing_shows_its_application(artemis):
    report = await run_case(
        artemis,
        "TC-07",
        f"{SIGNED_IN} {FIND_DEVELOPER} Find the first internship card that "
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
        "TC-07: no applied 'Developer' listing; run TC-06 first"
    )
    assert report["banner_title"].startswith("You applied on ")
    assert report["apply_now_visible"] is False
    assert report["view_application_visible"] is True
    assert report["detail_app_bar_title"] == "Application Detail"
    assert report["detail_position"] == report["card_title"]
    assert report["detail_company"] == report["card_company"]
    assert report["detail_status"] == report["banner_status"]
