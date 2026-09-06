#!/usr/bin/env bash
# PreToolUse(Edit|Write) hard gate. Allows main-thread mutations to a small
# per-turn allowance of DISTINCT files — delegation.md's grace allowance (2
# distinct files per turn), the hook-enforced form of its "a single
# already-known file or a one-line change" exception — then hard-denies any
# mutation that would spread to a further file, so real multi-file work is
# forced through a subagent instead of merely nudged. Repeated edits to an
# already-allowed file are unlimited: the contract's exception is about scope
# (how many files), not call count.
#
# Turn-boundary logic (subagent bail via agent_id, prompt_id turn key,
# counter dir, 2h GC) is shared with delegate-nudge.sh via lib/turn-key.sh so
# the two never define "a turn" differently. The counter files themselves are
# independent (different tool set, different outcome: soft nudge once per
# turn vs hard deny per out-of-allowance file).
#
# No `set -e`: every path must degrade to exit 0 (allow), so a parse failure
# here can never lock the user out of their own edits.
set -uo pipefail

grace=2 # distinct files per turn

lib="$(dirname "$0")/lib/turn-key.sh"
[ -r "$lib" ] || exit 0
. "$lib"

input=$(cat)

# Parse stdin once; if jq fails, all three stay empty and we fail open below.
{
  IFS= read -r agent_id
  IFS= read -r turn
  IFS= read -r file_path
} <<EOF
$(printf '%s' "$input" | jq -r '.agent_id // "", .prompt_id // "", .tool_input.file_path // ""' 2>/dev/null)
EOF

# No target path means nothing to count against the file allowance.
[ -z "$file_path" ] && exit 0

turn_counter claude-force-delegation "$agent_id" "$turn" || exit 0

# One line per mutation call: the path it targets. append is atomic for a
# write this small, so parallel mutation calls in one message each land their
# own line instead of racing a read-increment-write.
printf '%s\n' "$file_path" >> "$counter"

# Rank of this path among the turn's distinct paths, in first-appearance
# order. Ranks never shift: the first `grace` files stay editable all turn,
# and a denied path keeps its over-allowance rank and stays denied.
rank=$(awk '!seen[$0]++' "$counter" 2>/dev/null | grep -Fxn -- "$file_path" | head -n1 | cut -d: -f1)
case "$rank" in '' | *[!0-9]*) exit 0 ;; esac
[ "$rank" -le "$grace" ] && exit 0

cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Delegation Contract: main-thread mutations are capped at 2 distinct files per turn (a single already-known file or a one-line change; repeat edits to those files are fine). This call would spread to a further file; dispatch a subagent instead (general-purpose for multi-file work, dev-lifecycle for a scoped, fully-specified fix) rather than widening inline."}}
JSON

exit 0
