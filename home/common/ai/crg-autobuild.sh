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
  nice -n 10 code-review-graph "$action" -q --repo "$repo" >"$log" 2>&1 || true
) &

exit 0
