"""Flow 1 pre-submit (Apply Form): TC-18 Check CV → Continue → Validate CV,
TC-19 upload a CV through the Android document picker, TC-20 upload failed
while offline."""

import pytest
from conftest import (
    SAMPLE_CV_NAME,
    SIGNED_IN,
    enable_analytics_debug,
    logged_analytics_events,
    push_sample_cv,
    run_case,
    set_network,
)

OPEN_APPLY_FORM = (
    "Tap 'Search' in the bottom navigation, type 'Intern' in the search field "
    "and tap 'Find Internships'. Tap the first internship card, then tap "
    "'Apply now' at the bottom."
)

NO_CV = "Add a CV to continue. Companies need it to review your application."

# Fills only what the test account's Profile left empty, so `Continue to
# review` is decided by the CV alone.
FILL_PERSONAL = (
    "In 'Personal information' fill only the fields that are empty: "
    "'Full name' type 'Test Student', 'Phone number' type '0908123456', "
    "'University' tap it and choose 'FPT University', 'Year of study' tap it "
    "and choose 'Year 3'."
)


async def test_tc18_apply_form_checks_the_cv_before_continue(artemis):
    enable_analytics_debug()
    report = await run_case(
        artemis,
        "TC-18",
        f"{SIGNED_IN} {OPEN_APPLY_FORM} On the Apply Form report the top app "
        "bar title, the step text under it, and whether the 'CV / Resume' "
        "section shows a CV file (with 'Preview' and 'Replace') or an "
        f"'Upload CV' button. {FILL_PERSONAL} Then tap 'Continue to review' "
        "at the bottom and do not tap anything after that. Report the top app "
        "bar title of the screen you are now on and, if it is still the Apply "
        "Form, the red message in the 'CV / Resume' section.",
        expected_output=(
            'JSON: {"app_bar_title": string, "step_text": string, '
            '"cv_state": "file" | "upload_button", '
            '"next_app_bar_title": string, "cv_error": string | null}'
        ),
    )
    assert report["app_bar_title"] == "Apply Form"
    assert report["step_text"].startswith("Step 1 of 2")
    assert "Your details" in report["step_text"]
    if report["cv_state"] == "file":
        # Pre-submit Complete: the form hands the CV to Validate CV (Flow 4).
        assert report["next_app_bar_title"] == "Validate CV"
    else:
        assert report["next_app_bar_title"] == "Apply Form"
        assert report["cv_error"] == NO_CV
    assert "apply_start" in logged_analytics_events()


@pytest.mark.native
async def test_tc19_upload_a_cv_for_this_internship(artemis):
    push_sample_cv()
    report = await run_case(
        artemis,
        "TC-19",
        f"{SIGNED_IN} {OPEN_APPLY_FORM} In the 'CV / Resume' section tap "
        "'Replace' (or 'Upload CV' if there is no file). In the sheet tap "
        f"'Choose file'. In the Android file picker choose '{SAMPLE_CV_NAME}' "
        "(open Downloads if it is not listed). Back in the sheet tap the blue "
        "'Update CV' (or 'Upload CV') button and wait until the sheet closes. "
        "Report the file name and the line under it in the 'CV / Resume' "
        "section.",
        expected_output=(
            'JSON: {"cv_file_name": string, "cv_source_line": string}'
        ),
    )
    assert report["cv_file_name"].lower().endswith(".pdf")
    assert report["cv_source_line"] == "Uploaded for this internship"


@pytest.mark.native
@pytest.mark.error_path
async def test_tc20_upload_offline_shows_the_error(artemis):
    push_sample_cv()
    set_network(False)
    try:
        report = await run_case(
            artemis,
            "TC-20",
            f"{SIGNED_IN} The device is offline. {OPEN_APPLY_FORM} In the "
            "'CV / Resume' section tap 'Replace' (or 'Upload CV'), tap "
            f"'Choose file' and choose '{SAMPLE_CV_NAME}' in the Android file "
            "picker. Tap the blue 'Update CV' (or 'Upload CV') button and "
            "wait up to 60 seconds for an error message above that button. "
            "Report the error message.",
            expected_output='JSON: {"error_message": string}',
        )
    finally:
        set_network(True)
    assert report["error_message"] == (
        "We could not upload the file. Check your connection and try again."
    )
