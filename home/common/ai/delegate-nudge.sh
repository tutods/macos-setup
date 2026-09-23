#!/usr/bin/env bash
# PreToolUse(Read|Grep|Glob) hard gate. Denies a further DISTINCT inline recon
# target once a turn passes CLAUDE_RECON_LIMIT (default 8); re-reading an
# already-counted target stays free. Turn-boundary logic (subagent bail,
# prompt_id turn key, counter dir, 2h GC) is shared with force-delegation.sh
# via lib/turn-key.sh. No `set -e`: every path must degrade to exit 0 (allow).
set -uo pipefail

limit="${CLAUDE_RECON_LIMIT:-8}"
case "$limit" in '' | *[!0-9]* | 0) limit=8 ;; esac

lib="$(dirname "$0")/lib/turn-key.sh"
[ -r "$lib" ] || exit 0
. "$lib"

input=$(cat)

{
  IFS= read -r agent_id
  IFS= read -r turn
  IFS= read -r target
} <<EOF
$(printf '%s' "$input" | jq -r '.agent_id // "", .prompt_id // "", (.tool_input.file_path // .tool_input.pattern // .tool_input.path // "")' 2>/dev/null)
EOF

[ -z "$target" ] && exit 0

turn_counter claude-delegate-recon "$agent_id" "$turn" || exit 0

printf '%s\n' "$target" >> "$counter"

rank=$(awk '!seen[$0]++' "$counter" 2>/dev/null | grep -Fxn -- "$target" | head -n1 | cut -d: -f1)
case "$rank" in '' | *[!0-9]*) exit 0 ;; esac
[ "$rank" -le "$limit" ] && exit 0

printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Delegation: %s distinct inline Read/Grep/Glob targets this turn is the cap. Dispatch Explore or caveman:cavecrew-investigator with the full brief. Re-reads are free."}}\n' "$limit"

exit 0
