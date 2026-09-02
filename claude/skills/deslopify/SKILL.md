---
name: deslopify
description: "Use when the user gives explicit cleanup intent for recently changed files — removing leftover prints, commented-out code, unused imports, or debug artifacts. Use code-review for evaluation without cleanup. Not for: code review without explicit cleanup intent; broadening cleanup into feature work."
argument-hint: "[optional: specific file or directory to clean]"
user-invocable: true
allowed-tools: Bash, Read, Edit, Glob, Grep
---

# De-Sloppify

Run a focused cleanup pass on recently changed files to remove common agent-generated slop.

**Cleanup-intent gate:** Proceed only when the user explicitly asks for cleanup. Review-only requests belong to `code-review` and must not edit.

## Step 1: Identify Changed Files

If `$ARGUMENTS` specifies a file or directory, use that scope.

Otherwise, find files changed in the current session:
1. `git diff --name-only HEAD~5` (recent commits)
2. `git diff --name-only` (unstaged)
3. `git diff --name-only --staged` (staged)
4. Filter to source files: `.swift`, `.ts`, `.tsx`, `.js`, `.jsx`, `.py`, `.pine`
5. Exclude test files (tests have different rules)

If no changed files found, tell the user and stop.

## Step 2: Scan and Fix

Read each changed file. Flag and fix these categories:

### A — Debug Artifacts
- `print(` / `NSLog(` / `debugPrint(` in Swift NOT behind `#if DEBUG`
- `console.log` / `console.debug` / `console.info` in JS/TS
- `print(` in Python (unless the file is a CLI script)
- `breakpoint()` / `pdb.set_trace()` / `debugger` statements

### B — Dead Code
- Commented-out code blocks (3+ consecutive commented lines that look like code, not docs)
- Unused imports (import not referenced elsewhere in file)
- Unreachable code after unconditional return/throw/break

### C — Over-Engineering
- Protocols with exactly one conformer
- Generic type parameters used with exactly one concrete type
- Wrapper types that add no behavior
- Over-defensive nil/optional handling for values that cannot be nil in context

### D — Ungated Debug Code
- Verbose logging that should be behind `#if DEBUG` or `process.env.NODE_ENV`
- Test/mock data left in production code
- `TODO`/`FIXME`/`HACK` comments added by the agent (check git blame — leave user-authored ones)

## Step 3: Apply Fixes

For each issue:
1. Show file, line, category, and what will change
2. Apply the fix (delete, wrap in `#if DEBUG`, remove import, etc.)
3. Do NOT remove user-authored debug code — if `git blame` shows it predates this session, leave it

## Step 4: Report

```
## De-Sloppify Report
- Files scanned: N
- Issues found: N / fixed: N
- By category: A: N, B: N, C: N, D: N
- Files modified: [list]
```

## Rules

- Never remove code that changes behavior. Slop removal is cosmetic + hygienic.
- Never touch test files unless explicitly asked.
- When in doubt, leave it. False positives erode trust.
- Skip files with zero issues silently.
