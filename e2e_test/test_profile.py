"""TC-12 Remote Config: the value shown on Firebase demo drives Home."""

import re

from conftest import SIGNED_IN, run_case

SOURCES = ("From Firebase", "In-app default", "Static value")


async def test_tc12_remote_config_limits_home_recommended(artemis):
    # Works with any console value: the case reads the value the app holds
    # (Profile → Firebase demo) and checks Home against it. Before an
    # evidence run, set `home_recommended_limit` to a non-default value in the
    # Firebase console (e.g. 3; the in-app default is 5) so the source is
    # "From Firebase".
    report = await run_case(
        artemis,
        "TC-12",
        f"{SIGNED_IN} Tap 'Profile' in the bottom navigation, scroll down and "
        "tap 'Firebase demo'. In the 'Remote Config' section find 'Home · "
        "Recommended cards' and read the line under its key name "
        "'home_recommended_limit' (it looks like '5 · In-app default'). Tap "
        "the Back arrow, tap 'Home' in the bottom navigation and scroll down "
        "slowly. Count the internship cards between the heading 'Recommended "
        "for you' and the heading 'Recently Posted'.",
        expected_output=(
            'JSON: {"value_line": string, "recommended_cards": integer}'
        ),
    )
    match = re.fullmatch(r"\s*(\d+)\s*·\s*(.+?)\s*", report["value_line"])
    assert match, f"TC-12: unexpected value line {report['value_line']!r}"
    limit, source = int(match.group(1)), match.group(2)
    assert source in SOURCES
    # Home shows exactly that many cards (the pool holds more IT listings).
    assert report["recommended_cards"] == limit
