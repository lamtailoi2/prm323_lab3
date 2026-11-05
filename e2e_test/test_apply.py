"""TC-06 Flow 2 + 2d: CV Match Check, Validate CV and submission."""

from conftest import SIGNED_IN, run_case


async def test_tc06_cv_match_then_validate_and_submit(artemis):
    report = await run_case(
        artemis,
        "TC-06",
        f"{SIGNED_IN} Tap 'Home', open an internship card that does not show "
        "'You applied on', tap 'Apply now'. On the Apply Form, scroll down and "
        "tap 'Continue to review'. On the 'CV match' screen, read the "
        "percentage, the line that contains 'requirements matched', every "
        "skill under 'Gaps to review' and the suggestion under each gap. Note "
        "whether the 'Continue' button is visible before the check finishes. "
        "Tap 'Continue', wait for the 'Validate CV' screen to finish, then tap "
        "'Continue to review'. On the review screen tap 'Submit application' "
        "and read the title and company shown in the success recap.",
        expected_output=(
            'JSON: {"match_percent": string, "match_summary": string, '
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
