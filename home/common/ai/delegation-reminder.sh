#!/bin/bash
# UserPromptSubmit hook: re-state the Delegation Contract, but only once the
# session has been compacted. Before compaction the full contract sits in the
# context (rules file), so re-injecting it every turn is a per-prompt tax with
# no benefit. Compaction drops it; from the first prompt after that boundary
# this hook restores a compressed restatement every turn.
#
# The boundary marker ("subtype":"compact_boundary") stays in the transcript
# file forever, so one grep answers "has this session ever been compacted".
# grep -q short-circuits on the first match; the 5s hook timeout covers the
# no-match scan of a very large transcript.
#
# No `set -e`: every failure path must degrade to silence (exit 0), a broken
# reminder can never block a prompt.
set -uo pipefail

input=$(cat)

transcript=$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null)
[ -n "$transcript" ] && [ -f "$transcript" ] || exit 0

grep -q '"subtype":"compact_boundary"' "$transcript" 2>/dev/null || exit 0

cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"DELEGATION ACTIVE (restored after compaction): main thread orchestrates; no inline read/search/edit unless it is one known file. 2+ independent units = multiple Agent calls in ONE message. Recon -> Explore. Multi-file edit -> general-purpose. Diff review -> code-reviewer. Vault -> vault-search. Pass `model` on every dispatch. Not for user decisions, commits/PRs, or destructive ops."}}
JSON

exit 0
