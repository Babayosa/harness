#!/usr/bin/env bash
# config-protection.sh — PreToolUse hook for Edit|Write
# Prevents weakening lint/format/build configs. Fix the code, not the config.
set -euo pipefail

input=$(cat)

file_path=$(echo "$input" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    fp = data.get('tool_input', {}).get('file_path', '')
    print(fp)
except:
    print('')
" 2>/dev/null)

if [ -z "$file_path" ]; then
    exit 0
fi

basename=$(basename "$file_path")

case "$basename" in
    .swiftlint.yml)           matched=1 ;;
    project.yml)              matched=1 ;;
    .biome.json|.biome.jsonc) matched=1 ;;
    .eslintrc*)               matched=1 ;;
    eslint.config.*)          matched=1 ;;
    .prettierrc*)             matched=1 ;;
    ruff.toml|.ruff.toml)     matched=1 ;;
    *)                        matched=0 ;;
esac

if [ "$matched" -eq 1 ]; then
    echo "BLOCKED: $basename is a protected config file. Fix the code, don't weaken the config. If this edit is genuinely needed, ask the user for explicit approval." >&2
    exit 2
fi

exit 0
