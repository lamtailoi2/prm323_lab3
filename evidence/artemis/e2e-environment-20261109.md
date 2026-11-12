# ARTEMIS runs — 2026-11-09 (TC-18, full email flow)

Status: **TC-18 passed 3/3** on the profile build with `gemini-3.5-flash-lite`. One smoke run passed before the counted batch and is not counted. The earlier failures were test wording (the To placeholder read as a value, the CV block below the fold, the hand-off not asserted) and a 180 s model timeout on `gemini-3.1-flash-lite`; none was an app defect. The counted runs opened Gmail, sent the draft to the test account, returned to Internly, pressed `I've sent it`, and reached `Application submitted!`.

The 15 lines of `e2e_test/artifacts/runs.jsonl` (the preceding TC-02 run and the 14 TC-18 runs) are copied to [`runs-20261109.jsonl`](runs-20261109.jsonl). Every counted run was checked against its ARTEMIS step history.

The next batch (TC-06, TC-07, TC-09, TC-14, TC-17 and TC-19, late 2026-11-09 to 2026-11-10) is recorded in [`e2e-environment-20261110.md`](e2e-environment-20261110.md).

## Environment

| Item | Value |
|---|---|
| App | Profile build installed 2026-11-09 21:34 from `dev` `ac7322e` (CV library merged) |
| Suite | Working tree with the P-84 TC-18/TC-19 changes |
| Device | `emulator-5554`, `Medium_Phone_API_37.0`, API 37, `-gpu swiftshader_indirect` (software GPU: the previous GPU made `screencap` and `uiautomator dump` hang) |
| Gmail | Signed in as `lap262005@gmail.com`; TC-18 replaces the recipient with this address before Send, so no company receives a test email |
| ARTEMIS | `351ca84` + [`artemis-local.patch`](../../e2e_test/artemis-local.patch); primary `gemini-3.5-flash-lite`, fallback `gemini-3.1-flash-lite` (swapped after the 3.1 timeouts) |
| API key | Free tier |
| Recording | OBS Studio, full desktop (emulator + ARTEMIS console + terminal), one file per test |
| Video | `e2e_test/artifacts/recordings/20261109/TC-18_Compose_CV.mp4`, 28,372,923 bytes (27.1 MiB); upload to the [Record Artemis Test - PRM323](https://drive.google.com/drive/folders/1B44bE_K5JY06eAhTU0FrJZrbmcfe7LCf) folder pending |

Commands (from `e2e_test/`):

```bash
uv run pytest test_apply_form.py -k tc18 --count 1 -v   # smoke, not counted
uv run pytest test_apply_form.py -k tc18 --count 3 -v   # counted; OBS records the batch
```

## Runs

| # | Test | Trace | pytest | Time (s) | Note |
|---|---|---|---|---|---|
| 1 | TC-18 | `f59f986c` | failed | 438.7 | wrong element: To helper text read as the draft banner |
| 2 | TC-18 | `11be6c72` | failed | 114.9 | same |
| 3 | TC-18 | `8d925cec` | failed | 180.8 | same |
| 4 | TC-18 | `58e68828` | failed | 291.5 | CV block reported not visible |
| 5 | TC-18 | `fa6cca85` | failed | 178.6 | no structured output (`assert {}`) |
| 6 | TC-18 | `b68df440` | failed | 225.0 | CV block reported not visible |
| 7 | TC-18 | `4d27dad3` | failed | 154.9 | `Change CV` below the fold |
| 8 | TC-18 | `7ec30db6` | failed | 143.6 | CV block reported not visible |
| 9 | TC-18 | `82cb8ea0` | failed | 190.6 | `Open email app` reported no visible result |
| 10 | TC-18 | `3658371e` | **passed** | 363.2 | smoke of the full flow; not counted |
| 11 | TC-18 | `f2397408` | failed | 455.5 | environment: 3.1 `TimeoutError: LLM call timed out after 180 seconds` |
| — | TC-18 | `87130171` | not written | 184.1 (session) | same 180 s timeout; the batch was stopped |
| 12 | TC-18 | `5e99ca80` | **passed** | 150.2 | counted |
| 13 | TC-18 | `2adcba49` | **passed** | 148.0 | counted |
| 14 | TC-18 | `fd62333f` | **passed** | 157.3 | counted |

## Result (counted runs)

| Test | Passed | Average time (s) | Counted traces |
|---|---|---|---|
| TC-18 | 3/3 | 151.8 | `5e99ca80`, `2adcba49`, `fd62333f` |

What the counted runs showed: the compose screen drafted the subject and letter (`Drafted from the job description and your Profile…`); `Open email app` opened Gmail with the same subject and body; the agent replaced Gmail's `To` with `lap262005@gmail.com`, pressed `Send` and saw the sent state; Back returned to Internly; `I've sent it` reached `Application submitted!` with the same title (`Intern Business Analysis Implementation`) and company (`ISOFH`). Logcat contained `apply_start` and `application_create`.

## Recording

| Test | Video | Counted runs in it |
|---|---|---|
| TC-18 | `TC-18_Compose_CV.mp4` (27.1 MiB, local `e2e_test/artifacts/recordings/20261109/`) | `5e99ca80`, `2adcba49`, `fd62333f` |

## Why runs failed or were not counted

- **Runs 1–3 (`f59f986c`, `11be6c72`, `8d925cec`).** The instruction said "the notice above the To field", which is the To helper text. The draft banner is at the top of the form. The case now reads the banner there.
- **Runs 4, 6, 8 (`58e68828`, `b68df440`, `7ec30db6`) and run 7 (`4d27dad3`).** The CV block is below the long cover-letter field; the agent reported "not visible" instead of scrolling every time. The CV and `Change CV` checks moved to TC-19, which scrolls to the block explicitly.
- **Run 9 (`82cb8ea0`).** The agent tapped `Open email app` but reported no mail app, no message and no snackbar. The case now follows Gmail, sends and asserts the return to the app.
- **Run 5 (`fa6cca85`).** Reporting miss: no JSON in `report_task_status` (`assert {}`). It is not counted.
- **Run 11 (`f2397408`) and session `87130171`.** Environment: `gemini-3.1-flash-lite` was overloaded; the daemon log shows `TimeoutError: LLM call timed out after 180 seconds`. Primary/fallback swapped to `gemini-3.5-flash-lite`; the counted runs then passed 3/3.
- **Run 10 (`3658371e`).** Smoke run of the full flow before the counted batch; it passed but is not counted. The three counted traces are listed above.
