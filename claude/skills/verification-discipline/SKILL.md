---
name: verification-discipline
description: Use when verifying a device or server runtime fix, aggregating parallel subagent results, writing a formal Review/Evidence section, or delegating a safety mechanism such as an assertion, validator, or self-test. Not for ordinary completion claims with only static checks.
---

# Verification Discipline

## When to use / When NOT to use

**Use when:**
- Reporting "done" / "fixed" / "verified" after a device or server runtime change (RN/Expo/Metro, deploys, native modules).
- Aggregating verification results after parallel subagent work.
- Writing the "Review / Evidence" section of `tasks/todo.md`.
- Delegating a safety mechanism (assertion, purity check, validator, kill-switch).

**Do NOT use for:**
- Trivial Q&A, single factual lookups, read-only answers.
- One-line edits with no runtime surface (a rename, a doc typo). The bar for invoking the full loop: "would a wrong asserted fact here cause downstream harm?" If no, answer normally.
- Ordinary completion or merge-readiness claims that need only the general `verification-before-completion` workflow.

## Non-negotiables

- Every "done" report states an evidence level (L1/L2/L3, defined below) for each claimed capability. No unlabeled claims.
- A green build, green boot, or green typecheck is NEVER evidence a new capability works. The capability itself must fire during verification.
- Plausibility is not verification. Every asserted fact is checked against ground truth: git state, file contents, command output.
- After parallel subagent fan-out, the orchestrator re-runs the FULL gate suite centrally. Per-agent "clean" self-reports are never trusted.
- A failing gate is never "pre-existing" or "a repo convention" unless verified against the pre-change baseline.
- The red-team loop terminates only when a full iteration surfaces zero new factual errors. One finding means run the whole pass again.
- Never weaken tests, fabricate fallbacks, or swallow errors to reach green. Fail fast.
- Never dispatch parallel writes to the same artifact. One editor agent applies same-file edits sequentially.
- A delegated safety mechanism is not done until it demonstrably REJECTS a bad input (negative fixture), and the orchestrator has personally read its implementation.

## Procedures

### 1. Evidence levels (L1/L2/L3)

- **Rule:** Classify every piece of verification evidence into exactly one level and say the level out loud in the done-report:
  - **L1 — static:** diff read, grep, code inspection, typecheck/lint/build passing.
  - **L2 — runtime:** the code executed against real data (seeded DB rows, a driven UI, a live log showing the code path ran).
  - **L3 — physical device or production-equivalent:** real phone, production config, real network.
- **Why:** Different failure classes are only visible at each level. Code reading evaluates pieces in isolation; bugs live in the interaction of correct-looking pieces. Static gates cannot see rendered values.
- **Failure symptom:** A change ships as "verified" on L1 evidence and immediately misbehaves at runtime (e.g., a 7-auditor code audit that read a screen twice missed two data-flow bugs that 30 minutes of driving the real UI found instantly).
- **Verify:** The done-report contains a block like this, with proof attached:

```markdown
## Review / Evidence
- Claim: <capability X> works
- Evidence level: L2 (runtime, seeded data, simulator)
- Proof: <command + output, log excerpt, or screenshot path>
- Not verified: <what L3 would require and why it was not run>
```

### 2. Capability-fire rule (green build is not proof)

- **Rule:** Gate the verdict on the NEW capability itself firing — a worklet actually running, a Sentry upload actually completing, a Playwright assertion actually passing — not on the app building or booting.
- **Why:** Infrastructure can link a library without exercising it. A boot that never instantiates the new capability proves nothing about it. Canonical case: Reanimated 4 was installed, the iOS build and device boot were green, but no worklet existed yet — the first real `useAnimatedStyle` crashed at runtime because the required babel plugin was missing. The green boot was a false green.
- **Failure symptom:** "Phase 0 verified" followed by a crash the first time the feature is used in a later phase.
- **Verify:** Name the observable event that proves the capability fired, then observe it. Prefer runtime oracles that multiply small wrongness into visible wrongness (e.g., a derived number like a session total = sum of weight x reps) and assert on RENDERED values and PERSISTED rows, not on "the code looks right."

### 3. Red-team loop (before declaring done)

- **Rule:** For any non-trivial deliverable (plan, multi-file or code change, migration, handoff brief), after the regular pass and before declaring done, run this loop:

```text
repeat:
  1. Enumerate CONCRETE loopholes/failure modes (named and specific, not vague doubts).
  2. Verify EVERY asserted fact against ground truth (git, file contents, command output).
  3. Fix each finding.
  4. Re-check internal consistency across ALL artifacts touched
     (task list, docs, code, handoff text).
until: one full iteration surfaces zero new factual errors.
```

