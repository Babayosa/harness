---
name: goal
description: "Use when the user asks to execute a goal autonomously and keep working until a verified end state — phrasings like run this goal, keep going until, or do this autonomously. Use goal-creator when the user only wants a goal prompt drafted or tightened. Not for: drafting or tightening a goal prompt without executing; prompt rewriting."
argument-hint: "<a finished goal contract, OR a rough task to run autonomously>"
user-invocable: true
---

# Goal (executor)

`/goal` runs a **completion contract**: work, check evidence, continue or complete, stop only on a defined condition. It does not rewrite the request back at the user. It does the work.

The only case to stop and redirect to `/goal-creator` is when the *sole* artifact the user wants is a formatted goal prompt with no other work to do (e.g., "draft me a goal for X", "show me the goal prompt", or they literally type `/goal-creator`). A request that asks to tighten the wording *and then run it* is not that case: treat the tightening as the silent upgrade step in Step 1 and execute. When unsure, execute.

## First: is this even a goal?

Apply the contract machinery unless the entire request can be satisfied in a single tool call or one prose paragraph with no iteration — a one-line edit, a lookup, a single-answer question. If the task touches more than one file, has any multi-step dependency, or needs iterate-and-verify, it is a goal. **When in doubt, apply the contract:** overhead on a simple task is cheap; skipping the contract on real work causes failure. Do not use "it has a natural stop" to wave off substantive multi-step work. A goal *about* reviewing or auditing code is still a goal — run it.

Trivial requests: answer directly and stop.

## Step 1 — Establish the contract (silent, then 2-3 lines out loud)

Every goal runs against a six-part contract. Derive all six before acting:

1. **Outcome** — what must be true when the work is done.
2. **Verification surface** — the concrete evidence that proves it: a test suite, build, benchmark threshold, command output, generated artifact, or inspected source. Name it specifically. For research/reproduction goals the verification surface IS a tiered ledger (see Research goals); define it here, not at report time.
3. **Constraints** — what must NOT regress or change while reaching the outcome.
4. **Boundaries** — which files, modules, tools, repos, or resources are in scope.
5. **Iteration policy** — how the next action is chosen after each attempt.
6. **Blocked stop condition** — what counts as "no defensible path remains," what to report, and the single next input or decision that would unblock progress.

**If the input is already a complete, well-formed contract:** do not reformat, restructure, or "improve" it. "Derive all six" here means map the existing text to the six components mentally — do not re-emit them or change the user's phrasing. Adopt every constraint, phase boundary, verification step, and stop-and-report instruction exactly as written. If the input contains commentary outside a fenced code block (for example a "Why it works" section from `/goal-creator`), treat only the fenced contract as operative and ignore the commentary. State the objective and the first concrete step in one or two lines, then begin.

**If the input is rough or underspecified:** silently upgrade it into the six-part contract. Infer the six parts from the request and the working context (repo state, `~/CLAUDE.md`, files present, prior decisions), then begin immediately — do not stop for confirmation.

**The one exception (the only permitted pause):** if no verification surface is inferable at all — the request is a pure vague-finish-line anti-pattern ("make it better", "improve performance", "clean this up", "refactor X") with no metric, threshold, or testable target derivable from the request or working context — do **not** invent a fake metric and silently run against it. That is the Goodhart trap. Ask exactly one targeted question via AskUserQuestion to pin the missing verification surface, **wait for the answer**, then proceed. This is the single pause point in the entire run; everything else runs without stopping. If you are unsure whether an input is merely "rough" (upgrade silently and run) or "vague-finish-line" (ask once), it is vague-finish-line: the test is purely whether a concrete verification surface is derivable. A "no questions / just proceed" instruction does not waive this one question — only an explicit user instruction to use your best judgment on the success metric does.

The 2-3 line summary you show the user must surface at minimum the **outcome**, the **verification surface**, and any **non-obvious constraint or stop condition**, so the user can course-correct before a long run. Do not narrate the six-part derivation as a worksheet.

## Step 2 — Execute under the iteration policy

Loop: act → gather evidence → decide next action → repeat.

- After each material attempt hold an internal ledger line: **what changed, what the evidence showed, the next best action.** Surface it only when reporting progress, switching strategy, or stopping.
- Choose the next action by expected information gain or progress toward the outcome, not by lowest effort.
- **No-progress check (run every iteration):** an iteration that reasons over evidence already gathered, or processes a fresh tool result toward the next action, IS progress. But if two consecutive iterations each produce no tool call AND no new evidence beyond what is already in the ledger, do not re-enter the loop — go straight to Step 4 as blocked. This prevents spinning without cutting off legitimate synthesis passes.
- Respect any phase boundaries or gates the contract specifies. If it says plan-and-gate first, do that before touching anything.

## Step 3 — Completion is evidence-based, never belief-based

Declare the goal complete **only when the named verification surface confirms it** — tests green, build passing, benchmark threshold met, artifact produced and checked, source inspected. "It is probably done" is not completion. Before declaring done, state the evidence: command run, result, files changed.

## Step 4 — Stop conditions

Stop and report (do not silently spin) when any of these holds:

- **Success** — verification surface confirms the outcome. Report what was achieved and the evidence.
- **Blocked** — no defensible path remains within the boundaries/constraints, or the no-progress check tripped. Report: paths attempted, evidence gathered, the specific blocker, and the single next input or decision that would unblock progress.
- **Budget/scope limit** — if the run hits a length, time, or scope limit, stop substantive work, summarize concrete progress and remaining blockers, and name the next useful step. Hitting a limit is NOT completing the objective; never report it as success.

Never overclaim. An approximate or proxy result is reported as approximate, with the gap to the true outcome stated explicitly.

## Research goals

For investigation/reproduction goals, define evidence tiers at Step 1 and keep a ledger. Per claim:

```
Claim:                <the specific thing being tested>
Route:                <method used to test it>
Evidence surface:     <what was actually inspected/run>
Status:               reproduced | approximate | blocked | uncertain
Remaining uncertainty:<what is still unknown>
```

The final report must separate **reproduced**, **approximate**, **blocked**, and **uncertain**. A close numerical match raises confidence but is not an exact reproduction; label it approximate. (This ledger format is the canonical one; `/goal-creator` mirrors it — keep them in sync.)

## Portability and environment

The six-part contract is tool-agnostic. The same prompt drives autonomous execution here or in any agent that supports a persistent goal/objective surface. Do not hardcode any specific agent's lifecycle commands or version requirements; apply the contract discipline regardless of host. When the contract text itself is reused outside Claude Code, the leading `/goal` token is invocation syntax, not part of the contract.

Honor the user's environment rules in `~/CLAUDE.md` (safety rules, fail-fast, plan-first, subagent and task-tracking conventions). They bind during goal execution exactly as in any other session; this skill does not restate or override them.

## Style

No emojis unless asked. No em dashes in prose written for the user. The work and its evidence are the deliverable; commentary is minimal. Never narrate the silent contract derivation.
