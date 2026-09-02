#!/usr/bin/env bash
# render-rules.sh — flatten a rules file with @imports into one self-contained file.
# Usage: scripts/render-rules.sh <entry-file> > AGENTS.md
# For harnesses that do not expand @imports (Codex, OpenCode, Cursor, most others).
#
# Rules: a line that is exactly "@<path>" is an import (~ and relative paths resolve
# from the importing file's directory). Up to 5 hops. Cycles skipped. A missing target
# is a hard error, never a silent gap. Inline @tokens mid-line are left as text.
set -euo pipefail

entry="${1:?usage: render-rules.sh <entry-file>}"
seen=""

resolve() {  # resolve <path> <base-dir>
  case "$1" in
    "~/"*) printf '%s' "$HOME/${1#\~/}" ;;
    /*)    printf '%s' "$1" ;;
    *)     printf '%s' "$2/$1" ;;
  esac
}

expand() {  # expand <file> <depth>
  local file="$1" depth="$2" dir line target
  [ -f "$file" ] || { echo "render-rules: missing import: $file" >&2; exit 1; }
  case "$seen" in *"|$file|"*) return ;; esac
  seen="$seen|$file|"
  dir="$(cd "$(dirname "$file")" && pwd)"
  while IFS= read -r line || [ -n "$line" ]; do
    if [[ "$line" =~ ^@([^[:space:]]+)$ ]] && [ "$depth" -lt 5 ]; then
      target="$(resolve "${BASH_REMATCH[1]}" "$dir")"
      expand "$target" $((depth + 1))
      printf '\n'
    else
      printf '%s\n' "$line"
    fi
  done < "$file"
}

expand "$(resolve "$entry" "$PWD")" 0
