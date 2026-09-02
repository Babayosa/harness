# Prompt Rewrite Patterns

Learned patterns for improving prompts. Updated automatically by the `/rewrite` skill.

## Universal Patterns

- "When user says 'fix the bug' → infer which bug from recent context, specify the file/function, and state expected vs actual behavior"
- "When user says 'make it work' → identify what's broken, specify the success condition"
- "When request involves UI changes → specify platform, component name, and visual expectations"
- "When request is multi-step → number the steps and specify order dependencies"
- "When user says 'add a button/field/feature' → specify where it goes, what it does on interaction, and how it connects to existing state/data"
- "When user says 'clean up' or 'refactor' → specify what's messy, the target structure, and constraints (no behavior change, etc.)"
- "When user gives a one-word or two-word command → expand with context from the current file/project/conversation"

## Prompt Engineering Principles

- Add specificity: who, what, where, when, why, how
- State constraints explicitly: language, framework, file scope, backward compatibility
- Define done: what does success look like?
- Provide examples when the format matters
- Separate concerns: one clear ask per prompt, or numbered sub-tasks

## Learned Patterns

<!-- New patterns discovered by /rewrite will be appended below -->
