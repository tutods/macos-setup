#!/usr/bin/env bash
# PreToolUse(Edit|Write|MultiEdit) hard gate. Allows a small per-turn grace
# allowance of main-thread file mutations (matching delegation.md's "a single
# already-known file or a one-line change" exception, and the 1-2 file
# language in model-selection.md), then hard-denies further inline mutations
# so real work is forced through a subagent instead of merely nudged.
#
# Subagents fire the same PreToolUse hooks, so a non-empty agent_id (set only
# inside a subagent) is the discriminator: bail immediately when present,
# same detection delegate-nudge.sh uses. Never restrict a subagent.
#
# Independent counter from delegate-nudge.sh (different tool set, different
# outcome: soft nudge once per turn vs hard deny every call past grace), but
# identical turn-boundary logic (same key fields, same atomic-append
# counting, same 2-hour GC) so the two never define "a turn" differently.
#
# No `set -e`: every path must degrade to exit 0 (allow), so a parse failure
# here can never lock the user out of their own edits.
set -uo pipefail

grace=2

input=$(cat)

agent_id=$(printf '%s' "$input" | jq -r '.agent_id // empty' 2>/dev/null)
[ -n "$agent_id" ] && exit 0

turn=$(printf '%s' "$input" | jq -r '.prompt_id // .session_id // empty' 2>/dev/null)
[ -z "$turn" ] && exit 0

dir="${TMPDIR:-/tmp}/claude-force-delegation"
mkdir -p "$dir" 2>/dev/null || exit 0
find "$dir" -mindepth 1 -maxdepth 1 -mmin +120 -exec rm -rf {} + 2>/dev/null

safe_turn=$(printf '%s' "$turn" | tr -c 'A-Za-z0-9._-' '_')
counter="$dir/$safe_turn"

# One byte per call. append is atomic for a write this small, so parallel
# mutation calls in one message each land their own byte instead of racing a
# read-increment-write.
printf '.' >> "$counter"
count=$(wc -c < "$counter" 2>/dev/null | tr -d ' ')
case "$count" in '' | *[!0-9]*) count=0 ;; esac

# First `grace` main-thread mutations this turn are allowed (single
# already-known file / one-line change); every one after that is denied,
# every time, not just once, unlike the nudge.
[ "$count" -le "$grace" ] && exit 0

cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Delegation Contract: main-thread file mutations are capped at 2 per turn (a single already-known file or a one-line change). This edit goes past that; dispatch a subagent instead (general-purpose for multi-file work, dev-lifecycle for a scoped, fully-specified fix) rather than continuing inline."}}
JSON

exit 0
