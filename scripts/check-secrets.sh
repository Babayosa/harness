#!/usr/bin/env bash
# check-secrets.sh — refuse to commit secrets or personal paths.
# Usage: scripts/check-secrets.sh            (staged files; used by .githooks/pre-commit)
#        scripts/check-secrets.sh --all      (every tracked + untracked file)
# No dependencies beyond git and grep. Upgrade path: gitleaks, if you want entropy checks.
set -uo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

if [ "${1:-}" = "--all" ]; then
  FILES="$(git ls-files --cached --others --exclude-standard)"
else
  FILES="$(git diff --cached --name-only --diff-filter=ACMR)"
fi
[ -z "$FILES" ] && exit 0

# Files that must never be committed, whatever they contain.
BANNED_NAMES='(^|/)(\.env(\..*)?|auth\.json|settings\.local\.json|.*\.pem|.*\.p12|.*\.key|id_rsa.*|id_ed25519.*|.*\.jsonl|.*\.sqlite|.*\.db)$'

# Content patterns. Personal absolute home paths count as a leak in a shared repo: write ~ instead.
PATTERNS=(
  '-----BEGIN [A-Z ]*PRIVATE KEY-----'
  'sk-[A-Za-z0-9_-]{16,}'
  'sk-ant-[A-Za-z0-9_-]{16,}'
  'AKIA[0-9A-Z]{16}'
  'gh[pousr]_[A-Za-z0-9]{20,}'
  'xox[abprs]-[A-Za-z0-9-]{10,}'
  'AIza[0-9A-Za-z_-]{30,}'
  '(api[_-]?key|secret|token|password)["'"'"']?\s*[:=]\s*["'"'"'][^"'"'"']{8,}'
  '/Users/[A-Za-z0-9._-]+/'
  '/home/[A-Za-z0-9._-]+/'
)

status=0
while IFS= read -r f; do
  [ -f "$f" ] || continue
  if printf '%s' "$f" | grep -Eq "$BANNED_NAMES"; then
    echo "BLOCKED file name: $f"; status=1; continue
  fi
  # skip binaries
  if grep -Iq . "$f" 2>/dev/null; then
    for p in "${PATTERNS[@]}"; do
      hits="$(grep -nE -e "$p" -- "$f" 2>&1)"; rc=$?; hits="$(printf '%s\n' "$hits" | head -3)"
      if [ "$rc" = 2 ]; then
        echo "SCAN ERROR on $f (pattern: $p): $hits"; status=1
      elif [ -n "$hits" ]; then
        echo "BLOCKED $f (pattern: $p)"; printf '%s\n' "$hits" | sed 's/^/    /'; status=1
      fi
    done
  fi
done <<< "$FILES"

if [ "$status" != 0 ]; then
  echo
  echo "Commit refused. Remove the secret or replace the absolute home path with ~."
fi
exit "$status"
