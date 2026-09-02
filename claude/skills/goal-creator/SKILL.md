---
name: goal-creator
description: "Use when the user asks to draft, write, or tighten a goal prompt into a completion contract without running it. Use goal when the user wants the work actually executed. Not for: executing the drafted contract; autonomous execution."
argument-hint: "<a rough task idea to turn into a goal prompt>"
user-invocable: true
allowed-tools:
  - Read
  - Grep
  - Glob
  - AskUserQuestion
---

# Goal Creator (drafter)

`/goal-creator` produces a goal prompt. It **never executes the work**. Reading repo files for context is allowed; changing or running anything is not.

This read-only rule is enforced by instruction, not by a sandbox: `Write`, `Edit`, `Bash`, and the `Skill` tool remain technically callable but are **off-limits here** — never call them, and never invoke `/goal` or any other skill from within this skill. The only deliverable is the prompt plus a short rationale.

> Tiebreaker vs `/goal`: if the user says "make/create/build/write a goal to X" and does NOT also ask to run, execute, or do it autonomously, draft it here. If they want it done, that is `/goal`. After drafting, offer the handoff; never run it yourself.

## When NOT to make a goal

Two cases. In both, do not manufacture a contract:

1. **Trivial** — a one-line edit, simple question, or quick lookup with a single answer and a natural stop. Say so, give the one-line phrasing, and add: "This is simple enough to run directly — use `/goal <one-liner>` to execute it now." Then stop.
2. **Vague finish line with no inferable evidence standard** — "improve performance", "make it better", "clean this up", "refactor X" with no metric, threshold, or testable target the user gave or that is derivable from context. Do not invent the metric. Use the clarifying-questions step to ask the user for the missing verification standard first.

## A strong goal has six parts

Every prompt you produce must specify all six, explicitly or by clear implication:

