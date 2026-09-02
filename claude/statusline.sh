#!/bin/bash
# Ambient usage-focused Claude Code status line.
# Reads the session JSON from stdin (see ~/.claude/settings.json -> statusLine.command).
# Shows: model | dir (git branch) | ctx% | rate-limit% (or token fallback).

input="$(cat)"

IFS=$'\t' read -r model_name cwd used_pct five_hour seven_day tok_in tok_out <<< "$(jq -r '
  [
    (.model.display_name // "?"),
    (.workspace.current_dir // .cwd // "."),
    (.context_window.used_percentage // "-"),
    (.rate_limits.five_hour.used_percentage // "-"),
    (.rate_limits.seven_day.used_percentage // "-"),
    (.context_window.total_input_tokens // "-"),
    (.context_window.total_output_tokens // "-")
  ] | @tsv
' <<< "$input")"

# "-" is a jq-side sentinel: empty TSV fields would collapse under bash read (tab is IFS whitespace) and shift values left.
[ "$used_pct" = "-" ] && used_pct=""
[ "$five_hour" = "-" ] && five_hour=""
[ "$seven_day" = "-" ] && seven_day=""
[ "$tok_in" = "-" ] && tok_in=""
[ "$tok_out" = "-" ] && tok_out=""

dir_base="$(basename "$cwd")"

branch=""
if git -C "$cwd" --no-optional-locks rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch="$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)"
fi

reset=$'\033[0m'

# green <60%, yellow <85%, red >=85%
color_for() {
  local i="${1%.*}"
  [ -z "$i" ] && return
  if   [ "$i" -ge 85 ]; then printf '\033[31m'
  elif [ "$i" -ge 60 ]; then printf '\033[33m'
  else                       printf '\033[32m'
  fi
}

ctx_str=""
if [ -n "$used_pct" ]; then
  c="$(color_for "$used_pct")"
  ctx_str="$(printf 'ctx %s%.0f%%%s' "$c" "$used_pct" "$reset")"
fi

limit_str=""
if [ -n "$five_hour" ] || [ -n "$seven_day" ]; then
  if [ -n "$five_hour" ]; then
    c="$(color_for "$five_hour")"
    limit_str="$(printf '5h %s%.0f%%%s' "$c" "$five_hour" "$reset")"
  fi
  if [ -n "$seven_day" ]; then
    c="$(color_for "$seven_day")"
    seven_str="$(printf '7d %s%.0f%%%s' "$c" "$seven_day" "$reset")"
    if [ -n "$limit_str" ]; then limit_str="$limit_str  $seven_str"; else limit_str="$seven_str"; fi
  fi
elif [ -n "$tok_in" ] || [ -n "$tok_out" ]; then
  # No rate_limits exposed this session -> best-available proxy: cumulative context tokens.
  limit_str="tok ${tok_in:-0}/${tok_out:-0}"
fi

line="$model_name"
[ -n "$dir_base" ] && line="$line  $dir_base"
[ -n "$branch" ] && line="$line ($branch)"
[ -n "$ctx_str" ] && line="$line  $ctx_str"
[ -n "$limit_str" ] && line="$line  $limit_str"

printf '%s\n' "$line"
