---
name: copying-to-clipboard
description: Use when the user says "pbcopy", "copy it", "copy that", "pbcopy again", or asks for an artifact, output, prompt, or text you produced to be put on the clipboard.
---

# Copying to Clipboard

## Overview

Bare `pbcopy` / "copy it" means: put the **full text of the most recent artifact** on the clipboard. The failure modes are silent byte corruption during transcription and — worse — **claiming fidelity you didn't prove**.

**Source hierarchy (determines what you may claim):**

| Source | Method | Claim you may make |
|---|---|---|
| Artifact exists on disk | `pbcopy < file`, then `pbpaste \| cmp - file` | Byte-exact, proven |
| Conversation-only text | Materialize → copy → roundtrip-check | Faithful transcription, stated limits |

If a file version exists (you just wrote it, or the user named it), **always copy from the file** — that is the only byte-exact path.

## What to copy

- The most recent complete deliverable (brief, prompt, essay, script, message) — full text, never a summary.
- "pbcopy again" → the current version of that same artifact (after any edits since).
- Multiple candidates in the last turn → copy the final deliverable (not intermediate output) and state which one you copied. Don't ask; the user expects immediate action.
- Artifact body only — no markdown fences, headers, or commentary that weren't part of it.

## Preflight — fail closed

Before touching the clipboard, confirm all of the following or stop (never silently no-op, never fabricate success):

- **Platform + tools.** Require macOS with `pbcopy`, `pbpaste`, and `trash` on `PATH` (`[ "$(uname -s)" = Darwin ] && command -v pbcopy >/dev/null && command -v pbpaste >/dev/null && command -v trash >/dev/null`). On any other host, or if any binary is missing, stop and tell the user clipboard copy isn't available here — don't invent a result.
- **Unambiguous source.** Resolve to exactly one artifact. If no single most-recent deliverable is identifiable (no clear source, or genuinely indistinguishable targets), stop and ask which — never guess or copy a partial. (Ranked candidates in one turn still resolve to the final deliverable per *What to copy*.) Keep that selected artifact as the source to materialize below; `$f` is not defined until the private temp file is created.

## Mechanics

1. **Preflight and create the private path (shell invocation 1).** In one shell, confirm macOS and `pbcopy`, `pbpaste`, and `trash` are on `PATH` using `[ "$(uname -s)" = Darwin ] && command -v pbcopy >/dev/null && command -v pbpaste >/dev/null && command -v trash >/dev/null`; resolve exactly one unambiguous artifact before proceeding; create one owner-only, unpredictable temp file with `f=$(mktemp -t pbcopy) && chmod 600 "$f"`; then return only its absolute path. Do **not** install an EXIT trap in this shell, and do not rely on the shell-local `$f` surviving the separate file-write tool boundary.
2. **Materialize at that exact path (file-write invocation).** Use the file-write tool to write the selected artifact's exact bytes to the absolute path returned by shell invocation 1. Never interpolate shell content, use `echo`/`printf` through a shell, use a predictable path, or create a second temp file.
3. **Validate and copy (one final shell invocation).** Pass the returned path as metadata only, never artifact content. Define the finalizer below, then make `trap finalize EXIT` the first executable operation in this shell; it captures the incoming operation status, disables the recursive EXIT trap, attempts `trash "$f"`, emits exactly one metadata-only human-readable cleanup-failed diagnostic to stderr if cleanup fails (without printing the path or artifact content), turns a successful operation into failure if cleanup fails, preserves an earlier nonzero operation status when cleanup also fails, and exits with the final status:

```bash
finalize() {
  status=$?
  trap - EXIT
  trash "$f" 2>/dev/null || {
    printf '%s\n' 'clipboard temporary-file cleanup failed' >&2
    [ "$status" -ne 0 ] || status=1
  }
  exit "$status"
}
trap finalize EXIT
```

Before any regular/readable/mode/UTF-8 checks, explicitly reject a symlink and validate the same path as a non-symlink regular readable file with `[ ! -L "$f" ] && [ -f "$f" ] && [ -r "$f" ]` and `iconv -f utf-8 -t utf-8 "$f" >/dev/null`; after materialization and before `pbcopy`, explicitly verify owner-only mode with `[ "$(stat -f '%Lp' "$f")" = 600 ]`. Preserve the artifact's final-newline state by inspecting only last-byte status without printing content; run `pbcopy < "$f"`, then `pbpaste | cmp - "$f"` and check the exit status; report only `wc -c < "$f"` and the cmp result. A failure or interruption between invocations 1–3 can leave the private file behind, so explicitly clean that exact path with `trash` before retrying. Cleanup failure is reported by the metadata-only stderr diagnostic above rather than claimed removed.
4. **Privacy-safe verification.** Never run `cat -A`, `cat -vet`, `od`, or another command that prints artifact bytes into terminal or transcript logs. For sensitive or potentially sensitive text, rely on the checked source-to-clipboard comparison above; do not expose content merely to inspect whitespace.
5. **Point-in-time limitation.** The roundtrip proves clipboard == this file only at check time; another process can overwrite the clipboard afterward, so do not claim more.

## Honest claims — the actual contract

For conversation-only artifacts, transcription is best-effort: labeled/visible whitespace and all characters you can see are recoverable; *unlabeled trailing whitespace* generally is not.

- ✅ "591 bytes, roundtrip clean; `$…` literal, tabs/unicode intact, no final newline. Transcribed from our conversation — if exact trailing whitespace matters (diffs, Makefiles, YAML), point me at a file version."
- ❌ "byte-for-byte identical" / "character-for-character" — PROHIBITED unless copied from an on-disk source and cmp-proven.
- ❌ "checked trailing whitespace" when you only checked the lines that announced themselves. Name the scope: which lines you verified, what you can't know.

For prose (essays, briefs, messages) don't drown the reply in caveats — one clause suffices. For whitespace-sensitive content (patches, scripts, config), the limitation sentence is mandatory or you copy from disk.

## Reply style

One or two lines: what was copied, byte count, scoped fidelity claim, any deliberate deviation ("stripped the code fence"). Never re-print the artifact.

## Common mistakes

| Mistake | Fix |
|---|---|
| `echo "$TEXT" \| pbcopy` | Shell mangles `$`/backticks. Write a file, redirect it. |
| Calling a roundtrip cmp against your own temp file "verified byte-for-byte" | Circular. It proves clipboard==file only. Scope the claim. |
| "Trailing whitespace is invisible, so I skipped it" — silently | The gap is fine; hiding it isn't. Declare it, and prefer an on-disk source. |
| Appending a final newline the artifact didn't have | Check last byte; truncate. |
| Copying a summary or partial section | Full artifact, always. |
| Overwriting the clipboard on your own initiative (tests, convenience) | Clipboard is user state. Write it only on request. |
