#!/usr/bin/env bash
# PreToolUse(Bash) guard, blocks co-author trailers and AI attribution in
# commits, PRs and PR reviews, inline or via a referenced body file.
# Intentionally overrides the default Co-Authored-By trailer.
#
# No `set -e`: every path must degrade to allow (exit 0), so a parse failure
# here can never block an unrelated command.
set -uo pipefail

input=$(cat)

cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)
[ -z "$cmd" ] && exit 0

if ! printf '%s' "$cmd" | grep -Eq '(git[[:space:]]+(-C[[:space:]]+[^[:space:]]+[[:space:]]+)?commit)|(gh[[:space:]]+pr[[:space:]]+(create|edit|comment|review))|(gh[[:space:]]+api)'; then
  exit 0
fi

content=$cmd

files=$(printf '%s' "$cmd" | grep -oE '(--body-file|--input|--file|-F)(=|[[:space:]]+)[^[:space:]]+' | sed -E 's/^(--body-file|--input|--file|-F)(=|[[:space:]]+)//')
for f in $files; do
  f=$(printf '%s' "$f" | sed -E "s/^[\"']//; s/[\"']$//")
  if [ -f "$f" ]; then
    content="$content
$(cat "$f" 2>/dev/null)"
  fi
done

if printf '%s' "$content" | grep -iEq 'co-authored-by:|🤖|generated with claude code|claude\.com/claude-code|automated cross-pr review|review by claude code'; then
  cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Blocked by global policy: this commit/PR/review command contains a co-author trailer or AI attribution (e.g. 'Co-Authored-By:', the robot emoji, 'Generated with Claude Code', a claude.com/claude-code link, or an 'Automated cross-PR review by Claude Code' / 'review by Claude Code' attribution). Commits, PRs, and PR reviews must not include any co-author tags or AI attribution. Re-issue the command with those lines removed from the message/title/body and from any -F/--body-file/--input file."}}
JSON
  exit 0
fi

exit 0
