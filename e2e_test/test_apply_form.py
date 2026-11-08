"""Flow 2 (Compose application): TC-18 the email draft, TC-19 editing the
recipient and the letter.

TC-20 (a CV upload that fails offline) is gone with the form: the compose
screen has no upload, and a failed draft is covered by the
`ApplyComposeViewModel` unit tests instead.
"""

from conftest import (
    SIGNED_IN,
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


async def test_tc18_compose_screen_drafts_the_email(artemis):
    enable_analytics_debug()
    report = await run_case(
        artemis,
        "TC-18",
        f"{SIGNED_IN} {OPEN_COMPOSE} The next screen's app bar reads 'Apply by "
        "email'. Wait until the 'Subject' field contains text (up to 60 "
        "seconds). Then read the value in the 'To' field, the text in "
        "'Subject', the first two lines in 'Cover letter', the notice above "
        "the 'To' field, and whether the buttons 'Open email app' and \"I've "
        "sent it\" are visible.",
        expected_output=(
            'JSON: {"app_bar_title": string, "to_value": string, '
            '"subject": string, "letter_excerpt": string, '
            '"draft_notice": string, "open_email_visible": boolean, '
            '"sent_visible": boolean}'
        ),
    )
    assert report["app_bar_title"] == "Apply by email"
    assert report["open_email_visible"] is True
    assert report["sent_visible"] is True
    assert report["subject"].strip()
    assert report["letter_excerpt"].strip()
    # The draft came from the model, or the deterministic template when the
    # model was unavailable; either way the screen says which.
    notice = report["draft_notice"].lower()
    assert "drafted from the job description" in notice or "template" in notice
    assert "apply_start" in logged_analytics_events()


async def test_tc19_recipient_and_letter_are_editable(artemis):
    report = await run_case(
        artemis,
        "TC-19",
        f"{SIGNED_IN} {OPEN_COMPOSE} On 'Apply by email', tap the 'To' field, "
        "clear it and type 'hr@example.com'. Then tap the 'Cover letter' "
        "field, move the cursor to the end and type ' Test line.'. Read the "
        "final 'To' value and the character count shown under the cover "
        "letter.",
        expected_output='JSON: {"to_value": string, "character_count": integer}',
    )
    assert report["to_value"] == "hr@example.com"
    assert report["character_count"] > 0
