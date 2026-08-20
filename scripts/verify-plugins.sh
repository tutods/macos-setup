#!/usr/bin/env bash
# Verify every declared Claude Code plugin actually exists in its marketplace.
#
# Plugins fail silently: a typo'd name is written to settings.json, Claude Code
# finds nothing to install, and no skill ever appears. This turns that into a
# non-zero exit. Also reports the skill count each plugin drags in, since a
# plugin is coarser than a skill and the count is easy to miss.
#
# Deps: git, jq. Reads the repo, clones nothing permanent, writes to a temp dir.
#
#   ./scripts/verify-plugins.sh            # verify + per-plugin skill counts
#   ./scripts/verify-plugins.sh --quiet    # verify only (CI)
set -euo pipefail

cd "$(dirname "$0")/.."

QUIET=0
[ "${1:-}" = "--quiet" ] && QUIET=1

command -v jq >/dev/null || { echo "verify-plugins: jq not found" >&2; exit 2; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# Role files are scanned too, they declare no plugins today, but may again.
SOURCES=(
  home/common/ai/plugins.nix
  home/roles/personal/ai/default.nix
  home/roles/work/ai/default.nix
)

# Collect `<key> = "<owner>/<repo>";` inside home.ai.marketplaces blocks, and
# "<plugin>@<key>" inside home.ai.plugins blocks. Comment lines are skipped.
: > "$TMP/marketplaces"
: > "$TMP/plugins"
for f in "${SOURCES[@]}"; do
  [ -f "$f" ] || continue
  awk '
    /home\.ai\.marketplaces = \{/ { inm=1; next }
    /home\.ai\.plugins = \[/      { inp=1; next }
    inm && /^  \};/               { inm=0; next }
    inp && /^  \];/               { inp=0; next }
    { sub(/#.*/, "") }
    inm && match($0, /[A-Za-z0-9_-]+ = "[^"]+"/) {
      s = substr($0, RSTART, RLENGTH); gsub(/[ "]/, "", s); sub(/=/, " ", s)
      print s >> "'"$TMP"'/marketplaces"
    }
    inp && match($0, /"[^"]+@[^"]+"/) {
      s = substr($0, RSTART+1, RLENGTH-2)
      print s >> "'"$TMP"'/plugins"
    }
  ' "$f"
done

sort -u -o "$TMP/marketplaces" "$TMP/marketplaces"
sort -u -o "$TMP/plugins" "$TMP/plugins"

fail=0
total_skills=0

mkt_repo() { awk -v k="$1" '$1==k {print $2}' "$TMP/marketplaces"; }

fetch() { # $1 = owner/repo -> prints clone dir, or empty on failure
  local repo="$1" dir="$TMP/$(echo "$repo" | tr '/' '_')"
  if [ ! -d "$dir" ]; then
    git clone -q --filter=blob:none --no-checkout --depth 1 \
      "https://github.com/$repo" "$dir" 2>/dev/null || return 1
  fi
  printf '%s' "$dir"
}

while read -r entry; do
  [ -n "$entry" ] || continue
  plugin="${entry%@*}"
  mkt="${entry##*@}"

  # Built into Claude Code; there is no marketplace repo to check against.
  if [ "$mkt" = "claude-plugins-official" ]; then
    [ "$QUIET" -eq 1 ] || printf '  %-52s %s\n' "$entry" "(official, not checkable)"
    continue
  fi

  repo=$(mkt_repo "$mkt")
  if [ -z "$repo" ]; then
    echo "FAIL  $entry -> marketplace '$mkt' is not declared in home.ai.marketplaces" >&2
    fail=$((fail + 1)); continue
  fi

  dir=$(fetch "$repo") || {
    echo "FAIL  $entry -> could not fetch $repo" >&2
    fail=$((fail + 1)); continue
  }

  mj="$dir/mj.json"
  if [ ! -f "$mj" ]; then
    git -C "$dir" show HEAD:.claude-plugin/marketplace.json > "$mj" 2>/dev/null || {
      echo "FAIL  $entry -> $repo has no .claude-plugin/marketplace.json" >&2
      fail=$((fail + 1)); continue
    }
  fi

  if ! jq -e --arg p "$plugin" '.plugins[] | select(.name == $p)' "$mj" >/dev/null; then
    echo "FAIL  $entry -> '$plugin' is not a plugin in $repo" >&2
    fail=$((fail + 1)); continue
  fi

  # Skill count: explicit `skills` list, else SKILL.md files under the plugin's
  # source dir, ignoring the per-agent mirror trees some repos ship.
  # `source` may be "./", ".", "./plugins/x", or an object (remote plugin).
  src=$(jq -r --arg p "$plugin" \
    '.plugins[] | select(.name == $p) | (.source // "./") | if type == "string" then . else "./" end' "$mj" \
    | sed 's|^\./||; s|^\.$||; s|/$||')
  n=$(jq -r --arg p "$plugin" '.plugins[] | select(.name == $p) | (.skills // []) | length' "$mj")
  if [ "$n" -eq 0 ]; then
    pref=""; [ -n "$src" ] && pref="$src/"
    # awk, not a grep chain: grep exits 1 on zero matches, which under
    # `set -o pipefail` would abort the whole script on a legitimately
    # skill-less plugin.
    n=$(git -C "$dir" ls-tree -r --name-only HEAD | awk -v pref="$pref" '
      index($0, pref) != 1 { next }
      $0 !~ /(^|\/)SKILL\.md$/ { next }
      /(^|\/)\.(gemini|cursor|opencode|grok|kiro|pi|qoder|rovodev|trae|trae-cn|vibe|codex|agents|hermes|github|codebuddy)\// { next }
      /(^|\/)cli\/assets\// { next }
      { c++ } END { print c + 0 }')
  fi
  total_skills=$((total_skills + n))
  [ "$QUIET" -eq 1 ] || printf '  %-52s %3s skills\n' "$entry" "$n"
done < "$TMP/plugins"

# A marketplace nobody references is dead config.
while read -r key _repo; do
  [ -n "$key" ] || continue
  if ! grep -q "@$key\$" "$TMP/plugins"; then
    echo "FAIL  marketplace '$key' is declared but no plugin uses it" >&2
    fail=$((fail + 1))
  fi
done < "$TMP/marketplaces"

n_plugins=$(wc -l < "$TMP/plugins" | tr -d ' ')
n_markets=$(wc -l < "$TMP/marketplaces" | tr -d ' ')

if [ "$fail" -gt 0 ]; then
  echo "verify-plugins: $fail problem(s) across $n_plugins plugins" >&2
  exit 1
fi

echo "verify-plugins: $n_plugins plugins, $n_markets marketplaces, ~$total_skills skills, all resolve"
