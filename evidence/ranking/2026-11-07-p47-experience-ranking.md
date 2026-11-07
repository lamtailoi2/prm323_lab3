# P-47: Experience band and ranking tiebreaker (2026-11-07)

Scope: `docs/records/implementation-ai-log.md` P-47, `docs/design-traceability.md`
DC-29/DC-30, `docs/records/handoff-gaps.md` G-23.

## What the evidence covers

- `ExperienceRange` in `lib/models/user_profile.dart`: `none` / `underOne` /
  `oneToTwo` / `twoPlus`, labels `No experience` / `Under 1 year` /
  `1–2 years` / `2+ years`, stored as `none` / `under_one` / `one_to_two` /
  `two_plus`. Absent field = `null` ("Not set"), which is different from an
  explicit `none`.
- `InternshipPreferences` reads, writes, compares and hashes `experience`;
  a legacy document without the field reads as `null`.
- `EditPreferencesViewModel` seeds the band, clears it when the selected chip
  is tapped again (separate `hasExperience` sentinel), keeps it while other
  fields change, and counts it once in `profile_update.item_count` only when
  set.
- `recommendationScore` is unchanged: role + shared skills. Experience is only
  a tiebreaker in `HomeViewModel`: score desc → level match desc →
  `compareBySyncRank`. Nothing is filtered.
- Bands: `none` → {Intern}; `under_one` → {Intern, Fresher}; `one_to_two` →
  {Fresher, Junior}; `two_plus` → {Junior}.
- Target roles: `Data / AI` and `DevOps / Cloud` were added; labels no longer
  carry the " Intern" suffix (DC-29).

## Verification (automated)

| Command | Result |
|---|---|
| `dart format lib test` | 174 files, 0 changed after the final edits |
| `flutter analyze` | No issues found! |
| `flutter test` | 571 tests, all passed (Run 23) |

Key regression tests:

- `test/features/home/home_viewmodel_test.dart` › `experience tiebreaker`:
  a matching level beats a better sync rank; no experience answer keeps the
  sync order; a level cannot lift a lower role/skill score above a better
  match.
- `test/core/utils/recommendation_test.dart`: level matrix and the guarantee
  that experience does not change the role + skill score.
- `test/features/profile/profile_viewmodels_test.dart`: clear, other-field
  edits keep the draft, save + `item_count`, failed save.
- `test/models/user_profile_test.dart`: storage values, legacy profile,
  equality/hashCode.
- `test/features/profile/profile_screen_test.dart`: Experience group and the
  360/412 dp sheet scroll, saved `1–2 years` tag, four "Not set" groups.

## Not verified here

No device/emulator screenshot and no Firestore round trip: this machine has no
device or Firebase project. `profile_update.item_count` is not captured in
DebugView yet. These are listed in Run 23.
