#!/usr/bin/env bash
# Prunes Claude Code state Nix cannot reach: plugins no scope enables, their marketplaces and caches,
# registry entries for deleted worktrees, code-review-graph leftovers. Dry run by default, --apply executes.
set -euo pipefail

apply=0
[ "${1:-}" = "--apply" ] && apply=1
dev_dir="${PROJECT_DIR:-$HOME/Developer}"
claude_dir="$HOME/.claude"
registry="$claude_dir/plugins/installed_plugins.json"
known="$claude_dir/plugins/known_marketplaces.json"
cache="$claude_dir/plugins/cache"
sentinel="${TMPDIR:-/tmp}/claude-compacted"

run() {
  if [ "$apply" -eq 1 ]; then "$@"; else printf 'would: %s\n' "$*"; fi
}

in_list() {
  local needle="$1"
  shift
  local item
  for item in "$@"; do [ "$item" = "$needle" ] && return 0; done
  return 1
}

for bin in jq claude; do
  command -v "$bin" >/dev/null || { echo "claude-cleanup: $bin not on PATH" >&2; exit 1; }
done
[ -f "$registry" ] || { echo "claude-cleanup: no plugin registry at $registry, nothing to do"; exit 0; }

settings_files=("$claude_dir/settings.json")
while IFS= read -r f; do
  [ -n "$f" ] && settings_files+=("$f")
done < <(
  {
    find "$dev_dir" -maxdepth 5 \( -name node_modules -o -name .git \) -prune -o \
      -type f \( -name settings.json -o -name settings.local.json \) -path '*/.claude/*' -print 2>/dev/null
    find "$HOME/orca/workspaces" -maxdepth 4 -type f \( -name settings.json -o -name settings.local.json \) -path '*/.claude/*' -print 2>/dev/null
    jq -r '.plugins // . | .[] | .[] | .projectPath // empty' "$registry" | sort -u | while IFS= read -r d; do
      for n in settings.json settings.local.json; do [ -f "$d/.claude/$n" ] && printf '%s\n' "$d/.claude/$n"; done
    done
  } | sort -u
)

keep_plugins=()
while IFS= read -r p; do
  [ -n "$p" ] && keep_plugins+=("$p")
done < <(jq -rs '[.[] | .enabledPlugins // {} | to_entries[] | select(.value == true) | .key] | unique | .[]' "${settings_files[@]}")

keep_markets=(claude-plugins-official)
for p in "${keep_plugins[@]}"; do
  m="${p##*@}"
  in_list "$m" "${keep_markets[@]}" || keep_markets+=("$m")
done
while IFS= read -r m; do
  [ -n "$m" ] && ! in_list "$m" "${keep_markets[@]}" && keep_markets+=("$m")
done < <(jq -rs '[.[] | .extraKnownMarketplaces // {} | keys[]] | unique | .[]' "${settings_files[@]}")

printf 'keep plugins:      %s\n' "${keep_plugins[*]}"
printf 'keep marketplaces: %s\n' "${keep_markets[*]}"
echo

echo "== plugins installed but enabled nowhere"
while IFS= read -r p; do
  [ -z "$p" ] && continue
  in_list "$p" "${keep_plugins[@]}" || run claude plugin uninstall "$p"
done < <(jq -r '.plugins // . | keys[]' "$registry")

echo "== marketplaces no kept plugin or settings file references"
if [ -f "$known" ]; then
  while IFS= read -r m; do
    [ -z "$m" ] && continue
    in_list "$m" "${keep_markets[@]}" || run claude plugin marketplace remove "$m"
  done < <(jq -r 'keys[]' "$known")
fi

echo "== code-review-graph leftovers and the compaction sentinel"
if jq -e '.mcpServers["code-review-graph"]' "$HOME/.claude.json" >/dev/null 2>&1; then
  run claude mcp remove code-review-graph -s user
fi
if command -v pipx >/dev/null && pipx list --short 2>/dev/null | grep -q '^code-review-graph '; then
  run pipx uninstall code-review-graph
fi
if [ -d "$sentinel" ]; then
  run rm -rf "$sentinel"
fi

echo "== registry entries whose project path no longer exists"
dead=$(jq -r '.plugins // . | to_entries[] | .value[] | select(.projectPath != null) | .projectPath' "$registry" \
  | sort -u | while IFS= read -r p; do [ -d "$p" ] || printf '%s\n' "$p"; done \
  | jq -Rs 'split("\n") | map(select(length > 0))')
dead_count=$(printf '%s' "$dead" | jq length)
if [ "$dead_count" -gt 0 ]; then
  printf '%s\n' "$dead" | jq -r '.[] | "  " + .'
  if [ "$apply" -eq 1 ]; then
    mkdir -p "$claude_dir/backups"
    cp "$registry" "$claude_dir/backups/installed_plugins.$(date +%Y%m%d%H%M%S).json"
    if jq -e 'has("plugins")' "$registry" >/dev/null; then
      filter='.plugins |= (with_entries(.value |= map(select(.projectPath == null or (($dead | index(.projectPath)) == null)))) | with_entries(select(.value | length > 0)))'
    else
      filter='with_entries(.value |= map(select(.projectPath == null or (($dead | index(.projectPath)) == null)))) | with_entries(select(.value | length > 0))'
    fi
    tmp=$(mktemp)
    jq --argjson dead "$dead" "$filter" "$registry" > "$tmp"
    install -m 0644 "$tmp" "$registry"
    rm -f "$tmp"
    echo "  pruned $dead_count entries (backup in $claude_dir/backups)"
  else
    echo "  would prune $dead_count entries"
  fi
else
  echo "  none"
fi

echo "== plugin cache dirs nothing references"
if [ -d "$cache" ]; then
  before=$(du -sh "$cache" | cut -f1)
  keep_paths=$(jq -r '[.plugins // . | .. | objects | .installPath? // empty] | unique | .[]' "$registry")
  for m in "$cache"/*/; do
    [ -d "$m" ] || continue
    m="${m%/}"
    in_list "$(basename "$m")" "${keep_markets[@]}" || run rm -rf "$m"
  done
  for d in "$cache"/*/*/*/; do
    [ -d "$d" ] || continue
    d="${d%/}"
    printf '%s\n' "$keep_paths" | grep -Fxq -- "$d" || run rm -rf "$d"
  done
  if [ "$apply" -eq 1 ]; then
    for d in "$cache"/*/*/; do [ -d "$d" ] && rmdir "$d" 2>/dev/null || true; done
    echo "  cache: $before -> $(du -sh "$cache" | cut -f1)"
  else
    echo "  cache now: $before"
  fi
fi

echo
if [ "$apply" -eq 1 ]; then
  echo "claude-cleanup: done"
else
  echo "claude-cleanup: dry run, pass --apply to execute"
fi
