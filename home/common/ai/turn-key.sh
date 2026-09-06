# shellcheck shell=bash
# Shared turn-boundary logic for the per-turn PreToolUse counters
# (delegate-nudge.sh, force-delegation.sh). Sourced, not executed; deployed to
# ~/.claude/hooks/lib/turn-key.sh. Keeping this in one file is what stops the
# two hooks from ever defining "a turn" differently.
#
# turn_counter <namespace> <agent_id> <prompt_id>
#   On success returns 0 and sets $counter to this turn's counter-file path.
#   Returns 1 when the caller must bail out (exit 0, i.e. allow/stay silent):
#     - agent_id non-empty: subagents fire the same PreToolUse hooks, and a
#       non-empty agent_id (set only inside a subagent) is the discriminator.
#       Never restrict or nudge a subagent.
#     - prompt_id empty: no reliable turn boundary. Falling back to
#       session_id would turn a per-turn counter into a per-session one on
#       any Claude Code binary lacking prompt_id — and since every counted
#       call refreshes the counter file's mtime, the 2-hour GC below would
#       never fire, making a lockout permanent. Every failure path in these
#       hooks degrades to allow; a missing turn key must too.
#     - the counter dir cannot be created.
turn_counter() {
  _tk_ns=$1
  _tk_agent_id=$2
  _tk_prompt_id=$3

  [ -n "$_tk_agent_id" ] && return 1
  [ -z "$_tk_prompt_id" ] && return 1

  _tk_dir="${TMPDIR:-/tmp}/$_tk_ns"
  mkdir -p "$_tk_dir" 2>/dev/null || return 1
  # GC turns older than 2 hours so the dir never grows unbounded.
  find "$_tk_dir" -mindepth 1 -maxdepth 1 -mmin +120 -exec rm -rf {} + 2>/dev/null

  _tk_safe=$(printf '%s' "$_tk_prompt_id" | tr -c 'A-Za-z0-9._-' '_')
  counter="$_tk_dir/$_tk_safe"
  return 0
}
