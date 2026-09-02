# harness

A shared rule set, three agents, three hooks, and twelve skills for AI coding agents. Works with Claude Code, OMP, and Codex from one source. Install links the repo into your home directory; your personal preferences live outside the repo, so nothing private can be committed by accident.

## Install

```sh
git clone <this repo> ~/harness
~/harness/install.sh
```

Then start a new agent session. Re-run `install.sh` after `git pull`; it is idempotent and backs up anything it replaces to `~/.harness-backup/<stamp>/`.

What install does:

1. Symlinks `claude/agents/*`, `claude/hooks/*`, `claude/statusline.sh`, and each `claude/skills/<name>` into `~/.claude/`.
2. Adds two `@` import lines to your rules file (`~/.claude/CLAUDE.md`, or `~/CLAUDE.md` if you already have one): the shared `CLAUDE.md` and your private `~/CLAUDE.private.md`. Creates the private file if missing.
3. If OMP is installed, adds the same imports to `~/.omp/agent/AGENTS.md` plus `omp/AGENTS.md` (the OMP mechanism mapping).
4. If Codex is installed and has no `AGENTS.md`, copies `codex/AGENTS.md` there. Codex has no `@` imports, so it gets a plain copy.
5. Copies `claude/settings.example.json` to `~/.claude/settings.json` only if you have none. Otherwise it leaves yours alone and tells you what to merge.
6. Points this repo's git hooks at `.githooks/` so every commit runs the secret gate.

Nothing is deleted. `settings.json`, sessions, auth, and memory are never touched.

## Requirements

- `trash` (macOS ships it; `brew install trash` elsewhere). The rules ban `rm`.
- `jq` for the hooks.
- `dcg` (optional): blocks `rm -rf` and friends at the hook level. Remove the `dcg` hook line from settings if you skip it.

## Layout

```
CLAUDE.md                     shared rules: safety, workflow, orchestrator loop, engineering laws
modules/
  communication-contract.md   opt-in: terse STE100-style replies, verdict words, reference codes
  teach-mode.md               opt-in: the agent teaches as it works (Claude Code only)
claude/
  agents/                     scout (read-only explore), implementer (edits inside a plan), reviewer (fresh-context diff review)
  hooks/                      commit-quality (scans staged diff for debug junk and secrets),
                              config-protection (refuses to weaken lint/build configs),
                              learning-logger (daily tool-activity log in ~/.claude/logs)
  skills/                     12 skills, listed below
  statusline.sh
  settings.example.json       hooks + permissions + statusline only; no env, no secrets
omp/
  AGENTS.md                   how the shared rules map onto OMP tools
  config.example.yml          model roles with comments
codex/AGENTS.md               plain-text rules for Codex
harness-log.md                captain's-log template with a worked example
install.sh
scripts/check-secrets.sh      pre-commit gate: secrets, banned file names, absolute home paths
```

## How the rules are layered

```
~/CLAUDE.md  (or ~/.claude/CLAUDE.md)
  @~/harness/CLAUDE.md                          shared core (this repo)
  @~/harness/modules/communication-contract.md  optional
  @~/harness/modules/teach-mode.md              optional
  @~/CLAUDE.private.md                          yours: preferences, projects, stacks
```

Claude Code and OMP both expand `@path` imports inline (five hops deep). The core file never names a person, a project, or a date; those belong in your private file. If you find yourself editing the core to add something personal, it goes in the private file instead.

## The ideas worth stealing, in one paragraph each

**Orchestrator loop.** The main session plans and decides. A read-only `scout` explores; an `implementer` edits only inside the plan's "Files touched" list and writes an audit; a fresh-context `reviewer` diffs only that scope and cites file:line for every finding. The orchestrator never reviews its own diff. This is a token budget as much as a quality gate.

**Captain's log.** Every harness change gets a dated what/where/why entry. It is how you find out, months later, that an agent has been silently dead since a config edit. `harness-log.md` has the template and three real entries.

**Verdict discipline.** Tool metrics do not count as progress. Each week one artifact goes in front of a human or a human-facing scoreboard. A tooling overhaul sparked by social media waits 48 hours and must name the deliverable it serves.

**Engineering laws.** Lazy senior dev (reuse first, smallest diff). Comments must earn their line. Root causes only. Every error message names the fix in human words. A blocked keyboard reflex is a ship-stopping bug. Smoke-test one item before backgrounding a batch. Secret names say product, protocol, and scope.

**Failed-lane audit.** A subagent that reports failure may already have edited files. Read its transcript and audit the disk before retrying. Never blind-retry.

## Skills

| Skill | Use when |
|---|---|
| `code-review` | structured review of a diff, file, branch, or PR |
| `codebase-audit` | read-only multi-dimensional audit via parallel scoped auditors |
| `deslopify` | strip leftover prints, dead code, unused imports from recent changes |
| `stop-slop` | quick prose pass to remove AI tells from short text |
| `verification-discipline` | before claiming work is done; evidence sections; delegating safety checks |
| `teach` | `/teach` a topic on demand |
| `goal` / `goal-creator` | run a goal to a verified end state / draft a completion contract |
| `rewrite` | improve a prompt before running it |
| `verdict` | track the loops that grade you, not the tools |
| `copying-to-clipboard` | "pbcopy that" |
| `animation-vocabulary` | motion reference for UI transitions and micro-interactions |

Third-party skill packs are not vendored. If you want the `pstack` collection, install it separately.

## Contributing back

Keep the core harness-neutral and person-neutral. The pre-commit gate refuses absolute home paths (`/Users/<name>/`, `/home/<name>/`) so paths must be written with `~`. Add a log entry for anything you change.
