# AI-assisted code review

AI finds; we decide (Lab 3 §8). This file holds the review record in the Appendix C format, the AI tool disclosure, and the review process rules.

## Requirements (Lab 3 §8)

- [ ] At least one AI review tool run on **pull requests** (not the whole repo); tool output saved in `evidence/code-review/`.
- [ ] ≥ **5 findings** tied to a file and line, covering ≥ **2 kinds**: bug, security, architecture (MVVM rule broken), performance, test gap, maintainability.
- [ ] A decision for every finding (accepted / modified / rejected) with a valid reason: a requirement in the Lab 3 handout, a rule in §5, a measurable effect (crash, latency, rebuild count) or a real constraint (scope, time, API limits). "The AI said so" and "I didn't like it" are not reasons.
- [ ] ≥ **3 fixes**, each in **its own commit naming the finding ID** (e.g. `fix(CR-01): move SerpAPI call out of SearchScreen`), linked below.
- [ ] Every AI tool used in the lab disclosed (table at the end).

## Process rules

**At most 3 AI review rounds per pull request.** This is a cap, not a quota: stop as soon as no blocker or major finding remains (often after `R1`). After `R3` the agent stops, and any open findings go to a human reviewer.

**Review only the changes:**

| Round | Input |
|---|---|
| `R1` | The PR diff only: `git diff main...HEAD` |
| `R2`, `R3` | Only the diff since the last reviewed commit (`git diff <last-reviewed-sha>..HEAD`) plus the open findings |

- Read code outside the diff only when a changed line cannot be judged without it, and only that part.
- Record the reviewed SHA range per round. Do not re-report findings already decided.

## Review record (Appendix C)

| ID | Tool | File:line | Kind | Finding (summary) | Decision | Reason | Fix commit | PR / round |
|---|---|---|---|---|---|---|---|---|
| CR-01 | | | | | | | | |

### Per-PR log

```markdown
### PR #__: <title>  (reviewer tool: __, date: __)
- R1 · reviewed `main...<sha>` → findings CR-__ … CR-__
- R2 · reviewed `<sha>..<sha>` (only if a blocker / major remained)
- Escalated to human after R3: <finding IDs + decision> (if any)
- flutter analyze → <result>; flutter test → <passed/total>
```

## AI tools used (disclosure)

| Tool | Version / model | Used for | Where recorded |
|---|---|---|---|
| Google Stitch | — | Lab 2 screen generation and refinement | Lab 2 `ai/ai-design-log.md` |
| Claude Code | Opus 5.5 (`claude-opus-5-5`) | Repository initialization: design tokens, shared widgets, services, routing, tests, documentation; requirement review against the Lab 3 handout | [`implementation-ai-log.md`](records/implementation-ai-log.md) |
| OpenCode | `deepseek-v4.1-flash-free` | Home UI implementation, SerpAPI → Firestore sync function, rules and documentation (P-18); Saved list and the Home Save Toggle (P-21, P-22) | [`implementation-ai-log.md`](records/implementation-ai-log.md) |
| Google ARTEMIS | commit `351ca84` + model on the host | End-to-end test execution and the exploratory session | [`test-plan.md`](test-plan.md) |
| *AI code review tool* | *to fill (e.g. CodeRabbit, Copilot code review)* | *PR review* | this file |
