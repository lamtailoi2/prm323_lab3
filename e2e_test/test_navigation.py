"""TC-02 top-level navigation: every tab opens and stays reachable."""

from conftest import SIGNED_IN, run_case

TABS = ["Home", "Search", "Saved", "Applications", "Profile"]


async def test_tc02_each_tab_opens_its_screen(artemis):
    report = await run_case(
        artemis,
        "TC-02",
        f"{SIGNED_IN} Tap the bottom navigation items in this order: Search, "
        "Saved, Applications, Profile, Home. After each tap, note the title "
        "shown in the top app bar and which bottom navigation item is "
        "highlighted.",
        expected_output=(
            'JSON: {"visits": [{"tapped": string, "app_bar_title": string, '
            '"selected_tab": string}]}'
        ),
    )
    visits = report["visits"]
    assert [v["tapped"] for v in visits] == TABS[1:] + TABS[:1]
    for visit in visits:
        assert visit["selected_tab"] == visit["tapped"]
        assert visit["app_bar_title"] == visit["tapped"]
