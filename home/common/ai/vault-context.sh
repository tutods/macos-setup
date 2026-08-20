#!/bin/sh
# SessionStart hook — injects the Obsidian vault into every session as durable
# memory. Silent no-op (exit 0, no output) when the vault or a folder is absent.
#
# Core folders (the loop below is the authoritative list) are injected as FULL
# note bodies, in priority order, under a total byte budget
# (CLAUDE_VAULT_BUDGET, default 100000 ≈ 25k tokens). A folder that would push
# the running total over the budget degrades to titles only — never a
# half-truncated note — and its section header says so. Prompts/ is a prompt
# library, not working memory: always titles only, bodies fetched on demand.
# Templates/ and root files (Index.md, Vault.base) are never injected.
#
# Each note is preceded by a "## <vault-relative path>" header so content stays
# attributable to its source note.

set -euo pipefail

vault="$HOME/Obsidian"
[ -d "$vault" ] || exit 0

budget="${CLAUDE_VAULT_BUDGET:-100000}"
used=0

# Full bodies of every note under $1 (folder name), section-headed by $1.
dump_folder() {
  echo "# $1"
  find "$vault/$1" -name "*.md" | sort | while IFS= read -r f; do
    echo "## ${f#"$vault/"}"
    cat "$f"
    echo
  done
}

# Vault-relative titles (no .md extension) of every note under $1.
folder_titles() {
  find "$vault/$1" -name "*.md" | sed "s|^$vault/||;s|\\.md\$||" | sort
}

echo "# Obsidian vault (SessionStart injection)"
echo "Full note bodies below unless a section header says titles only (Prompts/ always; any folder over the session byte budget). Templates/ and vault-root files are never injected. To read anything titles-only or absent, dispatch the vault-search agent."
echo

for folder in Conventions Lessons Decisions Process Projects Clients Notes; do
  dir="$vault/$folder"
  [ -d "$dir" ] || continue
  size=$(find "$dir" -name "*.md" -exec cat {} + | wc -c | tr -d ' ')
  if [ $((used + size)) -le "$budget" ]; then
    dump_folder "$folder"
    used=$((used + size))
  else
    echo "# $folder (titles only — full bodies omitted, over the ${budget}-byte session budget; use vault-search to read a note)"
    folder_titles "$folder"
  fi
done

if [ -d "$vault/Prompts" ]; then
  echo "# Prompts (titles only — read the note when one is needed)"
  folder_titles "Prompts"
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
