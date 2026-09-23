#!/usr/bin/env bash
# PreToolUse(Bash): the irreversible commands shared.md names get a human "ask" even in auto mode; recursive rm under /tmp or $TMPDIR stays free.
# No `set -e`: every failure path must exit 0 (allow).
set -uo pipefail

cmd=$(jq -r '.tool_input.command // ""' 2>/dev/null) || exit 0
[ -n "$cmd" ] || exit 0

what=""
if printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+reset([[:space:]]+-[^[:space:]]+)*[[:space:]]+--hard'; then
  what="git reset --hard"
elif printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+clean([[:space:]]+-[^[:space:]]*)*[[:space:]]+-[a-zA-Z]*[fdx]'; then
  what="git clean"
elif printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+(checkout|restore)[[:space:]]+(--[[:space:]]+)?\.([[:space:]]|$)'; then
  what="git checkout/restore of the whole tree"
elif printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+push([[:space:]]+[^[:space:]]+)*[[:space:]]+(-f|--force|--force-with-lease)([[:space:]]|$|=)'; then
  what="git push --force"
elif printf '%s' "$cmd" | grep -Eq '(^|[[:space:];&|])rm[[:space:]]+(-[a-zA-Z]+[[:space:]]+)*-[a-zA-Z]*[rR]' && ! printf '%s' "$cmd" | grep -Eq '(/tmp/|TMPDIR)'; then
  what="recursive rm outside /tmp"
elif printf '%s' "$cmd" | grep -Eq '(^|[[:space:];&|])find[[:space:]].*(-delete|-exec[[:space:]]+rm)'; then
  what="find with -delete or -exec rm"
elif printf '%s' "$cmd" | grep -Eiq '(^|[^a-z])(drop|truncate)[[:space:]]+(table|database|schema)[[:space:]]'; then
  what="DROP/TRUNCATE"
fi

[ -n "$what" ] || exit 0

jq -cn --arg r "Destructive: $what. Irreversible per shared.md, so it needs your explicit yes here rather than auto approval." \
  '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "ask", permissionDecisionReason: $r}}' 2>/dev/null

exit 0
