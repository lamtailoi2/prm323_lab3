# ARTEMIS runs — 2026-11-09 night to 2026-11-10 (TC-06, TC-07, TC-09, TC-14, TC-17, TC-19)

Status: **TC-06, TC-07, TC-09 and TC-17 reached their counted 3 of 3**; **TC-14 passed 2 of 4** (two runs cancelled) and **TC-19 passed 0 of 3** (two cancelled, one failed after 10.8 s). 25 runs in total. The counted runs are the last three consecutive passes in the log; their step histories were not re-opened while writing this record.

The 25 lines were copied from the git-ignored `e2e_test/artifacts/runs.jsonl` to [`runs-20261110.jsonl`](runs-20261110.jsonl).

## Environment

| Item | Value |
|---|---|
| App | Profile build of `dev` `ac7322e` (CV library merged), installed 2026-11-09 21:34 — the same build used for the TC-18 batch |
| Suite | Working tree with the P-84 wording changes and the `_same_position` fixes, committed as `5c27ddd` on 2026-11-10 |
| Device | `emulator-5554`, `Medium_Phone_API_37.0`, API 37, `-gpu swiftshader_indirect` |
| ARTEMIS | `351ca84` + [`artemis-local.patch`](../../e2e_test/artemis-local.patch); the host was on `gemini-3.5-flash-lite` for the preceding TC-18 batch. The run log has no per-run model field |
| Recording | OBS Studio, full desktop (emulator + ARTEMIS console + terminal), one file per test |

Commands (from `e2e_test/`, one case at a time; TC-07 and TC-09 were rerun after their first title-check failure):

```bash
uv run pytest test_apply.py -k tc06 --count 3 -v
uv run pytest test_apply.py -k tc07 --count 3 -v
uv run pytest test_applications.py -k tc09 --count 3 -v
uv run pytest test_auth.py -k tc14 --count 3 -v
uv run pytest test_profile_skills.py -k tc17 --count 3 -v
uv run pytest test_apply_form.py -k tc19 --count 3 -v
```

## Runs

| # | Test | Trace | pytest | Time (s) | Note |
|---|---|---|---|---|---|
| 1 | TC-19 | `be05e6e5` | failed (cancelled) | 150.9 | first attempt; operator stopped after the CV change was observed, the To edit was removed from the case |
| 2 | TC-06 | `5dab06b9` | passed | 94.7 | counted |
| 3 | TC-06 | `038180be` | passed | 95.0 | counted |
| 4 | TC-06 | `9bd3dc18` | passed | 92.9 | counted |
| 5 | TC-07 | `c67149d6` | failed | 73.2 | card title includes the skills; exact comparison with the detail position |
| 6 | TC-07 | `a63722fb` | passed | 76.5 | |
| 7 | TC-07 | `6b816daf` | passed | 67.0 | |
| 8 | TC-07 | `e37d7261` | passed | 85.4 | counted |
| 9 | TC-07 | `38871e13` | passed | 80.2 | counted |
| 10 | TC-07 | `5116dc27` | passed | 80.4 | counted |
| 11 | TC-09 | `2c6c1c3f` | passed | 85.6 | |
| 12 | TC-09 | `cee108da` | failed | 73.2 | `startswith` compared the list card with the detail position |
| 13 | TC-09 | `fc008948` | passed | 58.0 | |
| 14 | TC-09 | `5192a465` | passed | 72.2 | counted |
| 15 | TC-09 | `f1233bb8` | passed | 61.2 | counted |
| 16 | TC-09 | `8c04b889` | passed | 64.2 | counted |
| 17 | TC-14 | `4991c7dc` | passed | 263.4 | |
| 18 | TC-14 | `0f1910f3` | passed | 295.9 | |
| 19 | TC-14 | `d84b3a90` | failed (cancelled) | 249.9 | operator stopped the run |
| 20 | TC-14 | `bec24fcb` | failed (cancelled) | 50.9 | operator stopped the run |
| 21 | TC-17 | `aacb86b6` | passed | 72.2 | counted |
| 22 | TC-17 | `23eed7a8` | passed | 78.3 | counted |
| 23 | TC-17 | `765a86e0` | passed | 75.5 | counted |
| 24 | TC-19 | `0aba4890` | failed (cancelled) | 62.2 | operator stopped the run |
| 25 | TC-19 | `83edba2d` | failed | 10.8 | agent session failed; no report returned, cause not diagnosed |

## Result (counted runs)

| Test | Passed | Average time (s) | Counted traces |
|---|---|---|---|
| TC-06 | 3/3 | 94.2 | `5dab06b9`, `038180be`, `9bd3dc18` |
| TC-07 | 3/3 | 82.0 | `e37d7261`, `38871e13`, `5116dc27` |
| TC-09 | 3/3 | 65.9 | `5192a465`, `f1233bb8`, `8c04b889` |
| TC-14 | 2/4 | 215.0 (all runs) | `4991c7dc`, `0f1910f3` |
| TC-17 | 3/3 | 75.3 | `aacb86b6`, `23eed7a8`, `765a86e0` |
| TC-19 | 0/3 | 74.6 (all runs) | `be05e6e5`, `0aba4890`, `83edba2d` |

## Recordings

| Test | Video | Size |
|---|---|---|
| TC-06 | `e2e_test/artifacts/recordings/20261109/TC-06_Apply.mp4` | 19.8 MiB |
| TC-07 | `e2e_test/artifacts/recordings/20261109/TC-07_View_application.mp4` | 16.0 MiB |
| TC-09 | `e2e_test/artifacts/recordings/20261110/TC-09_Application_Detail.mp4` | 12.8 MiB |
| TC-14 | `e2e_test/artifacts/recordings/20261110/TC-14_Sign_out.mp4` + `TC-14_Sign_out_extra.mp4` | 41.3 MiB + 5.3 MiB |
| TC-17 | `e2e_test/artifacts/recordings/20261110/TC-17_Add_skill.mp4` | 13.5 MiB |
| TC-19 | `e2e_test/artifacts/recordings/20261110/TC-19_Change_CV.mp4` | 7.3 MiB |

TC-18's recording is in the 2026-11-09 evidence file ([`e2e-environment-20261109.md`](e2e-environment-20261109.md)).

## Why runs failed or were not counted

- **TC-07 `c67149d6`.** The test compared the card title with the detail position; the card appends the skills, so `Junior Fullstack Developer TypeScript, Node.js, API` did not equal `Junior Fullstack Developer`. `test_apply.py` now uses `_same_position` (normalise, then containment); the five later runs passed.
- **TC-09 `cee108da`.** The same card-versus-detail difference, compared with `startswith`. `test_applications.py` now uses `_same_position`; the five later runs passed.
- **TC-14 `d84b3a90`, `bec24fcb`.** Cancelled by the operator during the batch. The two runs before them passed in 263.4 s and 295.9 s; no fix is implied, TC-14 still needs a counted 3/3.
- **TC-19 `be05e6e5`.** Cancelled earlier: the CV change was observed, but the To edit kept clearing/retyping, so that step was removed from the case.
- **TC-19 `0aba4890`.** Operator stopped the run.
- **TC-19 `83edba2d`.** The agent session failed after 10.8 s and returned no report; the cause is not diagnosed. The case needs the two-CV precondition seeded before the next counted batch.