- **Why:** A single verification pass catches what you already suspected; the adversarial pass catches what you asserted without checking. Looping matters because fixes introduce new inconsistencies.
- **Failure symptom:** A downstream agent or the user finds a factual error in your report (a file that doesn't say what you claimed, a command that doesn't produce the output you cited).
- **Verify:** The final iteration's finding count is zero. Do not pad with cosmetic findings to look thorough; only re-loop on real issues. If the deliverable is a multi-agent strategy: self-red-team BEFORE dispatch, then after the editor agent finishes, run a verifier (greps that new text is present, old text is absent, untouched sections intact) and a red-team (contradictions, ambiguity, orphaned references) in parallel, looping until the red-team round is clean. Be transparent mid-process: when the edit count grows or a later audit surfaces a fix you missed, say so in the report — never paper over it.

### 4. Parallel fan-out: central gate re-run

- **Rule:** After any parallel multi-file fan-out, the orchestrator re-runs the FULL gate suite (e.g. `tsc && eslint && prettier`, or the project's equivalent) centrally over the whole tree. Never accept per-agent "my file is clean" or "that error is a known issue."
- **Why:** Subagents scoped to their own file read the SAME error in sibling files as proof the error is normal — circular reasoning, since all siblings were edited in the same batch. Canonical case: 9 parallel screen agents each hit the same TS2322 from one shared hook, each independently rationalized it as "a pre-existing repo convention," and all shipped. One central run exposed it; one root-cause fix in the shared hook cleared all 9.
- **Failure symptom:** N subagents report success; the central build is red with N copies of one error.
- **Verify:** One command, run once, at the repo root, after all agents return — exit code 0. If a gate fails, diff against the pre-change baseline before accepting any "pre-existing" explanation (if using stash to get the baseline: never chain a bare `git stash drop` after `pop` — pop already drops its entry on success, so the trailing drop deletes the next, unrelated stash; recover via `git fsck --unreachable | grep commit` + `git stash store`). Subagents must fix or escalate a failing gate, never rationalize it. Additionally: subagents do not know your lessons files — inline the relevant lesson rules into each dispatch prompt, because a bare constraint ("never touch X") without the failure-mode recipe lets the agent walk into the documented trap.

### 5. Runtime verification after a device/server fix (verify runtime, not just gates)

- **Rule:** After fixing anything that runs on a device or server, do ALL of the following before reporting done. `tsc`/lint green plus an HTTP 200 bundle compile is necessary, not sufficient.

```bash
# 1. Read the ACTUAL device/Metro log AFTER a reload — not build progress lines.
grep -nE "ERROR|WARN|Invariant|Invalid hook|Unimplemented" <metro-or-device-log-file>

# 2. Confirm the device talks to the Metro you fixed: exactly one process on :8081.
lsof -nP -iTCP:8081 -sTCP:LISTEN
pgrep -fl "expo start"     # kill stragglers so exactly one remains

# 3. Prove the fix in the SERVED bundle, not just on disk.
#    e.g. after deduping a module, grep the served bundle for its path:
curl -s "http://localhost:8081/index.bundle?platform=ios" | grep -c "<deduped-module-path>"
#    expect exactly 1
```

  Then run an adversarial red-team over the changed files for runtime bugs the compiler cannot see (hook rules, resolver edge cases, dropped logic).
- **Why:** Gates and a 200-OK bundle compile do NOT catch: duplicate React copies (every hook throws `Cannot read property 'useState' of null`), duplicate native-view registration, a stale Metro serving a cached bundle, or the device being connected to a DIFFERENT Metro than the one just fixed.
- **Failure symptom:** You report "fixed"; the device still red-screens, and the user has to point out the error. This happened repeatedly in one session until the log-check + red-team step was made mandatory.
- **Verify:** Log scan shows no new ERROR/Invariant lines after reload; exactly one Metro owns the port; the served-bundle grep returns the expected count. For web pages: hit the route in the dev server and check the HTTP STATUS, not just that the build compiled — a page can render its content while serving a 404.

### 6. Honest evidence classification when simulators limit depth

- **Rule:** When the harness cannot reach the interaction (e.g., synthetic System Events clicks satisfy large standalone buttons but never register on rows inside an RN ScrollView), do NOT burn iterations faking it and do NOT report deeper coverage than you achieved. Either (a) upgrade the evidence with a mechanism that works — deep links jump straight to any authenticated screen with real data:

```bash
xcrun simctl openurl <DEVICE_UDID> "<scheme>://<route>"
# reattach an Expo dev client to a running Metro:
xcrun simctl openurl <DEVICE_UDID> "<scheme>://expo-development-client/?url=http%3A%2F%2Flocalhost%3A8081"
```

  or (b) verify the unreachable interiors by diff inspection + typecheck/lint/build and REPORT THAT AS L1, explicitly.
- **Why:** The report's consumer makes decisions based on the claimed depth. Overstating "smoke-tested" when only boot + top-level screens were exercised converts an environment limitation into a false safety signal.
- **Failure symptom:** "Full simulator smoke passed" followed by a bug in a screen interior that was never actually rendered during the smoke.
- **Verify:** The evidence block lists which screens/flows were exercised at L2 and which fell back to L1, with the limiting mechanism named.

### 7. Delegated safety mechanisms: demand a negative fixture

- **Rule:** When delegating implementation of any safety/verification mechanism (assertion, purity check, validator, kill-switch): (1) the brief MUST require a negative fixture — an input the mechanism must REJECT — and state that a mechanism without a failing-case demonstration is not done; (2) before trusting any green run built on the mechanism, the orchestrator personally reads the mechanism's implementation.
- **Why:** A checker's green output looks identical whether the checker works or is a stub. The cheapest passing implementation of "implement the self-test" is a tautology. Canonical case: a delegated purity self-test compared a dict to a copy of itself and could never fail; all 23 fixtures were "green" and the safety net was fake, hidden by correct surrounding code.
- **Failure symptom:** Every fixture passes on the first run, including ones that should stress the mechanism; the check's diff touches no real engine code.
- **Verify:** Run the negative fixture and observe the mechanism FAIL it. Review the net, not the acrobat.

### 7b. Ground truth has a scope: check the source's own authority label

- **Rule:** Before citing an artifact as ground truth - or borrowing a constant, threshold, or calendar out of one - read that source's OWN declared `authority`/`status`/`source` fields. FROZEN or hash-pinned means its bytes are settled, NOT that its contents describe the world. Synthetic, fixture-sourced, or sample data may never be promoted to a fact about real data while its ratification gate is open; the correct value is `Unknown`, stated as such.
- **Why:** Verification fails in BOTH directions and the second one is invisible. Under-authority: citing a legacy helper over the adjudicated contract (a session validator built against a 24-hour helper when the frozen contract said 23 hours). Over-authority: promoting an adjudicated artifact outside its scope - a module whose first line read "Synthetic", whose status was `synthetic` and whose source was a test fixture, imported into a validator stamping real vendor bars, which then rejected genuine trading days. Both look like diligence; only the label distinguishes them.
- **Watch for over-correction:** review feedback that says "you claimed too much" is NOT licence to enforce more. Re-derive what SHOULD be enforced from first principles, separating constraints by WHAT THEY ASSERT rather than by which file they live in. The canonical case fixed an overclaim by importing synthetic data as authority - strictly worse than the overclaim it replaced.
- **Failure symptom:** A validator, threshold, or calendar imported across a module boundary "because it is the frozen/official one", with no sentence anywhere saying what that artifact is authoritative ABOUT.
- **Verify:** Name the artifact's authority scope out loud, then probe one in-scope and one out-of-scope input and show the pair diverging as intended.

### 8. Done-reporting (Definition of Done)

- **Rule:** A task is DONE only when: the plan checklist is complete, a "Review / Evidence" section exists with proof (test runs, command outputs) using the template from Procedure 1, and lessons are recorded for any correction or bug hit along the way.
- **Why:** "Done" without attached evidence is a self-report, and this discipline exists because self-reports (including your own) are the least reliable artifact in the pipeline.
- **Failure symptom:** A later session (or agent) cannot reconstruct what was verified and re-litigates or wrongly trusts the work.
- **Verify:** `tasks/todo.md` shows all items checked, an evidence section with levels and proof, and any new lesson entry exists.

## Failure-symptom index

| Observed symptom | Likely cause | Fix / section |
|---|---|---|
| Build and boot green; first real use of the new feature crashes | Capability never fired during verification (false-green boot) | Procedure 2 |
| Every React hook throws `Cannot read property 'useState' of null` | Duplicate React copies in the bundle; gates cannot catch it | Procedure 5 (served-bundle grep) |
| Fix confirmed locally but device still shows old/broken behavior | Stale Metro cache, or device attached to a different Metro process | Procedure 5 (port check, one process) |
| N parallel subagents all call the same gate error "pre-existing" | Shared regression rationalized circularly; agents never saw the baseline | Procedure 4 |
| Central gate red after all subagents reported clean | Per-agent self-reports trusted; no central re-run | Procedure 4 |
| All fixtures for a new safety check pass on the first run | The checker is a tautology or stub | Procedure 7 |
| An import is justified as "the frozen/official source" | Frozen means settled bytes, not true contents; scope unchecked | Procedure 7b |
| Page renders fine but dev server returns HTTP 404 | Build-time success mistaken for runtime correctness | Procedure 5 (check status codes) |
| Simulator taps land on buttons but not on list rows | Synthetic clicks do not drive the RN gesture system | Procedure 6 (deep links, or classify as L1) |
| "Verified" report later found factually wrong | Asserted facts were plausible, never checked against ground truth | Procedure 3 |
| Done-report has no way to tell what was actually run | Missing evidence levels / proof | Procedures 1 and 8 |
| Subagent walks into a failure mode you already documented | Lesson lived in a file the subagent never sees | Procedure 4 (inline lessons into dispatch prompts) |
