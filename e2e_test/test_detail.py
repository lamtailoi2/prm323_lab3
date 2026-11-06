"""TC-05 Flow 1 → Internship Detail, and Back keeps the results."""

from conftest import SIGNED_IN, run_case


async def test_tc05_first_result_opens_its_detail(artemis):
    # Other cases apply to and save listings, and an application cannot be
    # deleted, so the case takes the first card that is still neither applied
    # to nor saved: its detail must show `Apply now` and `Save`.
    report = await run_case(
        artemis,
        "TC-05",
        f"{SIGNED_IN} Tap 'Search' in the bottom navigation, type 'Intern' in "
        "the search field and tap 'Find Internships'. Find the first internship "
        "card that has no 'Applied' badge and whose bookmark is not filled "
        "(scroll down if needed). Note its job title and company, then tap "
        "that card. On the next screen report the top app bar title, the job "
        "title, the company name and whether the 'Apply now' and 'Save' "
        "buttons are visible. Then tap the Back arrow and report the text in "
        "the search field.",
        expected_output=(
            'JSON: {"card_title": string, "card_company": string, '
            '"detail_app_bar_title": string, "detail_title": string, '
            '"detail_company": string, "apply_now_visible": boolean, '
            '"save_visible": boolean, "search_text_after_back": string}'
        ),
    )
    assert report["detail_app_bar_title"] == "Internship details"
    assert report["detail_title"] == report["card_title"]
    assert report["detail_company"] == report["card_company"]
    assert report["apply_now_visible"] is True
    assert report["save_visible"] is True
    # Detail is pushed, so Back returns to the same results.
    assert report["search_text_after_back"] == "Intern"
