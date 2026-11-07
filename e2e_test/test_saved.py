"""TC-08 Flow 2e Save: Save from Detail → Saved → open it → Unsave."""

from conftest import SIGNED_IN, run_case

SAVED_COUNT = (
    "the number in the line that ends with 'saved' above the list (0 if the "
    "screen says 'No saved internships yet')"
)


async def test_tc08_save_then_unsave(artemis):
    # Counts are compared before / after instead of emptying Saved first, so
    # the account keeps its saved listings; the case unsaves only the card it
    # saved, so the account ends as it started.
    # Saved is ordered by posting date, not by when it was saved, so the
    # listing is found by its title.
    # Not checked here: `Undo` and the `Saved to your list` Snackbar. Each
    # ARTEMIS step (screenshot + model call) takes 5–15 s and the Snackbar
    # shows for 4 s (design-system), so the agent misses Undo and misreads the
    # message. Widget tests cover both (`saved_screen_test.dart`,
    # `internship_detail_screen_test.dart`).
    report = await run_case(
        artemis,
        "TC-08",
        f"{SIGNED_IN} Do these steps in order and do not skip any. "
        f"1) Tap 'Saved' in the bottom navigation and note {SAVED_COUNT}. "
        "2) Tap 'Search', type 'Python' in the search field and tap 'Find "
        "Internships'. 3) Tap the first internship card that has no 'Applied' "
        "badge and whose bookmark is not filled; note its job title. 4) On the "
        "detail screen tap 'Save' at the bottom left and read the visible text "
        "of that same button. 5) Tap 'Saved' in the bottom navigation and note "
        f"{SAVED_COUNT} again. 6) Find the card with the noted title (scroll "
        "if needed) and TAP THE CARD itself to open it; note the job title on "
        "that detail screen and whether its bottom button is 'Apply now' or "
        "'View application'; then tap the Back arrow. 7) Back on Saved, tap "
        "the filled bookmark of the card with the noted title once and read "
        "the message at the bottom of the screen. Do not tap 'Undo' and never "
        "tap the bookmark of any other card. 8) Note the saved number and "
        "whether the card with the noted title is still in the list.",
        expected_output=(
            'JSON: {"saved_before": number, "card_title": string, '
            '"button_after_save": string, "saved_after_save": number, '
            '"saved_card_found": boolean, "opened_from_saved_title": string, '
            '"detail_button": string, "remove_message": string, '
            '"saved_after_unsave": number, "card_still_listed": boolean}'
        ),
    )
    # The agent may read the button's accessibility label ("Saved. Remove
    # from saved") instead of its text.
    assert report["button_after_save"].strip().startswith("Saved")
    assert report["saved_after_save"] == report["saved_before"] + 1
    assert report["saved_card_found"] is True
    # Proves the card was really opened from Saved (step 6).
    assert report["opened_from_saved_title"] == report["card_title"]
    assert report["detail_button"] == "Apply now"
    assert report["remove_message"].strip().lower() == "removed from saved"
    assert report["saved_after_unsave"] == report["saved_before"]
    assert report["card_still_listed"] is False
