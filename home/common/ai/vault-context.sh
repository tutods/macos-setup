#!/bin/sh
# SessionStart hook — injects the Obsidian vault into every session as durable
# memory. Silent no-op (exit 0, no output) when the vault or a folder is absent.
#
# Core folders (Conventions, Lessons, Decisions, Process, Projects, Clients,
# Notes) are injected as FULL note bodies — exhaustive by design, so no grep or
# summary step can drop a lesson. Prompts/ is a prompt library, not working
# memory: titles only, bodies fetched on demand via the obsidian-vault skill.
# Templates/ and root files (Index.md, Vault.base) are never injected.
#
# Each note is preceded by a "## <vault-relative path>" header so content stays
# attributable to its source note.

set -euo pipefail

vault="$HOME/Obsidian"
[ -d "$vault" ] || exit 0

# Full bodies of every note under $1 (folder name), section-headed by $1.
dump_folder() {
  dir="$vault/$1"
  [ -d "$dir" ] || return 0
  echo "# $1"
  find "$dir" -name "*.md" | sort | while IFS= read -r f; do
    echo "## ${f#"$vault/"}"
    cat "$f"
    echo
  done
}

for folder in Conventions Lessons Decisions Process Projects Clients Notes; do
  dump_folder "$folder"
done

if [ -d "$vault/Prompts" ]; then
  echo "# Prompts (titles only — read the note when one is needed)"
  find "$vault/Prompts" -name "*.md" | sed "s|.*/Prompts/||;s|\\.md\$||" | sort
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
