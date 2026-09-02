---
name: verdict
description: Track and close the loops that grade you, not the tools — open verdicts with ages in days, closed only by a recorded number or a human's answer.
---

# Verdict

Keeps `~/tasks/verdicts.md` honest. Born from the 2026-07-18 mirror finding: every scoreboard that grades a tool gets built; every scoreboard that grades the person gets postponed (QT backtest requested 02-17/03-04/04-02, never closed; "should I apply?" 05-08, then silence).

## Usage

`/verdict` — show open loops with age in days, oldest first. Then ask one question: "Which one closes today?" and help close it in this session if the user picks one.
`/verdict close <name> <number/outcome>` — record closure with today's date.
`/verdict add <name>` — add a loop. A valid loop names WHO or WHAT NUMBER will judge it.

## Rules

- A loop closes ONLY with a recorded number or a human's answer. Tool metrics (eval pass rates, CI green, lint clean, "the agent verified it") never close a loop.
- Never delete an open loop to tidy the file. Loops leave by closing or by an explicit user decision to drop them — record drops with a dated reason.
- No moralizing, no streaks, no guilt language. Ages in days and receipts only; the numbers do the talking.
- If every loop is >30 days old, say exactly that, once: "Every open verdict is over a month old. The tooling is not what's behind."

## Weekly

When invoked in a new week (vs the file's `last-reviewed` stamp), also check the CLAUDE.md weekly-human-verdict rule: did anything go in front of a human or human-facing scoreboard in the last 7 days? Record yes/no with the receipt. Update `last-reviewed`.
