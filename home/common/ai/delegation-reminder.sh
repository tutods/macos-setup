#!/usr/bin/env bash
# UserPromptSubmit hook: re-state the Delegation Contract, but only once the
# session has been compacted. Before compaction the full contract sits in the
# context (rules file), so re-injecting it every turn is a per-prompt tax with
# no benefit. Compaction drops it; from the first prompt after that boundary
# this hook restores a compressed restatement every turn.
#
# "Has this session been compacted" is answered by a sentinel file that
# compaction-sentinel.sh latches from PreCompact and SessionStart: one
# `[ -f ]` test, no transcript scan. This hook used to grep the whole
# transcript on every prompt instead, on the assumption that 5s covers a
# no-match scan. It does not on the work laptop, whose EDR (Cortex XDR) scans
# every exec and every file read: measured cat=0.9s, jq=1.1s, grep=2.4s on a
# 130MB transcript, so the hook timed out on most turns and the reminder was
# discarded exactly when it was needed. Nothing here forks a process now:
# stdin is read and parsed with bash builtins, and the output is a printf.
#
# No `set -e`: every failure path must degrade to silence (exit 0), a broken
# reminder can never block a prompt.
set -uo pipefail

input=
IFS= read -r -d '' input || :

sid_re='"session_id"[[:space:]]*:[[:space:]]*"([^"]+)"'
sid=
[[ $input =~ $sid_re ]] && sid=${BASH_REMATCH[1]}
# The value becomes a path segment, so reject anything that is not a bare id.
case "$sid" in
  '' | *[!A-Za-z0-9._-]*) exit 0 ;;
esac

[ -f "${TMPDIR:-/tmp}/claude-compacted/$sid" ] || exit 0

# Single quotes are the point: the payload's `model` backticks are literal
# JSON text, not a command substitution.
# shellcheck disable=SC2016
printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"DELEGATION ACTIVE (restored after compaction): main thread orchestrates; no inline read/search/edit unless it is one known file. 2+ independent units = multiple Agent calls in ONE message. Recon -> Explore. Multi-file edit -> general-purpose. Diff review -> code-reviewer. Vault -> vault-search. Pass `model` on every dispatch. Not for user decisions, commits/PRs, or destructive ops."}}'

exit 0
