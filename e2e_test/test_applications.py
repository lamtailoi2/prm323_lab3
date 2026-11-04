"""TC-09/TC-10 Flow 3 Track: Application Detail and its error recovery."""

from conftest import SIGNED_IN, run_case


async def test_tc09_application_detail_matches_the_list(artemis):
    report = await run_case(
        artemis,
        "TC-09",
        f"{SIGNED_IN} Tap 'Applications' in the bottom navigation. If the "
        "screen says 'You have not applied yet', create an application first: "
        "tap 'Home', open the first internship card, tap 'Apply now', tap "
        "'Continue to review', wait for the CV check to finish, tap 'Submit "
        "application', then tap 'View my applications'. Read the first "
        "application card: its position, company, the text that starts with "
        "'Applied', and its status badge. Then tap the card to open "
        "'Application Detail' and read the position, company and status badge "
        "shown there.",
        expected_output=(
            'JSON: {"list": {"position": string, "company": string, '
            '"applied_text": string, "status": string}, "detail": '
            '{"position": string, "company": string, "status": string}}'
        ),
    )
    listed = report["list"]
    detail = report["detail"]

    assert listed["position"].strip()
    assert listed["company"].strip()
    assert listed["applied_text"].strip()
    assert listed["status"].strip()
    assert detail["position"] == listed["position"]
    assert detail["company"] == listed["company"]
    assert detail["status"] == listed["status"]


async def test_tc10_application_list_recovers_after_airplane_mode(artemis):
    report = await run_case(
        artemis,
        "TC-10",
        f"{SIGNED_IN} Open the Quick Settings panel with a swipe down from the "
        "top of the screen, turn on Airplane mode, close the panel, then tap "
        "'Applications' in the bottom navigation and wait a few seconds. Note "
        "whether an error message and a 'Retry' button are visible. Open Quick "
        "Settings again, turn Airplane mode off, return to the app and tap "
        "'Retry'. Wait until the list loads and note whether an application "
        "card is visible.",
        expected_output=(
            'JSON: {"error_visible_offline": boolean, '
            '"retry_visible_offline": boolean, '
            '"list_visible_after_retry": boolean}'
        ),
    )

    assert report["error_visible_offline"] is True
    assert report["retry_visible_offline"] is True
    assert report["list_visible_after_retry"] is True
