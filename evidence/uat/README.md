# UAT evidence

Recordings, screenshots and questionnaires from the sessions in [`docs/uat-plan.md`](../../docs/uat-plan.md). Each row in [`docs/records/uat-results.md`](../../docs/records/uat-results.md) links to a file here.

| What | File name | Notes |
|---|---|---|
| Screen recording | `uat-<participant>-<yyyymmdd>.mp4` | Whole session, screen + audio; the phone's recorder or `adb shell screenrecord` |
| Failure screenshots | `uat-<participant>-<scenario>-<yyyymmdd>.png` | Only the states that failed, plus the error text |
| Questionnaire | `uat-<participant>-questionnaire-<yyyymmdd>.pdf` | Scan/photo of the signed paper form |
| Consent | kept by the team, not committed | Contains a name and signature |

Rules:

- Participants stay anonymous in the files and in the results table (`E1`, `E2`, `E3`, `R1-A`, `R1-B`).
- Test data only: no real CVs, phone numbers, addresses or other personal data on screen.
- Keep the raw recording unedited; if it must be trimmed, keep the untrimmed original too and say so in the results table.
- Screen recordings are large: if they are not committed, say where they are stored in the results row so the grader can ask for them.
