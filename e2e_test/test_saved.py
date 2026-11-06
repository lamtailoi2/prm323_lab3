"""TC-08 Flow 2e Save: Save from Detail → Saved → open it → Unsave → Undo."""

from conftest import SIGNED_IN, run_case

SAVED_COUNT = (
    "the number in the line that ends with 'saved' above the list (0 if the "
    "screen says 'No saved internships yet')"
)


async def test_tc08_save_then_unsave_with_undo(artemis):
    # Counts are compared before / after instead of emptying Saved first, so
    # the account keeps its saved listings.
    # Saved is ordered by posting date, not by when it was saved, so the
    # listing is found by its title. Only that card is ever unsaved: a missed
    # Undo (the Snackbar lasts about 4 s) then removes only what the test added.
    report = await run_case(
        artemis,
        "TC-08",
        f"{SIGNED_IN} Tap 'Saved' in the bottom navigation and note "
        f"{SAVED_COUNT}. Tap 'Search', type 'Python' in the search field and "
        "tap 'Find Internships'. Tap the first internship card that has no "
        "'Applied' badge and whose bookmark is not filled. Note its job title. "
        "On the detail screen tap 'Save' at the bottom and read the message "
        "that appears at the bottom of the screen. Tap 'Saved' in the bottom "
        f"navigation and note {SAVED_COUNT} again. Find the card with the "
        "noted title in the Saved list (scroll if needed; it is not "
        "necessarily the first one) and note whether it is there. Tap it, read "
        "whether the button at the bottom is 'Apply now' or 'View "
        "application', then tap the Back arrow. Never tap the bookmark of any "
        "other card. On the card with the noted title tap its filled bookmark "
        "and right after it, as one quick sequence, tap 'Undo' in the message "
        "at the bottom (it disappears after about 4 seconds); read the message "
        "text. Then note the saved number and whether the card with the noted "
        "title is in the list again.",
        expected_output=(
            'JSON: {"saved_before": number, "card_title": string, '
            '"save_message": string, "saved_after_save": number, '
            '"saved_card_found": boolean, "detail_button": string, '
            '"remove_message": string, "saved_after_undo": number, '
            '"card_back_after_undo": boolean}'
        ),
    )
    assert report["save_message"] == "Saved to your list"
    assert report["saved_after_save"] == report["saved_before"] + 1
    assert report["saved_card_found"] is True
    assert report["detail_button"] == "Apply now"
    assert report["remove_message"] == "Removed from Saved"
    assert report["saved_after_undo"] == report["saved_after_save"]
    assert report["card_back_after_undo"] is True
