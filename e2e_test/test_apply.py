"""TC-06 Flow 2: the email draft, its CV block, and `I've sent it`.
TC-07 Flow 2c: a listing already applied to shows its application and the
submitted CV."""

from conftest import SIGNED_IN, run_case

# Every run records a real application, which cannot be deleted. The listing
# only needs an unapplied card; the compose screen drafts from the JD.
CHOOSE_LISTING = (
    "Tap 'Search' in the bottom navigation, type 'Developer' in the search "
    "field and tap 'Find Internships'. Tap the first internship card that has "
    "no 'Applied' badge (scroll down if needed). Note its job title and "
    "company name."
)


def _same_position(left: str, right: str) -> bool:
    """Card titles may add skills or punctuation; compare the core text."""

    def norm(value: str) -> str:
        return "".join(char for char in value.lower() if char.isalnum())

    normalized_left = norm(left)
    normalized_right = norm(right)
    return normalized_left in normalized_right or normalized_right in normalized_left


async def test_tc06_compose_email_then_sent(artemis):
    report = await run_case(
        artemis,
        "TC-06",
        f"{SIGNED_IN} {CHOOSE_LISTING} Tap 'Apply now'. The next screen's app "
        "bar reads 'Apply by email'. Read the value in the 'To' field, the text "
        "in 'Subject', the first two lines in 'Cover letter', and whether "
        "the buttons 'Open email app' and \"I've sent it\" are visible. Tap "
        "\"I've sent it\" and read the title and company shown in the success "
        "recap.",
        expected_output=(
            'JSON: {"card_title": string, "card_company": string, '
            '"recipient": string, "subject": string, "letter_excerpt": string, '
            '"open_email_visible": boolean, "sent_visible": boolean, '
            '"success_title": string, "success_company": string}'
        ),
    )

    # The recipient may be empty when the job post names no address; the
    # screen must still offer the draft and the two actions.
    assert report["open_email_visible"] is True
    assert report["sent_visible"] is True
    assert report["subject"].strip()
    assert report["letter_excerpt"].strip()
    assert report["success_title"].strip()
    assert report["success_company"].strip()
    # The success recap names the listing the run started from.
    assert report["success_title"] == report["card_title"]
    assert report["success_company"] == report["card_company"]


# TC-07 only reads: TC-06 applies to the first unapplied 'Developer' cards, so
# the same search finds an 'Applied' card and the application it created.
FIND_DEVELOPER = (
    "Tap 'Search' in the bottom navigation, type 'Developer' in the search "
    "field and tap 'Find Internships'."
)


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
        "on that screen. Read the section titled 'Applicant & Submitted CV': "
        "the CV file name, the details line under it, whether a 'Preview' "
        "button is visible, and whether a 'Replace CV' button is visible.",
        expected_output=(
            'JSON: {"applied_card_found": boolean, "card_title": string, '
            '"card_company": string, "banner_title": string, '
            '"banner_status": string, "apply_now_visible": boolean, '
            '"view_application_visible": boolean, '
            '"detail_app_bar_title": string, "detail_position": string, '
            '"detail_company": string, "detail_status": string, '
            '"detail_cv_section": string, "detail_cv_file_name": string, '
            '"detail_cv_details": string, "detail_preview_visible": boolean, '
            '"detail_replace_cv_visible": boolean}'
        ),
    )
    assert report["applied_card_found"] is True, (
        "TC-07: no applied 'Developer' listing; run TC-06 first"
    )
    assert report["banner_title"].startswith("You applied on ")
    assert report["apply_now_visible"] is False
    assert report["view_application_visible"] is True
    assert report["detail_app_bar_title"] == "Application Detail"
    # The card title appends the skills; the detail shows the core position.
    assert _same_position(report["card_title"], report["detail_position"])
    assert report["detail_company"] == report["card_company"]
    assert report["detail_status"] == report["banner_status"]
    # BR-T6: the submitted CV is shown view-only, with no Replace CV.
    assert report["detail_cv_section"] == "Applicant & Submitted CV"
    assert report["detail_cv_file_name"].strip()
    details = report["detail_cv_details"]
    assert "Uploaded" in details or "Submitted" in details
    assert report["detail_preview_visible"] is True
    assert report["detail_replace_cv_visible"] is False
