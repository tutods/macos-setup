#!/usr/bin/env bash
# PreToolUse(Agent): a dispatch must name haiku, sonnet or opus; fork, an omitted model and any other model are denied.
# No `set -e`: every failure path must exit 0 (allow).
set -uo pipefail

input=$(cat)
parsed=$(printf '%s' "$input" | jq -r '.tool_input.subagent_type // "", .tool_input.model // ""' 2>/dev/null) || exit 0

{
  IFS= read -r subagent_type
  IFS= read -r model
} <<EOF
$parsed
EOF

if [ "$subagent_type" = "fork" ]; then
  reason="fork inherits the parent model; dispatch general-purpose or Explore with an explicit model instead."
else
  case "$model" in
    haiku | sonnet | opus | claude-haiku-* | claude-sonnet-* | claude-opus-*) exit 0 ;;
    "") reason="model is required." ;;
    *) reason="model '$model' is not allowed." ;;
  esac
fi

jq -cn --arg r "Subagent model gate: $reason Pick by complexity: haiku (mechanical, 1-2 files), sonnet (multi-file, integration), opus (architecture, review, hard reasoning). Never fable, never fork." \
  '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $r}}' 2>/dev/null

exit 0
