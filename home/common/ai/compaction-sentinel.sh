#!/usr/bin/env bash
# Latches "this session has been compacted" into a sentinel file, so the
# per-prompt hook (delegation-reminder.sh) can answer that question with a
# single `[ -f ]` instead of scanning the transcript on every turn. Wired to
# two one-shot events:
#
#   PreCompact   compaction is about to land: latch unconditionally.
#   SessionStart a fresh, resumed or forked session: latch only if this
#                transcript already carries a compact_boundary marker, so a
#                --resume or fork of an already-compacted session keeps the
#                reminder alive under its new session id.
#
# The transcript scan lives here, not in the prompt hook, because these events
# fire once per session or compaction rather than once per prompt. On the work
# laptop, whose EDR (Cortex XDR) scans every exec and every file read, the
# per-prompt version of that scan cost 2-4s and blew the prompt hook's
# timeout on most turns, discarding the reminder it existed to inject.
#
# PreCompact and not PostCompact: PostCompact is in settings.nix's
# keepHookEvents (Orca appends its own entry there) and the deploy merge lets
# the Nix value win, so declaring it here would drop Orca's hook.
#
# No `set -e`: every failure path must degrade to silence (exit 0). A missing
# sentinel costs the reminder, never the session.
set -uo pipefail

input=
IFS= read -r -d '' input || :

# Pure-bash extraction: no jq, no cat, so the SessionStart-at-startup path
# (the common one) forks nothing at all.
sid_re='"session_id"[[:space:]]*:[[:space:]]*"([^"]+)"'
sid=
[[ $input =~ $sid_re ]] && sid=${BASH_REMATCH[1]}
# The value becomes a path segment, so reject anything that is not a bare id.
case "$sid" in
  '' | *[!A-Za-z0-9._-]*) exit 0 ;;
esac

dir="${TMPDIR:-/tmp}/claude-compacted"
mkdir -p "$dir" 2>/dev/null || exit 0
# GC week-old sentinels so the dir never grows unbounded. Affordable here:
# once per session, not once per prompt. A sentinel must outlive its session,
# so this is 7 days and not the 2h the per-turn counters use (turn-key.sh).
find "$dir" -mindepth 1 -maxdepth 1 -mtime +7 -delete 2>/dev/null

sentinel="$dir/$sid"
[ -f "$sentinel" ] && exit 0

event_re='"hook_event_name"[[:space:]]*:[[:space:]]*"([^"]+)"'
event=
[[ $input =~ $event_re ]] && event=${BASH_REMATCH[1]}

if [ "$event" != "PreCompact" ]; then
  # SessionStart: latch only when this transcript was compacted already.
  transcript_re='"transcript_path"[[:space:]]*:[[:space:]]*"([^"]+)"'
  transcript=
  [[ $input =~ $transcript_re ]] && transcript=${BASH_REMATCH[1]}
  [ -n "$transcript" ] && [ -f "$transcript" ] || exit 0
  grep -q '"subtype":"compact_boundary"' "$transcript" 2>/dev/null || exit 0
fi

: >"$sentinel" 2>/dev/null || :
exit 0
