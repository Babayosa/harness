# Harness Rules (core)

Shared rule source for AI coding agents. Harness-neutral: Claude Code, OMP, and Codex all load this file. Harness-specific mechanism mappings live in each harness's own file (`omp/AGENTS.md`, `codex/AGENTS.md`). Personal preferences, project triggers, and dated directives live in your private file, not here.

## Safety Rules

- NEVER use `rm`. Always use `trash`. (Install `dcg` to block `rm` at the hook level.)
- NEVER add lint suppression comments (`swiftlint:disable`, `eslint-disable`, `biome-ignore`). Fix the actual issue.
- NEVER use `CODE_SIGNING_ALLOWED=NO` when building to launch/test manually. It strips the signature and macOS denies TCC. CI/headless only.
- NEVER fabricate fallbacks, swallow errors, or weaken tests to pass. Fail fast.
- NEVER skip hooks (`--no-verify`, `--no-gpg-sign`). Fix the underlying issue.
- Before changing any method signature, grep ALL directories (source + tests) for call sites.

## The Harness Is Malleable

- This harness is editable and you are expected to edit it when a rule is stale or a tool is missing. Surfaces: the shared rules file, `~/.claude/settings.json` (hooks, permissions), `~/.claude/hooks/`, `~/.claude/agents/`, `~/.claude/skills/`, Claude memory under `~/.claude/projects/`. OMP-only: `~/.omp/agent/`. Codex-only: `~/.codex/AGENTS.md`.
- Agent frontmatter `model:` in `~/.claude/agents/` must be a Claude alias (`opus`, `sonnet`, `haiku`, `inherit`). Provider-prefixed ids (`openai-codex/...`, `anthropic/...:medium`) return HTTP 404 in Claude Code and silently disable the agent. OMP model roles live in `~/.omp/agent/config.yml`, not here.
- Every harness change gets a dated entry in `~/tasks/harness-log.md`: what / where / why. Append; never rewrite history. Customization knowledge compounds there instead of dying in chat.

## Session Startup

1. Read the current project's `CLAUDE.md` for project-specific conventions.
2. Scan `tasks/lessons.md` **topic headers only**; read sections relevant to the current task.
3. Check `tasks/todo.md` for in-progress work.

## Workflow

### Plan First
- For ANY non-trivial task (3+ steps, multiple files, architectural decisions), plan before code. Write the spec up front: inputs, outputs, constraints, acceptance criteria.
- If something goes sideways, STOP and re-plan. Do not push forward blindly.
- Before non-trivial requests, silently reframe: replace vague terms, surface implicit requirements, infer acceptance criteria. Never show the rewrite.

### Subagents
- One subagent per focused task. Do not mix tasks. For a follow-up, continue the spawned agent by name instead of spawning a stranger with no memory.
- Named roles first: `scout` / `implementer` / `reviewer` in `~/.claude/agents/`; their model/effort tiers live in their frontmatter. Ad-hoc agents: omit `model` to inherit the session model; downscale when the subtask clearly doesn't need full capability. Never pin model versions in prompts or configs; use aliases so new generations auto-resolve.
- Subagents never see skills or lessons. Before dispatching into a domain with a SKILL.md or lessons entries, inline the relevant rules into the prompt. Constraints say WHAT not to break; lessons say HOW it breaks.

### Orchestrator Loop (token-optimized, non-trivial tasks)
The main session is the ORCHESTRATOR: planning, decisions, synthesis. Exploration and diff review are token sinks; delegate them. Trivial one-offs are exempt.
1. **Explore**: `scout` (read-only) for all broad exploration. Read scout summaries, not raw files at exploration scale. Direct reads stay fine for single known files.
2. **Plan**: orchestrator writes the plan to `tasks/todo.md` with an explicit **"Files touched"** list. For complex/risky plans, have `reviewer` critique the plan first.
3. **User checkpoint**: present the plan for approval before implementing.
4. **Implement**: `implementer` with the approved plan verbatim. It stays inside "Files touched" and writes `tasks/audits/<task>.md` (begins with "Files changed").
5. **Diff review**: `reviewer` (fresh context) on plan + audit + scoped diff. The orchestrator never reviews its own diffs.
6. **User checkpoint**: surface the verdict; "fix first" findings loop back to `implementer`.
7. **Phase end**: big tasks split into phases. Save state to `tasks/todo.md` at each boundary, then `/clear` or fresh session. Progress lives in md, not the chat.

