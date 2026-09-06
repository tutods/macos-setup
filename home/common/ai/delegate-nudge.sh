#!/usr/bin/env bash
# PreToolUse(Read|Grep|Glob) nudge. Counts inline recon calls per user turn on
# the main thread and, once past a threshold, injects a reminder that recon
# belongs in a subagent. Never denies.
#
# Turn-boundary logic (subagent bail via agent_id, prompt_id turn key,
# counter dir, 2h GC) is shared with force-delegation.sh via lib/turn-key.sh
# so the two never define "a turn" differently.
#
# No `set -e`: every path must degrade to exit 0, so a parse failure here can
# never block an unrelated tool call.
set -uo pipefail

threshold=3

lib="$(dirname "$0")/lib/turn-key.sh"
[ -r "$lib" ] || exit 0
. "$lib"

input=$(cat)

# Parse stdin once; if jq fails, both stay empty and turn_counter bails.
{
  IFS= read -r agent_id
  IFS= read -r turn
} <<EOF
$(printf '%s' "$input" | jq -r '.agent_id // "", .prompt_id // ""' 2>/dev/null)
EOF

turn_counter claude-delegate-nudge "$agent_id" "$turn" || exit 0

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
