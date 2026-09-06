#!/usr/bin/env bash
# SessionStart hook: makes the code-review-graph MCP server answer without a
# manual step. Its tools fail with "No graph found at .../graph.db. Run
# `code-review-graph build` first" in any repo that was never built, which is
# every new repo.
#
# Deliberately NOT `code-review-graph install`: that subcommand registers hooks
# and generated instruction files across every AI CLI it knows about (Gemini,
# Cursor, Windsurf, Cline, Kilo, Antigravity, Kimi), and this machine runs
# Claude Code and opencode only. `build` and `update` touch nothing outside the
# repo's own .code-review-graph/ directory, which is gitignored in cli/git.nix.
#
# Always backgrounded: a first build on a large repo takes minutes, and a
# SessionStart hook that blocks is a session that will not start.

set -euo pipefail

command -v code-review-graph >/dev/null 2>&1 || exit 0

repo=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
[ -n "$repo" ] || exit 0

db="$repo/.code-review-graph/graph.db"
log="$repo/.code-review-graph/autobuild.log"
lock="$repo/.code-review-graph/.autobuild.lock"

# mkdir is the atomic test-and-set: two sessions opened in the same repo at the
# same time would otherwise both start a full parse over one database.
mkdir -p "$repo/.code-review-graph"

# A crash or reboot mid-build never runs the EXIT trap, leaving the lock behind
# and silently disabling this hook forever. No build takes 2 hours; reclaim.
if [ -d "$lock" ] && [ -n "$(find "$lock" -maxdepth 0 -mmin +120 2>/dev/null)" ]; then
  rmdir "$lock" 2>/dev/null || true
fi

# Content-stamped skip: HEAD plus working-tree status hashes the state the last
# successful run parsed. Most sessions open on an unchanged tree, and `update`
# still walks the whole repo to discover nothing changed; this makes that case
# free. The stamp is written only after a successful run, from the state
# captured BEFORE the run started, so edits landing mid-build re-trigger next
# session instead of being silently absorbed.
stamp="$repo/.code-review-graph/.autobuild.stamp"
state=$({
  git -C "$repo" rev-parse HEAD 2>/dev/null || echo no-head
  git -C "$repo" status --porcelain 2>/dev/null
} | shasum | cut -d' ' -f1)
if [ -f "$db" ] && [ "$(cat "$stamp" 2>/dev/null)" = "$state" ]; then
  exit 0
fi

if ! mkdir "$lock" 2>/dev/null; then
  exit 0
fi

if [ -f "$db" ]; then
  action=update
else
  action=build
fi

# nice, because this races the user's own builds and tests for the same cores.
(
  trap 'rmdir "$lock" 2>/dev/null || true' EXIT
  if nice -n 10 code-review-graph "$action" -q --repo "$repo" >"$log" 2>&1; then
    printf '%s\n' "$state" >"$stamp"
  fi
) &

exit 0
