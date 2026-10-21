# Code review log (AI-assisted)

Each pull request gets one entry. Record what the AI reviewer reported, what a human decided, and the evidence. Do not mark a finding "fixed" without the commit that fixes it.

## Review round limit

**AI agents review a pull request for at most 3 rounds.** A round is one AI review pass followed by one round of fixes.

- Number each round (`R1`, `R2`, `R3`) in the entry.
- After `R3`, the agent stops reviewing that PR, even if findings remain. Open findings go to a **human reviewer**, who accepts the risk, asks for a specific fix, or rejects the finding. Record the decision in the entry.
- Do not start a "new" review on the same PR to get around the limit. A new round counts as round 4.
- Only blockers and majors justify another round. Minor and nit findings are batched into the next round or left to the human.

## Checklist (reviewers)

- [ ] Follows `AGENTS.md`: MVVM layers, Riverpod only, no Firebase in Views, tokens only.
- [ ] Every new screen state (loading / empty / error) exists and matches `design-system.md`.
- [ ] New Firestore collection → rules with field validation + emulator tests in the same PR.
- [ ] No secrets or personal data in code, logs, analytics events or test fixtures.
- [ ] Tests added: ViewModel (fakes), widget at 360 and 412 dp, model parsing for invalid data.
- [ ] `dart format`, `flutter analyze` (no issues) and `flutter test` pass; results pasted below.
- [ ] Docs updated: change log, gaps, analytics plan, fidelity check, AI log.

## Entry template

```markdown
### PR #__: <title>  (author: __, reviewer: __, date: __)

Tool / prompt: <AI tool and the exact review prompt>

#### Round R1 (of max 3)

| # | Finding (file:line) | Severity | Decision | Evidence / commit |
|---|---|---|---|---|
| 1 | | blocker / major / minor / nit | accepted · modified · rejected (why) | |

Commands run:
- flutter analyze → <result>
- flutter test → <passed / failed counts>

#### Round R2 / R3: same table, only if blockers or majors remain

#### Escalated to human (after R3, if anything is still open)

| # | Finding | Human decision (accept risk / fix / reject) | By |
|---|---|---|---|

Outcome: approved / changes requested · rounds used: _/3.
```

## Entries

_None yet. The first entry is expected with the first feature pull request._
