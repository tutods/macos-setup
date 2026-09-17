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

# git commit exports GIT_DIR/GIT_WORK_TREE etc. into this hook's environment,
# which redirects every `git -C <cloned marketplace>` below at the dotfiles repo
# instead of the clone (all marketplace checks fail with "no
# .claude-plugin/marketplace.json"). The clones are freshly made in $TMP, so
# dropping the inherited context is always safe here.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY \
      GIT_ALTERNATE_OBJECT_DIRECTORIES

QUIET=0
[ "${1:-}" = "--quiet" ] && QUIET=1

command -v jq >/dev/null || { echo "verify-plugins: jq not found" >&2; exit 2; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# Role files are scanned too, but only the one matching this machine when run
# locally: the work role's private ai-workbench marketplace (which is also why
# the local-install fallback in the fetch failure path below exists) only has
# an access path from the work laptop, so scanning it from the personal
# machine can never succeed. CI has no host identity of its own, so it keeps
# checking every role for full typo coverage.
SOURCES=(home/common/ai/plugins.nix)
if [ -n "${CI:-}" ]; then
  SOURCES+=(home/roles/personal/ai/default.nix home/roles/work/ai/default.nix)
else
  case "$(scutil --get ComputerName 2>/dev/null || hostname)" in
    *MacBook*|*macbook*) SOURCES+=(home/roles/personal/ai/default.nix) ;;
    *) SOURCES+=(home/roles/work/ai/default.nix) ;;
  esac
fi

# Collect `<key> = "<owner>/<repo>";` inside home.ai.marketplaces blocks, and
# "<plugin>@<key>" inside home.ai.plugins blocks. Comment lines are skipped.
# A quoted entry in a plugins block with no `@` goes to plugins_bad and fails
# the run, that is exactly the silent typo this script exists to catch.
: > "$TMP/marketplaces"
: > "$TMP/plugins"
: > "$TMP/plugins_bad"
for f in "${SOURCES[@]}"; do
  [ -f "$f" ] || continue
  awk '
    /home\.ai\.marketplaces = \{/ { inm=1; next }
    /home\.ai\.plugins = \[/      { inp=1; next }
    inm && /^[[:space:]]*\};/     { inm=0; next }
    inp && /^[[:space:]]*\];/     { inp=0; next }
    { sub(/#.*/, "") }
    inm && match($0, /[A-Za-z0-9_-]+ = "[^"]+"/) {
      s = substr($0, RSTART, RLENGTH); gsub(/[ "]/, "", s); sub(/=/, " ", s)
      print s >> "'"$TMP"'/marketplaces"
    }
    inp && match($0, /"[^"]+"/) {
      s = substr($0, RSTART+1, RLENGTH-2)
      if (s ~ /@/) print s >> "'"$TMP"'/plugins"
      else print s >> "'"$TMP"'/plugins_bad"
    }
  ' "$f"
done

sort -u -o "$TMP/marketplaces" "$TMP/marketplaces"
sort -u -o "$TMP/plugins" "$TMP/plugins"

fail=0
total_skills=0
official=0

while read -r bad; do
  [ -n "$bad" ] || continue
  echo "FAIL  plugin entry \"$bad\" has no \"@marketplace\" suffix" >&2
  fail=$((fail + 1))
done < "$TMP/plugins_bad"

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
    official=$((official + 1))
    [ "$QUIET" -eq 1 ] || printf '  %-52s %s\n' "$entry" "(official, not checkable)"
    continue
  fi

  spec=$(mkt_repo "$mkt")
  if [ -z "$spec" ]; then
    echo "FAIL  $entry -> marketplace '$mkt' is not declared in home.ai.marketplaces" >&2
    fail=$((fail + 1)); continue
  fi

  # "<owner>/<repo>[@<sha>]": verify against the pinned commit when present,
  # since that is the revision Claude Code will actually install from.
  repo="${spec%%@*}"
  sha=""
  [ "$spec" != "$repo" ] && sha="${spec##*@}"

  dir=$(fetch "$repo") || {
    # Private marketplaces (e.g. an employer's org repo) refuse the anonymous
    # clone this script uses. If Claude Code already installed the marketplace
    # locally, verify the plugin name against that copy instead of failing:
    # it is the same marketplace.json the deploy will resolve from.
    # The repo may live in a different account than the one Claude Code runs
    # in (admin vs user on the work machine), so look for the install in every
    # local home, current one first.
    local_mkt=""
    for cand in "$HOME/.claude/plugins/marketplaces/$mkt/.claude-plugin/marketplace.json" \
      /Users/*/.claude/plugins/marketplaces/"$mkt"/.claude-plugin/marketplace.json; do
      [ -r "$cand" ] && local_mkt="$cand" && break
    done
    if [ -n "$local_mkt" ]; then
      if jq -e --arg p "$plugin" '.plugins[] | select(.name == $p)' "$local_mkt" >/dev/null; then
        echo "  $entry  (private marketplace, verified against local install)"
      else
        echo "FAIL  $entry -> '$plugin' is not a plugin in the local install of $mkt" >&2
        fail=$((fail + 1))
      fi
      continue
    fi
    echo "FAIL  $entry -> could not fetch $repo (private? no local install at ~/.claude/plugins/marketplaces/$mkt to fall back on)" >&2
    fail=$((fail + 1)); continue
  }

  ref="HEAD"
  if [ -n "$sha" ]; then
    if ! git -C "$dir" cat-file -e "$sha^{commit}" 2>/dev/null; then
      # A failed fetch is not proof the pin is bad: a transient network error
      # must not send anyone off to re-pin a valid commit. Only an explicit
      # "not found" from the remote (or a fetch that succeeds yet still leaves
      # the sha missing locally) means the sha really does not exist.
      if fetch_err=$(git -C "$dir" fetch -q --depth 1 origin "$sha" 2>&1); then
        : # fetched; the cat-file below is the verdict
      elif ! grep -qiE 'not our ref|unadvertised object|couldn.t find remote ref|bad object' <<< "$fetch_err"; then
        echo "FAIL  $entry -> fetching pinned sha $sha from $repo failed (network/transient error, retry): $(head -n 1 <<< "$fetch_err")" >&2
        fail=$((fail + 1)); continue
      fi
      if ! git -C "$dir" cat-file -e "$sha^{commit}" 2>/dev/null; then
        echo "FAIL  $entry -> pinned sha $sha does not exist in $repo" >&2
        fail=$((fail + 1)); continue
      fi
    fi
    ref="$sha"
  fi

  mj="$dir/mj-$ref.json"
  if [ ! -f "$mj" ]; then
    git -C "$dir" show "$ref:.claude-plugin/marketplace.json" > "$mj" 2>/dev/null || {
      # The redirection created an empty $mj; remove it or every later plugin
      # from this marketplace gets a misleading "not a plugin" failure.
      rm -f "$mj"
      echo "FAIL  $entry -> $repo has no .claude-plugin/marketplace.json at $ref" >&2
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
    n=$(git -C "$dir" ls-tree -r --name-only "$ref" | awk -v pref="$pref" '
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

if [ "$official" -gt 0 ]; then
  echo "verify-plugins: $n_plugins plugins ($official official, not checked against a marketplace), $n_markets marketplaces, ~$total_skills skills; every checkable entry resolves"
else
  echo "verify-plugins: $n_plugins plugins, $n_markets marketplaces, ~$total_skills skills, all resolve"
fi
