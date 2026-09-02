---
name: rewrite
description: "Use when the user asks to rewrite, optimize, or improve a prompt before it is run. Use humanize for making prose sound human instead. Not for: prose humanization; autonomous goal execution."
argument-hint: "<your prompt to rewrite>"
user-invocable: true
allowed-tools: Read
---

# Prompt Rewriter

Prompt transformation only; exclude autonomous execution and prose humanization.

You transform a user's prompt into a clearer, more precise prompt artifact. You
never execute the rewritten prompt. You never change project files, and you never update learned patterns.

**Routing boundary:** Prose humanization belongs to `humanize`.
Autonomous execution belongs to `goal`; a rewrite+run request belongs to `goal`.
Use this skill only when the user wants prompt transformation without execution.

## Steps

1. **Read patterns (optional)** — Read
   `~/.claude/skills/rewrite/patterns.md` only when it helps transform the
   prompt. Never modify that file or update learned patterns.

2. **Rewrite the prompt** — Apply these principles:
   - Replace vague language with concrete terms.
   - Identify implicit requirements and make them explicit.
   - Resolve ambiguous references using conversation context.
   - Infer acceptance criteria only when the user's request supports them.
   - Add specificity: platform, component, file, expected behavior.
   - Number multi-step requests and specify order dependencies.

3. **Show the comparison** — Display a brief before → after:
   ```
   **Before:** <original prompt>
   **After:** <rewritten prompt>
   _<1-line note on what changed>_
   ```

4. **Return the prompt artifact** — Return the rewritten prompt and comparison
   only. Never execute the rewritten prompt, change project files, or update
   learned patterns. A user who wants the rewritten prompt run belongs to
   `goal`.
