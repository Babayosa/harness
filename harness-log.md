# Harness Log (captain's log) — template

Every change to your AI coding harness gets one entry: **what / where / why**. Dated. Append only; never rewrite history. Keep your live copy at `~/tasks/harness-log.md` (outside this repo); this file is the template and a worked example.

Why it exists: customization knowledge otherwise dies in chat history. Six months later you cannot tell which rule was a considered decision and which was a Tuesday-afternoon guess. The log is the difference.

Surfaces: the shared rules (`CLAUDE.md` in this repo), your private rules, `~/.claude/settings.json` (hooks), `~/.claude/agents/`, `~/.claude/skills/`, `~/.claude/hooks/`, OMP `~/.omp/agent/`, Codex `~/.codex/AGENTS.md`.

---

## YYYY-MM-DD

1. **Short title** — `path/that/changed`. Why: one or two sentences. What you verified.

### Worked example (real entries, lightly trimmed)

1. **Claude Code agents un-broken** — `~/.claude/agents/{scout,implementer,reviewer}.md` `model:` set to `opus`. Why: the files carried provider-prefixed ids; a live probe showed Claude Code sent them verbatim and got HTTP 404 `model_not_found`. The whole orchestrator loop had been silently dead for weeks. Verified from a fresh `claude -p` process; the running session kept the stale definitions, so agent-file edits need a new session.
2. **Reviewer tightened** — `reviewer.md` now requires file:line on every finding and independent verification of every fact the audit asserts. Why: a verifier's first run should be able to fail its own creator's commit.
3. **Model lanes consolidated** — one table names the config file as truth; 23 lines of dated, self-contradicting routing prose deleted. Why: four sources disagreed on which model ran which lane. Rule that came out of it: prose that disagrees with config is stale by definition.
