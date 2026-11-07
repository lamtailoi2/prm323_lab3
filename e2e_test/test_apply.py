"""TC-06 Flow 2: the email draft and `I've sent it`. TC-07 Flow 2c: a listing
already applied to shows its application."""

from conftest import SIGNED_IN, run_case

# Every run records a real application, which cannot be deleted. The listing
# only needs an unapplied card; the compose screen drafts from the JD.
CHOOSE_LISTING = (
    "Tap 'Search' in the bottom navigation, type 'Developer' in the search "
    "field and tap 'Find Internships'. Tap the first internship card that has "
    "no 'Applied' badge (scroll down if needed). Note its job title and "
    "company name."
)


async def test_tc06_compose_email_then_sent(artemis):
    report = await run_case(
        artemis,
        "TC-06",
        f"{SIGNED_IN} {CHOOSE_LISTING} Tap 'Apply now'. The next screen's app "
        "bar reads 'Apply by email'. Read the value in the 'To' field, the text "
        "in 'Subject', the first two lines in 'Cover letter', and whether the "
        "buttons 'Open email app' and \"I've sent it\" are visible. Tap \"I've "
        "sent it\" and read the title and company shown in the success recap.",
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
