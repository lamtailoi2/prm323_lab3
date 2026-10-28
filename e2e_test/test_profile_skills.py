"""TC-17 Profile upkeep: add a skill from Profile (Flow 2d "Edit skills" target)."""

from conftest import SIGNED_IN, run_case


async def test_tc17_add_skill_from_profile(artemis):
    report = await run_case(
        artemis,
        "TC-17",
        f"{SIGNED_IN} Tap 'Profile' in the bottom navigation. In 'Technical "
        "skills', if a 'Docker' tag is shown, tap 'Add skill', remove 'Docker' "
        "from 'Selected skills', tap 'Save changes' and wait for the sheet to "
        "close. Then tap 'Add skill', type 'dock' in the search field, tap the "
        "'Docker' chip and tap 'Save changes'. When the sheet has closed, read "
        "every tag listed under 'Technical skills'.",
        expected_output=(
            'JSON: {"sheet_closed": boolean, "section_title": string, '
            '"skills": [string]}'
        ),
    )
    assert report["sheet_closed"] is True
    assert report["section_title"] == "Technical skills"
    assert "Docker" in report["skills"]
