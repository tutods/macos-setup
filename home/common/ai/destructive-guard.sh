#!/usr/bin/env bash
# PreToolUse(Bash): the irreversible commands shared.md names get a human "ask" even in auto mode; recursive rm stays free only when every target is under /tmp or $TMPDIR.
# No `set -e`: every failure path must exit 0 (allow).
set -uo pipefail

cmd=$(jq -r '.tool_input.command // ""' 2>/dev/null) || exit 0
[ -n "$cmd" ] || exit 0

recursive_rm_outside_tmp() {
  local seg tok recursive targets_ok
  while IFS= read -r seg; do
    recursive=0
    targets_ok=1
    # shellcheck disable=SC2086
    set -f
    for tok in ${seg#*rm}; do
      tok=${tok//[\"\']/}
      case "$tok" in
        --recursive) recursive=1 ;;
        -*[rR]*) [[ "$tok" != --* ]] && recursive=1 ;;
        -*) ;;
        *)
          case "$tok" in
            *'/../'* | *'/..') targets_ok=0 ;;
            /tmp/* | '$TMPDIR'/* | '${TMPDIR}'/*) ;;
            *) targets_ok=0 ;;
          esac
          ;;
      esac
    done
    set +f
    if [ "$recursive" = 1 ] && [ "$targets_ok" = 0 ]; then return 0; fi
  done < <(printf '%s' "$cmd" | grep -Eo '(^|[[:space:];&|])rm[[:space:]][^;&|]*')
  return 1
}

force_push() {
  local seg
  while IFS= read -r seg; do
    if printf '%s' "$seg" | grep -Eq '[[:space:]]push[[:space:]]' &&
      printf '%s' "$seg" | grep -Eq '[[:space:]](-[a-zA-Z]*f[a-zA-Z]*|--force[a-z-]*)([[:space:]=]|$)|[[:space:]]\+[^[:space:]]'; then
      return 0
    fi
  done < <(printf '%s' "$cmd" | grep -Eo 'git[[:space:]][^;&|]*')
  return 1
}

what=""
if printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+reset([[:space:]]+-[^[:space:]]+)*[[:space:]]+--hard'; then
  what="git reset --hard"
elif printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+clean([[:space:]]+-[^[:space:]]*)*[[:space:]]+-[a-zA-Z]*[fdx]'; then
  what="git clean"
elif printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+(checkout|restore)[[:space:]]+(--[[:space:]]+)?\.([[:space:]]|$)'; then
  what="git checkout/restore of the whole tree"
elif force_push; then
  what="git push --force"
elif recursive_rm_outside_tmp; then
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
