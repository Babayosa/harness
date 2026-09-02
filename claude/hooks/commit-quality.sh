#!/usr/bin/env bash
# commit-quality.sh — PreToolUse hook for Bash
# Scans staged changes before git commit for debug artifacts and secrets.
set -euo pipefail

input=$(cat)

command=$(echo "$input" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('tool_input', {}).get('command', ''))
except:
    print('')
" 2>/dev/null)

# Only intercept git commit commands
case "$command" in
    git\ commit*) ;;
    *) exit 0 ;;
esac

# Get staged diff
diff_output=$(git diff --cached 2>/dev/null) || exit 0

if [ -z "$diff_output" ]; then
    exit 0
fi

warnings=""
blockers=""

# BLOCK: likely secrets
if echo "$diff_output" | grep -qE 'sk-[a-zA-Z0-9]{20,}'; then
    blockers="${blockers}\n  - Possible OpenAI/Stripe secret key (sk-...)"
fi
if echo "$diff_output" | grep -qE 'AKIA[A-Z0-9]{16}'; then
    blockers="${blockers}\n  - Possible AWS access key (AKIA...)"
fi
if echo "$diff_output" | grep -qE '\-\-\-\-\-BEGIN.*KEY\-\-\-\-\-'; then
    blockers="${blockers}\n  - Private key detected (-----BEGIN...KEY-----)"
fi

# WARN: debugger statements
if echo "$diff_output" | grep -qE '^\+.*\bdebugger\b'; then
    warnings="${warnings}\n  - JS debugger statement"
fi
if echo "$diff_output" | grep -qE '^\+.*\bbreakpoint\(\)'; then
    warnings="${warnings}\n  - breakpoint() statement"
fi
if echo "$diff_output" | grep -qE '^\+.*pdb\.set_trace'; then
    warnings="${warnings}\n  - Python pdb.set_trace()"
fi

# WARN: console.log in JS/TS
if echo "$diff_output" | grep -qE '^\+.*console\.(log|debug|info)\('; then
    warnings="${warnings}\n  - console.log/debug/info in JS/TS"
fi

# WARN: print/NSLog in Swift files (check diff headers for .swift)
if echo "$diff_output" | grep -qE '^\+\+\+ b/.*\.swift'; then
    if echo "$diff_output" | grep -qE '^\+.*\b(print\(|NSLog\()'; then
        warnings="${warnings}\n  - print()/NSLog() in Swift (not behind #if DEBUG?)"
    fi
fi

if [ -n "$blockers" ]; then
    printf "COMMIT BLOCKED — likely secrets in staged changes:%b\nRemove secrets before committing.\n" "$blockers" >&2
    exit 2
fi

if [ -n "$warnings" ]; then
    printf "COMMIT WARNING — review before committing:%b\n(Proceeding — these may be intentional.)\n" "$warnings" >&2
fi

exit 0
