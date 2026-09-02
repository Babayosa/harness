## OMP adaptations (mechanism mapping)

The shared rules name tools from other harnesses. Honor the intent with OMP equivalents:

- **Teach mode** (if you import `modules/teach-mode.md`) is Claude Code only. In OMP, do NOT run teach mode by default: no checklists, quizzes, restatements, or running teaching docs. It activates only on `/teach` or the `teach` skill.
- **Subagents**: the Codex rule "do not spawn subagents unless explicitly asked" is superseded in OMP. Delegation via the `task` tool is the harness default for decomposable/parallel work. The orchestrator loop maps to OMP agents: `scout` → `scout`, `implementer` → `task`, `reviewer` → `reviewer`.
- **AskUserQuestion** → the `ask` tool.
- **Skill tool / Read SKILL.md** → read `skill://<name>`.
- **`/clear` at phase boundaries** → start a fresh OMP session; state still lives in `tasks/todo.md`.
- **Codex dispatch** → `mcp__codex__codex` tools are discoverable via tool search if not active.
- Model/effort tiers pinned in `~/.claude/agents/*` frontmatter apply to Claude Code only. OMP lanes live in `~/.omp/agent/agents/` plus `config.yml` `modelRoles`. Truth for OMP lanes is `config.yml`; prose that disagrees with it is stale.
- **Named model dispatch**: agent-type frontmatter and config `modelRoles` are routing REQUESTS. The router can substitute. When the user names a model/effort, confirm the model from the runtime session header or cost telemetry, never from frontmatter/config bytes. If the user says the model looks wrong, they are right.
- **Reviewer independence**: the author of a deliverable never reviews it. Enforce with a fresh-context reviewer run and a read-only prompt. Reviewer lane down or rate-limited → stop and ask the user; never swap the reviewer silently.
- **Failed lane audit**: any tool-using subagent that reports failure → first read `history://<id>` and audit partial edits on disk, then decide. Never blind-retry a task that may already have edited or acted.
