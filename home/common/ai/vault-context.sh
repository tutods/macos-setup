#!/usr/bin/env bash
# SessionStart hook: lists the Obsidian vault so the agent knows what exists.
# Titles only, never bodies. Bodies are fetched on demand by the vault-search
# agent, because injecting them costs ~25k tokens before anything is known about
# the session. The folder loop below is the authoritative list; Templates/ and
# vault-root files are never listed.

set -euo pipefail

vault="$HOME/Obsidian"
[ -d "$vault" ] || exit 0

budget="${CLAUDE_VAULT_BUDGET:-4096}"

# Vault-relative titles (no .md extension) of every note under $1.
folder_titles() {
  find "$vault/$1" -name "*.md" | sed "s|^$vault/||;s|\\.md\$||" | sort
}

listing=""
for folder in Conventions Lessons Decisions Process Projects Clients Notes Prompts; do
  [ -d "$vault/$folder" ] || continue
  titles=$(folder_titles "$folder")
  [ -n "$titles" ] || continue
  listing="$listing# $folder
$titles

"
done

[ -n "$listing" ] || exit 0

echo "# Obsidian vault (SessionStart index)"
echo "Note titles only. This is an index, not the content. To read any note, dispatch the vault-search agent."
echo

size=$(printf '%s' "$listing" | wc -c | tr -d ' ')
if [ "$size" -le "$budget" ]; then
  printf '%s' "$listing"
else
  printf '%s' "$listing" | head -c "$budget"
  printf '\n[index truncated at %s bytes of %s; raise CLAUDE_VAULT_BUDGET or use vault-search]\n\n' "$budget" "$size"
fi

input=$(cat 2>/dev/null || true)
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null || true)
[ -z "$cwd" ] && cwd="$PWD"
slug=$(basename "$cwd")

matches=$(rg -l "^project: ${slug}\$" "$vault" 2>/dev/null || true)
if [ -n "$matches" ]; then
  echo "# Notes tagged for this project ($slug)"
  printf '%s\n' "$matches" | sed "s|^$vault/||" | sort
fi

exit 0
