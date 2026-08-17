#!/bin/sh
# SessionStart hook — injects Obsidian vault context into every session.
# Silent no-op (exit 0, no output) when the vault or a given folder is absent.
#
# Four sections, cheapest/most-general first:
#   1. Lesson titles           — the always-on "Prior Art" grep misses behavioral
#                                 lessons that don't match the session's keywords.
#   2. Convention + Decision    — standing rules and past choices, titles only.
#      titles
#   3. Convention bodies        — Conventions/ is small and is literally standing
#                                 rules, so it's worth the extra tokens to enforce
#                                 it rather than leave it grep-dependent.
#   4. This-project notes       — matches the session's cwd basename against each
#                                 note's `project:` frontmatter and surfaces paths
#                                 (not bodies) for anything filed under that slug.

set -euo pipefail

vault="$HOME/Obsidian"
[ -d "$vault" ] || exit 0

if [ -d "$vault/Lessons" ]; then
  echo "# Lessons"
  find "$vault/Lessons" -name "*.md" | sed "s|.*/Lessons/||;s|\\.md\$||" | sort
fi

if [ -d "$vault/Conventions" ] || [ -d "$vault/Decisions" ]; then
  echo "# Conventions & Decisions"
  titles=""
  [ -d "$vault/Conventions" ] && titles="$titles
$(find "$vault/Conventions" -name "*.md")"
  [ -d "$vault/Decisions" ] && titles="$titles
$(find "$vault/Decisions" -name "*.md")"
  printf '%s\n' "$titles" | sed "s|.*/||;s|\\.md\$||" | sed "/^\$/d" | sort
fi

if [ -d "$vault/Conventions" ]; then
  echo "# Convention Details"
  find "$vault/Conventions" -name "*.md" | sort | while IFS= read -r f; do
    cat "$f"
    echo
  done
fi

input=$(cat 2>/dev/null || true)
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null || true)
[ -z "$cwd" ] && cwd="$PWD"
slug=$(basename "$cwd")

matches=$(rg -l "^project: ${slug}\$" "$vault" 2>/dev/null || true)
if [ -n "$matches" ]; then
  echo "# This project ($slug)"
  printf '%s\n' "$matches" | sed "s|^$vault/||" | sort
fi

exit 0