1. **Outcome** — the single end state that must become true.
2. **Verification surface** — the concrete evidence proving it (named test suite, build command, benchmark + threshold, artifact, inspected source). No vague "make sure it works."
3. **Constraints** — what must NOT regress or change.
4. **Boundaries** — files, modules, tools, repos, or resources in scope.
5. **Iteration policy** — how the agent picks the next action after each attempt.
6. **Blocked-stop and report shape** — when to stop blocked, what to report when blocked (what was attempted, what's blocking, what would unlock progress), AND the shape of the success report (what verification output to include, what files changed, confirmation that constraints held). Specify the success report by default; trivial goals (one-line edit, single-command verification) can imply it.

A missing component is the most common failure. If you cannot infer one safely, that is what a clarifying question is for — never silently fabricate it.

## Template

```
/goal <desired end state> verified by <specific evidence> while preserving <constraints>.
Use <allowed files, tools, or boundaries>.
Between iterations, <how to choose the next best action and what to record>.
If blocked or no valid path remains, <what to report and what would unlock progress>.
```

(The leading `/goal` is Claude Code invocation syntax. When the user will paste the contract into a different agent, drop the `/goal` token — the contract text itself is portable and tool-agnostic.)

A compact task may collapse this to: `/goal <do the work> until <testable end state> without <constraints>` — but only when verification and boundaries are obvious from context, AND a stop condition is still stated or unambiguously implied. Never drop the blocked-stop component. If no natural stop is obvious, use the full template.

## Silent pre-write checklist

Identify before drafting (never shown to the user): **Deliverable**, **Context**, **Definition of done**, **Verification method** (named specifically), **Constraints**, **Boundaries** (what is off-limits), **Iteration policy**, **Blocked-stop and report shapes** (both success and blocked), **Risks / ambiguity**.

## Clarifying questions

Ask only when the goal cannot be drafted safely or usefully without an answer — including any vague-finish-line case where the verification standard is unknowable from context. Cap at 3, via AskUserQuestion.

**Contract-defining vs discoverable.** Only unknowns that define the verification surface, success criteria, or a constraint the agent cannot reverse warrant a question (e.g., the threshold/metric, the acceptance bar, an irreversible scope decision). Unknowns the executing agent can resolve by looking — the stack, framework, language, file/entry-point location, build/test command, directory layout, config — are **discoverable, not contract-defining**: never ask about these. Instead bake an inspect-first instruction into the goal's boundaries line ("first inspect the repo to identify <X>, then ...") and add the relevant blocked-stop ("if <X> cannot be identified, stop and report what was inspected and the one decision needed"). A goal that can name its verification surface is draftable even when the stack is unknown. If the user said to proceed without questions, make the reasonable inference and note the assumption inline — **except** the anti-pattern guard's request for a missing verification standard, which a generic "no questions" instruction does not waive. That ask is waived only by an explicit instruction to use your best judgment on the success metric (then infer it and flag the inferred standard in a callout above the goal prompt code block AND restate it inside "Why it works").

## Required output

Produce, in order:

1. **Goal prompt** — copy-ready code block applying the template, all six parts present. If any verification standard or other contract component was inferred under a "best judgment" waiver, precede the code block with a one-line markdown blockquote callout (outside the code block, so it cannot be lost in a copy-paste) flagging exactly what was inferred and asking the user to confirm or replace it. If a tighter version is also produced (see item 3), repeat the callout above the tighter block too, since the tighter version is the handoff.
2. **Why it works** — 3-6 bullets, each mapping a line of the prompt to one of the six components.
3. **Tighter version** *(required when the main prompt has multiple numbered verification clauses, is multi-phase, or exceeds ~250 words; optional otherwise)* — compressed variant for simple tasks (still names a stop condition).
4. **Expanded version** *(optional)* — for multi-phase work, with explicit Outcome, Constraints, Boundaries, Verification, Iteration policy, Blocked-stop, and Report sections.
5. **Handoff** — end with: run it now via `/goal <prompt>` (the tightest viable version). Do not execute it yourself.

## Anti-pattern guard

Flag these on sight and **ask the user for the missing component before drafting** — never invent a metric, threshold, or evidence standard the user did not provide:

- "Improve / optimize performance" → ask for the metric, threshold, and benchmark.
- "Make this better / clean this up" → ask for the defined end state and how it is verified.
- "Refactor this code" → ask for the target structure, the tests that must stay green, and the untouched-behavior constraint.
- "Reproduce this paper / research X" → ask for the evidence standard; require tiered reporting (reproduced / approximate / blocked / uncertain).

If the user supplies the missing standard, draft normally. If they explicitly decline to and say "your best judgment", you may infer it from context. Surface the inference in two places so it survives both a quick copy-paste and a careful review: (a) a one-line markdown blockquote callout placed immediately above each goal prompt code block (above the full version, and also above the tighter version if one is produced, since that is the handoff), and (b) restated inside "Why it works" so it can be corrected during review.

## Verb guidance

Prefer: `create, refactor, audit, implement, migrate, fix, document, test, compare, summarize, generate, verify, reproduce, benchmark`. Replace vague verbs (`help, improve, optimize, make better, clean up, handle, look into`) with the concrete action inferred from context — but only when the *evidence standard* is still determinable; if it is not, ask (see anti-pattern guard).

## Domain checklists

**Coding** — files/modules to inspect; exact test, lint, typecheck, build commands; "no unrelated changes" constraint; "report changed files and verification results." When the user cites file:line references, anchor each one with a named symbol unlikely to be renamed by the fix (e.g., the enclosing function or class name: `functionName at path:line`) so the contract survives line-number drift during the fix. For unnamed locations (anonymous closures, top-level code), use a one-phrase description of the location instead of a bare line number.

**Research** — source-quality bar (primary/peer-reviewed/official); recency cutoff; citation format; final output format; tiered ledger (Claim / Route / Evidence surface / Status: reproduced|approximate|blocked|uncertain / Remaining uncertainty). This ledger format is the canonical one shared with `/goal`; keep them in sync.

**Writing** — audience; tone; length; structure; style constraints or reference examples; the no-em-dash rule for prose written for this user.

## Style

No emojis unless asked. No em dashes in prose for the user. The prompt is the artifact; commentary supports it. Never narrate the silent checklist.
