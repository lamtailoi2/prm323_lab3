"""TC-03 Flow 1 search + filter, TC-04 Flow 1a no results → Clear filters."""

import re

from conftest import (
    SIGNED_IN,
    enable_analytics_debug,
    logged_analytics_events,
    run_case,
)

SEARCH_TAB = (
    "Tap 'Search' in the bottom navigation. Tap the search field "
    "'Search role, company, skill', type '{term}' and tap 'Find Internships'."
)


async def test_tc03_search_then_job_type_filter_lists_internships(artemis):
    enable_analytics_debug()
    report = await run_case(
        artemis,
        "TC-03",
        f"{SIGNED_IN} {SEARCH_TAB.format(term='Intern')} On the results screen "
        "tap the 'Filters' button next to the search field. In the Filters "
        "sheet tap 'Job type' and choose 'Internship', then tap the blue "
        "'Show … results' button. Report the results count line (e.g. "
        "'38 internships found'), the labels of the active filter chips above "
        "it, and the title of the first internship card.",
        expected_output=(
            'JSON: {"results_count_text": string, "active_chips": [string], '
            '"first_card_title": string}'
        ),
    )
    count = re.search(r"(\d+) internships? found", report["results_count_text"])
    assert count and int(count.group(1)) > 0
    assert "Internship" in report["active_chips"]
    assert "Intern" in report["active_chips"]
    assert report["first_card_title"].strip()
    # Analytics plan rows 4-5 reached Firebase (debug mode).
    events = logged_analytics_events()
    assert "search" in events
    assert "search_filter_apply" in events


async def test_tc04_no_results_then_clear_filters(artemis):
    report = await run_case(
        artemis,
        "TC-04",
        f"{SIGNED_IN} {SEARCH_TAB.format(term='zzqx intern')} Report the "
        "title and the button of the empty state. Then tap that button and "
        "report the results count line that appears.",
        expected_output=(
            'JSON: {"empty_title": string, "empty_button": string, '
            '"results_count_after_clear": string}'
        ),
    )
    assert report["empty_title"] == "No internships found"
    assert report["empty_button"] == "Clear filters"
    count = re.search(
        r"(\d+) internships? found", report["results_count_after_clear"]
    )
    assert count and int(count.group(1)) > 0