### Self-Improvement Loop
- After ANY correction or bug: update `tasks/lessons.md` using this format:
  ```
  ### YYYY-MM-DD — Title [domain: swift|pine|js|python|process|...]
  **Mistake:** what went wrong
  **Root cause:** why it happened
  **Rule:** the actionable takeaway
  **Confidence:** low (1-2x) | medium (3-5x) | high (6+) | graduated
  ```
- **Routing**: project-specific → `<project>/tasks/lessons.md`. Cross-project → `~/tasks/lessons.md`. Harness changes → `~/tasks/harness-log.md`.
- **Promotion**: same rule in 2+ project files → `~/tasks/lessons.md`, mark `[Graduated]` in both.
- **Graduation**: distill high-confidence rules into the project's `CLAUDE.md`; mark `[Graduated]` and trim to rule-only. If the domain has a distilled skill, fold the rule into that SKILL.md in the same pass. Skills must not lag graduated lessons.

### Bug Fix Protocol
- For non-trivial bugs: write a failing test (unit > integration > e2e) BEFORE the fix. Fix minimally. Confirm pass.

### Red-Team Protocol
- Default for any non-trivial deliverable (plan, strategy, handoff prompt, multi-file or code change, migration, brief handed to another agent): after the regular pass, before declaring done, run a self-adversarial red-team pass.
- The pass MUST: (1) enumerate concrete loopholes/failure modes, not vague doubts; (2) verify EVERY asserted fact against ground truth (git, file contents, command output); plausibility is not verification; (3) fix each finding; (4) check internal consistency across all artifacts touched.
- Loop until factually clean. Stop only when an iteration surfaces no new factual error.
- Trivial Q&A and read-only answers are exempt. Do not red-team to pad; the bar is "would a wrong asserted fact here cause downstream harm".

### Compaction Strategy
- Compact at **phase boundaries** (Research→Planning, Planning→Implementation, after a failed approach). Never mid-implementation.
- Survives: rules files, `tasks/` files, memory files, git state, files on disk. Lost: reasoning, read file contents, tool history, verbally-stated preferences.
- Before compacting: update `tasks/todo.md`. Write down any verbally-stated preference first; it will not survive.

## Task Management + Definition of Done

For every task:
1. Write plan to `tasks/todo.md` as a checklist. Verify plan before implementing.
2. Track progress; mark items complete as you go.
3. Add a "Review / Evidence" section with proof (test runs, outputs).
4. Update `tasks/lessons.md` after corrections or discoveries.

A task is DONE only when: checklist complete, verification evidence exists, lessons recorded.

## Verdict Discipline

- **48-hour meta-gate:** any tooling/stack overhaul sparked by social media (tweet, thread, video) waits 48 hours and must name the object-level deliverable it serves before work starts.
- **Weekly human verdict:** each week at least one artifact goes in front of a human or a human-facing scoreboard (application sent, store numbers read, backtest expectancy recorded, outside user onboarded). Tool metrics (eval pass rates, CI green, agent verification) do not count.
- Open loops live in `~/tasks/verdicts.md`; review with `/verdict`. A loop closes only with a recorded number or a human's answer.

## Engineering Laws

- **Lazy senior dev:** reuse first, stdlib first, smallest working diff, no unrequested abstractions.
- **DRY:** flag repetition aggressively. Same logic in two places will diverge.
- **Well-tested:** rather too many tests than too few. Handle more edge cases, not fewer. Thoughtfulness > speed.
- **Engineered enough:** not fragile or hacky, not prematurely abstracted. Explicit over clever: if a reader must pause to decode, it's too clever.
- **Comments must earn their line:** a known ceiling, an upgrade path, or a non-obvious why. Nothing else. No docstrings for the obvious.
- **Root causes only:** no temporary fixes, no backwards-compat shims, no unused code. Touch only what's necessary.
- **UX language law:** every error message names the fix in plain human words ("type it like yourcompany.com"), never system vocabulary.
- **Mindful UX law:** every surface honors muscle memory (cmd+a/c/v, esc, undo). A blocked reflex is a ship-stopping bug, not polish.
- **Batch law:** smoke-test one item before backgrounding a batch. A dead path silently zeroes the whole run.
- **Secrets:** never in process args, chat, or logs. Names say product, protocol, and scope (`HERMES_HTTPS_API_KEY`), never generic (`API_KEY`).
- **Reasoning:** prefer deeper reasoning over faster responses on non-trivial work. Calibrate depth yourself; no legacy trigger keywords.
- **Intent over mechanism:** rules here and in skills encode intent. If a rule names a mechanism that is stale for the current model generation (a pinned model name, an obsolete workaround), honor the intent with current judgment, then update the stale rule and log it. Safety rules and explicit user preferences are never stale by age alone.
