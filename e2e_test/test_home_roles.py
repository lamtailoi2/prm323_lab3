"""TC-16 Home role discovery: chips filter locally and "All roles" opens Search."""

from conftest import SIGNED_IN, run_case


async def test_tc16_home_role_chip_filters_and_all_roles_opens_search(artemis):
    report = await run_case(
        artemis,
        "TC-16",
        f"{SIGNED_IN} On Home, read the section heading above the role chips and "
        "the action label on its right. Tap the 'Frontend' role chip. Report "
        "which role is selected, whether that chip shows a check mark, and the "
        "titles of the recommended internship cards currently visible. Then tap "
        "'All roles'. Report the title in the top app bar.",
        expected_output=(
            'JSON: {"role_heading": string, "action_label": string, '
            '"selected_role": string, "selected_role_has_check": boolean, '
            '"visible_job_titles": [string], "after_all_roles_screen_title": '
            "string}"
        ),
    )
    assert report["role_heading"] == "Browse by Role"
    assert report["action_label"] == "All roles"
    assert report["selected_role"] == "Frontend"
    assert report["selected_role_has_check"] is True
    assert report["visible_job_titles"]
    assert report["after_all_roles_screen_title"] == "Search"
