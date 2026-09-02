#!/usr/bin/env bash
# install.sh — link this repo into ~/.claude, ~/.omp/agent, and ~/.codex.
# Idempotent. Anything it would replace is moved to ~/.harness-backup/<stamp>/ first.
# It never edits settings.json, never touches sessions/auth, and never deletes.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y-%m-%d-%H%M%S)"
BACKUP="$HOME/.harness-backup/$STAMP"
CHANGED=0
tilde() { case "$1" in "$HOME"/*) printf '~/%s' "${1#"$HOME"/}";; *) printf '%s' "$1";; esac; }
TILDE_HERE="$(tilde "$HERE")"

say()  { printf '%s\n' "$*"; }
note() { printf '  %s\n' "$*"; }

backup_then() {  # backup_then <path>
  local dst="$1" rel
  rel="${dst#"$HOME"/}"
  mkdir -p "$BACKUP/$(dirname "$rel")"
  mv "$dst" "$BACKUP/$rel"
  note "backed up $dst -> $BACKUP/$rel"
}

link() {  # link <repo-path> <home-path>
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then return; fi
  if [ -e "$dst" ] || [ -L "$dst" ]; then backup_then "$dst"; fi
  ln -s "$src" "$dst"
  note "linked $dst"
  CHANGED=1
}

ensure_line() {  # ensure_line <file> <exact-line>
  local file="$1" line="$2"
  if [ -f "$file" ] && grep -qxF -- "$line" "$file"; then return; fi
  if [ -f "$file" ]; then cp "$file" "$BACKUP.$(basename "$file").bak" 2>/dev/null || true; fi
  mkdir -p "$(dirname "$file")"
  printf '%s\n' "$line" >> "$file"
  note "added to $file: $line"
  CHANGED=1
}

say "harness install from $HERE"

# 1. Claude Code: agents, hooks, statusline, skills (symlinks).
for f in "$HERE"/claude/agents/*.md;  do link "$f" "$HOME/.claude/agents/$(basename "$f")"; done
for f in "$HERE"/claude/hooks/*.sh;   do link "$f" "$HOME/.claude/hooks/$(basename "$f")"; chmod +x "$f"; done
link "$HERE/claude/statusline.sh" "$HOME/.claude/statusline.sh"
for d in "$HERE"/claude/skills/*/;    do d="${d%/}"; link "$d" "$HOME/.claude/skills/$(basename "$d")"; done

# 2. Shared rules. Claude Code reads ~/.claude/CLAUDE.md; a pre-existing ~/CLAUDE.md is honored instead
#    so the two never double-load.
RULES="$HOME/.claude/CLAUDE.md"
[ -f "$HOME/CLAUDE.md" ] && RULES="$HOME/CLAUDE.md"
PRIVATE="$HOME/CLAUDE.private.md"
ensure_line "$RULES" "@$TILDE_HERE/CLAUDE.md"
ensure_line "$RULES" "@$(tilde "$PRIVATE")"
if [ ! -f "$PRIVATE" ]; then
  cat > "$PRIVATE" <<'EOF'
# Personal Rules (never committed)

Add your own preferences, project trigger rules, and tech-stack notes here.
Opt-in modules: add one of these lines to the file that imports the harness
(the line must start with @ at column 1):
  @~/harness/modules/communication-contract.md
  @~/harness/modules/teach-mode.md
EOF
  note "created $PRIVATE"
  CHANGED=1
fi

# 3. OMP (only if installed).
if [ -d "$HOME/.omp/agent" ]; then
  OMP="$HOME/.omp/agent/AGENTS.md"
  ensure_line "$OMP" "@$(tilde "$RULES")"
  ensure_line "$OMP" "@$TILDE_HERE/omp/AGENTS.md"
  [ -f "$HOME/.omp/agent/config.yml" ] || note "OMP: copy omp/config.example.yml to ~/.omp/agent/config.yml and set your models"
fi

# 4. Codex (only if installed). Codex has no @imports, so it gets a plain copy.
if [ -d "$HOME/.codex" ] && [ ! -f "$HOME/.codex/AGENTS.md" ]; then
  cp "$HERE/codex/AGENTS.md" "$HOME/.codex/AGENTS.md"; note "installed ~/.codex/AGENTS.md"; CHANGED=1
fi

# 5. Claude settings: never merged automatically.
if [ ! -f "$HOME/.claude/settings.json" ]; then
  cp "$HERE/claude/settings.example.json" "$HOME/.claude/settings.json"; note "installed ~/.claude/settings.json"; CHANGED=1
else
  note "settings.json exists: copy the hooks/statusLine you want from claude/settings.example.json"
fi

# 6. Repo hygiene: secret gate on every commit in this repo.
if git -C "$HERE" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git -C "$HERE" config core.hooksPath .githooks
fi

# 7. Tools the hooks expect.
for t in trash jq dcg; do command -v "$t" >/dev/null 2>&1 || note "missing tool: $t (see README > Requirements)"; done

if [ "$CHANGED" = 1 ]; then say "done. start a new agent session to load the changes."; else say "already up to date."; fi
