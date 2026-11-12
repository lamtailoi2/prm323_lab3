"""TC-11 Export and upload: a PDF report of the student's applications."""

from conftest import SIGNED_IN, run_case


async def test_tc11_export_application_report(artemis):
    report = await run_case(
        artemis,
        "TC-11",
        f"{SIGNED_IN} Tap 'Profile' in the bottom navigation, scroll to "
        "'Diagnostics' and tap 'Firebase demo'. In the 'Open' section tap "
        "'Report export'. On the Report export screen, read the application "
        "count on the 'Application report' card and tap 'Export report'. Wait "
        "until the button is tappable again (up to 60 seconds) and the upload "
        "finishes. Then read 'Your reports': every file name, its date line and "
        "whether each row has an 'Open' action. Also read the 'Last exported' "
        "line if it is shown.",
        expected_output=(
            'JSON: {"application_count": string, "export_finished": boolean, '
            '"last_exported": string, "report_files": [string], '
            '"report_rows_have_open": boolean}'
        ),
    )
    assert report["export_finished"] is True
    assert report["application_count"] != ""
    assert report["report_files"], "no report was listed after the export"
    assert any(
        name.startswith("application-report-") and name.endswith(".pdf")
        for name in report["report_files"]
    )
    assert report["report_rows_have_open"] is True
