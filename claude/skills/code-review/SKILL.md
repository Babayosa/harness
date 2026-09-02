---
name: code-review
description: When the user wants a structured code review of changes, a file, module, branch, diff, or PR. Also use when the user says "review", "audit this code", "review my changes", "review this PR", "look for bugs", or asks whether code is safe to ship.
argument-hint: "[file path, module, PR URL, or 'staged changes']"
user-invocable: true
---

# Code Review

Use this skill for review-only work. Do not modify code unless the user also
asks for fixes.

## Review Goal

Find issues that matter: correctness bugs, security risks, missing tests,
behavioral regressions, performance problems, and maintainability problems that
will make future work harder. Do not spend review budget on harmless style
preferences.

## Workflow

1. Identify the review scope.
   - "Staged changes": inspect `git diff --staged`.
   - "My changes" or no explicit diff: inspect `git diff` and `git status`.
   - Branch review: compare against the appropriate base branch.
   - File/module review: read the requested files and their immediate callers.
   - PR review: fetch the diff and PR description when tooling is available.
2. Read project instructions first: `AGENTS.md`, `codex/RULES.md`, and relevant
   lessons.
3. Gather enough context to understand intent: changed code, tests, nearby
   patterns, call sites, and public contracts.
4. Review in this order:
   - Correctness and regressions
   - Security and data exposure
   - Error handling and fail-fast behavior
   - Tests and coverage gaps
   - Performance and resource use
   - Maintainability and unnecessary complexity
5. Verify findings against the actual code before reporting them.

## Review Checklist

### Correctness

- Does the code do what the request or API contract says?
- Are boundary cases handled: empty input, nil/null, time zones, duplicates,
  concurrency, retries, permissions, malformed data, partial failure?
- Did method signature or contract changes update all call sites and tests?
- Are state transitions valid through the full lifecycle, not just the happy path?

### Security

- Is external input validated before it reaches queries, commands, file paths, or
  rendered output?
- Are auth and authorization checks present at every protected boundary?
- Are secrets, tokens, private data, or internal errors exposed in logs or
  responses?
- Do new dependencies or permissions increase risk?

### Tests

- Does every behavioral change have a meaningful test?
- Do tests cover failure paths and the important edge cases found during review?
- Would the tests fail if the implementation regressed?
- Are tests isolated from order, timing, external services, and local machine
  state?

### Performance

- Are database queries bounded, indexed, and outside avoidable loops?
- Are algorithms appropriate for realistic input sizes?
- Are caches and collections bounded?
- Are network calls batched or timed out where needed?

## Severity

- **Critical**: correctness, data loss, security, or release-blocking issue.
- **Major**: likely production bug, missing essential tests, or serious design
  flaw.
- **Minor**: maintainability, robustness, or clarity issue worth fixing.
- **Nit**: harmless polish. Use sparingly.

## Output Format

Lead with findings, ordered by severity. Use precise file and line references.

```markdown
**Findings**
- Critical: [title] - `path:line`
  Problem, impact, and suggested fix.
- Major: [title] - `path:line`
  Problem, impact, and suggested fix.

**Open Questions**
- ...

**Test Gaps**
- ...
```

If there are no findings, say so directly and mention residual risk or tests not
run.
