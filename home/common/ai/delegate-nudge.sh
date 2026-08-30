#!/usr/bin/env bash
# PreToolUse(Read|Grep|Glob) nudge. Counts inline recon calls per user turn on
# the main thread and, once past a threshold, injects a reminder that recon
# belongs in a subagent. Never denies.
#
# Subagents fire the same PreToolUse hooks, so a non-empty agent_id (set only
# inside a subagent) is the discriminator: bail immediately when present.
#
# No `set -e`: every path must degrade to exit 0, so a parse failure here can
# never block an unrelated tool call.
set -uo pipefail

threshold=3

input=$(cat)

agent_id=$(printf '%s' "$input" | jq -r '.agent_id // empty' 2>/dev/null)
[ -n "$agent_id" ] && exit 0

turn=$(printf '%s' "$input" | jq -r '.prompt_id // .session_id // empty' 2>/dev/null)
[ -z "$turn" ] && exit 0

dir="${TMPDIR:-/tmp}/claude-delegate-nudge"
mkdir -p "$dir" 2>/dev/null || exit 0
find "$dir" -mindepth 1 -maxdepth 1 -mmin +120 -exec rm -rf {} + 2>/dev/null

safe_turn=$(printf '%s' "$turn" | tr -c 'A-Za-z0-9._-' '_')
counter="$dir/$safe_turn"

# One byte per call. append is atomic for a write this small, so parallel recon
# calls in one message each land their own byte instead of racing a
# read-increment-write.
printf '.' >> "$counter"
count=$(wc -c < "$counter" 2>/dev/null | tr -d ' ')
case "$count" in '' | *[!0-9]*) count=0 ;; esac

[ "$count" -lt "$threshold" ] && exit 0

# Fire once per turn: mkdir is atomic, so exactly one instance past the
# threshold creates the marker and emits, the rest see EEXIST and exit.
mkdir "$counter.fired" 2>/dev/null || exit 0

cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"Delegation Contract: that is the third inline Read/Grep/Glob this turn on the main thread. Recon goes to Explore or caveman:cavecrew-investigator, multi-file edits to general-purpose, diff/PR review to code-reviewer, vault lookups to vault-search, each with an explicit model. If more searching is coming, dispatch a subagent instead of continuing inline."}}
JSON

exit 0
