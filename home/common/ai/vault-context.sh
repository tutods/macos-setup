#!/usr/bin/env bash
# SessionStart hook: lists the Obsidian vault so the agent knows what exists.
# Titles only, never bodies. Bodies are fetched on demand by the vault-search
# agent, because injecting them costs ~25k tokens before anything is known about
# the session. The folder loop below is the authoritative list; Templates/,
# vault-root files, and Prompts/ (static reference library, pointer line only)
# are never listed. Truncation is folder-aware: a folder is either fully listed
# or fully dropped and named in the truncation notice.

set -euo pipefail

vault="$HOME/Obsidian"
[ -d "$vault" ] || exit 0

budget="${CLAUDE_VAULT_BUDGET:-12288}"

# Titles (no .md extension) of every note under $1, folder prefix stripped;
# nested subfolders (Lessons/Backend/...) keep their subpath as signal.
folder_titles() {
  find "$vault/$1" -name "*.md" | sed "s|^$vault/$1/||;s|\\.md\$||" | sort
}

listing=""
dropped=""
used=0
for folder in Conventions Lessons Decisions Process Projects Clients Notes; do
  [ -d "$vault/$folder" ] || continue
  titles=$(folder_titles "$folder")
  [ -n "$titles" ] || continue
  block="# $folder
$titles

"
  block_size=$(printf '%s' "$block" | wc -c | tr -d ' ')
  if [ $((used + block_size)) -le "$budget" ]; then
    listing="$listing$block"
    used=$((used + block_size))
  else
    dropped="$dropped $folder"
  fi
done

[ -n "$listing" ] || [ -n "$dropped" ] || exit 0

echo "# Obsidian vault (SessionStart index)"
echo "Note titles only. This is an index, not the content. To read any note, dispatch the vault-search agent."
echo
printf '%s' "$listing"
if [ -n "$dropped" ]; then
  printf '[truncated: dropped%s; raise CLAUDE_VAULT_BUDGET or use vault-search]\n\n' "$(printf '%s' "$dropped" | sed 's/^ //;s/ /, /g;s/^/ /')"
fi

if [ -d "$vault/Prompts" ]; then
  prompt_count=$(find "$vault/Prompts" -name "*.md" | wc -l | tr -d ' ')
  [ "$prompt_count" -gt 0 ] && printf 'Prompts/: %s notes (reference library, not indexed); use vault-search\n\n' "$prompt_count"
fi

input=$(cat 2>/dev/null || true)
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null || true)
[ -z "$cwd" ] && cwd="$PWD"
slug=$(basename "$cwd")
# Dotfiles-style dirs: cwd ".dotfiles" must match "project: dotfiles".
slug="${slug#.}"

matches=$(rg -l "^project: ${slug}\$" "$vault" 2>/dev/null || true)
if [ -n "$matches" ]; then
  echo "# Notes tagged for this project ($slug)"
  printf '%s\n' "$matches" | sed "s|^$vault/||" | sort
fi

exit 0
