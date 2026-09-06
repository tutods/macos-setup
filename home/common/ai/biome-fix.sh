#!/usr/bin/env bash
# PostToolUse (Edit|Write): biome-fix just the edited file.
#
# Only a PATH-installed biome is ever executed. The old inline hook fell back
# to ./node_modules/.bin/biome, which hands a cloned repo arbitrary code
# execution on the first edit (a committed binary needs no npm install), and
# ran with no path argument, reformatting files the session never touched.
set -uo pipefail

input=$(cat)
file=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null) || exit 0
[ -n "$file" ] && [ -f "$file" ] || exit 0

case "$file" in
  *.js | *.jsx | *.ts | *.tsx | *.json | *.jsonc | *.css) ;;
  *) exit 0 ;;
esac

# Same cwd-root gate as before: only projects that opted into biome.
[ -f biome.json ] || [ -f biome.jsonc ] || exit 0
command -v biome >/dev/null 2>&1 || exit 0

biome check --write "$file" 2>&1
exit 0
