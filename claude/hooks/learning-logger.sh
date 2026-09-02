#!/usr/bin/env bash
# learning-logger.sh — PostToolUse hook for all tools
# Logs every tool invocation to a daily log file for review.
# Reads JSON from stdin, extracts tool name + key details.

set -euo pipefail

LOG_DIR="$HOME/.claude/logs"
mkdir -p "$LOG_DIR"

LOG_FILE="$LOG_DIR/claude-activity-$(date +%Y-%m-%d).log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

input=$(cat)

# Extract tool name and key details
details=$(echo "$input" | python3 -c "
import sys, json

try:
    data = json.load(sys.stdin)
    tool_name = data.get('tool_name', 'unknown')
    tool_input = data.get('tool_input', {})

    detail = ''
    if tool_name == 'Bash':
        detail = tool_input.get('command', '')[:200]
    elif tool_name == 'Read':
        detail = tool_input.get('file_path', '')
    elif tool_name == 'Write':
        detail = tool_input.get('file_path', '')
    elif tool_name == 'Edit':
        detail = tool_input.get('file_path', '')
    elif tool_name == 'Glob':
        detail = tool_input.get('pattern', '')
    elif tool_name == 'Grep':
        detail = tool_input.get('pattern', '')
    elif tool_name == 'WebFetch':
        detail = tool_input.get('url', '')
    elif tool_name == 'WebSearch':
        detail = tool_input.get('query', '')
    elif tool_name == 'Task':
        detail = tool_input.get('description', '')
    else:
        # Generic: show first key-value pair
        for k, v in tool_input.items():
            detail = f'{k}={str(v)[:100]}'
            break

    print(f'{tool_name} | {detail}')
except Exception as e:
    print(f'parse-error | {e}')
" 2>/dev/null)

echo "[$TIMESTAMP] $details" >> "$LOG_FILE"

# Hooks must exit 0 to not block the workflow
exit 0
