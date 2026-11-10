"""Flow 2 (Compose application): TC-18 the complete hand-off — app draft,
Gmail send, back to the app, `I've sent it` — and TC-19 the CV block plus the
editable fields.

TC-20 (a CV upload that fails offline) is gone with the form: the compose
screen has no upload, and a failed draft is covered by the
`ApplyComposeViewModel` unit tests instead.
"""

import pytest

from conftest import (
    SIGNED_IN,
    TEST_ACCOUNT_EMAIL,
    enable_analytics_debug,
    logged_analytics_events,
    run_case,
)

OPEN_COMPOSE = (
    "Tap 'Search' in the bottom navigation, type 'Intern' in the search field "
    "and tap 'Find Internships'. Tap the first internship card that has no "
    "'Applied' badge (an applied listing shows 'View application' instead), "
    "then tap 'Apply now' at the bottom."
)


@pytest.mark.native
async def test_tc18_compose_send_email_then_mark_sent(artemis):
    enable_analytics_debug()
    report = await run_case(
        artemis,
        "TC-18",
        f"{SIGNED_IN} {OPEN_COMPOSE} The next screen's app bar reads 'Apply by "
        "email'. Wait until the 'Subject' field contains text (up to 60 "
        "seconds). Read the banner at the top of the form (under the "
        "internship summary), the text in 'Subject', the first two lines in "
        "'Cover letter', and the title and company at the top of the form. In "
        "the 'To' box, the grey 'recruiter@company.com' is only a placeholder: "
        "report to_shows_only_placeholder true when no real address is typed. "
        "Tap 'Open email app' and wait 3 seconds. An email app must open; read "
        "its name, its 'To' field, its 'Subject' and the first line of its "
        f"body. Clear the email app's 'To' field and type '{TEST_ACCOUNT_EMAIL}' "
        "so the test never emails a real company. Read the 'To' field again "
        "and tap 'Send'. Wait 3 seconds. Press the Android Back button until "
        "the Internly 'Apply by email' screen is visible again; if the app is "
        "not in front, open Internly from the recent apps. Tap \"I've sent "
        "it\" and wait for the success screen. Read its heading and the "
        "recap's title and company.",
        expected_output=(
            'JSON: {"app_bar_title": string, "card_title": string, '
            '"card_company": string, "draft_banner": string, '
            '"to_shows_only_placeholder": boolean, "subject": string, '
            '"letter_excerpt": string, "email_app_visible": boolean, '
            '"email_app_name": string, "mail_to_value": string, '
            '"mail_subject": string, "mail_body_excerpt": string, '
            '"mail_to_after_edit": string, "send_tapped": boolean, '
            '"mail_sent_visible": boolean, "back_in_app": boolean, '
            '"success_heading": string, "success_title": string, '
            '"success_company": string}'
        ),
        # Follow the hand-off into Gmail and back.
        locked_app_package=None,
    )
    assert report["app_bar_title"] == "Apply by email"
    assert report["card_title"].strip()
    assert report["card_company"].strip()
    banner = report["draft_banner"].lower()
    assert "drafted from the job description" in banner or "template" in banner
    assert report["subject"].strip()
    assert report["letter_excerpt"].strip()
    # The draft must reach the mail app before it is sent.
    assert report["email_app_visible"] is True, (
        "TC-18: no email app opened; install or enable one on the device"
    )
    assert "gmail" in report["email_app_name"].lower()
    assert report["mail_subject"].strip()
    assert report["mail_body_excerpt"].strip()
    # The test sends only to its own account, never to the recruiter.
    assert report["mail_to_after_edit"] == TEST_ACCOUNT_EMAIL
    assert report["send_tapped"] is True
    # Back in the app, `I've sent it` is the only step that records the
    # application (BR-P8).
    assert report["back_in_app"] is True
    assert report["success_heading"] == "Application submitted!"
    assert report["success_title"] == report["card_title"]
    assert report["success_company"] == report["card_company"]
    events = logged_analytics_events()
    assert "apply_start" in events
    assert "application_create" in events


async def test_tc19_cv_change_and_letter_edit(artemis):
    report = await run_case(
        artemis,
        "TC-19",
        f"{SIGNED_IN} {OPEN_COMPOSE} The next screen's app bar reads 'Apply by "
        "email'. Wait until the 'Subject' field contains text (up to 60 "
        "seconds). Scroll down until the 'CV / Resume' section is visible; if "
        "it is not visible, keep scrolling down. Read the CV file name. Tap "
        "'Change CV', read the sheet title and subtitle, then tap the CV whose "
        "file name is different from the one you read and tap 'Done'. Wait "
        "until the 'Cover letter' has text, then scroll to the 'CV / Resume' "
        "section and read the CV file name again. Then tap the 'Cover letter' "
        "field, move the cursor to the end and type ' Test line.'. Read the "
        "character count shown under the cover letter.",
        expected_output=(
            'JSON: {"initial_cv": string, "sheet_title": string, '
            '"selected_cv": string, "cv_after_change": string, '
            '"character_count": integer}'
        ),
    )
    assert report["initial_cv"].strip()
    assert report["sheet_title"] == "Change CV"
    assert report["selected_cv"].strip()
    assert report["selected_cv"] != report["initial_cv"]
    # The choice applies to this application only (BR-C5, DC-26).
    assert report["cv_after_change"] == report["selected_cv"]
    assert report["character_count"] > 0
