#!/usr/bin/env bash
# Catch dangling references in the AI tree before they ship.
#
# Every one of these has already shipped at least once: an agent preloading a
# skill that does not exist, a `names` list naming a directory that was deleted,
# a skill directory nobody registered, a doc pointing at a removed module. None
# of them error at deploy time; the reference is silently ignored.
#
#   ./scripts/verify-references.sh            # report
#   ./scripts/verify-references.sh --quiet    # exit code only (CI, pre-commit)
set -euo pipefail

cd "$(dirname "$0")/.."

QUIET=0
[ "${1:-}" = "--quiet" ] && QUIET=1
fail=0

say() { [ "$QUIET" -eq 1 ] || printf '%s\n' "$*"; }
bad() { printf '  ✗ %s\n' "$*" >&2; fail=1; }

# Names registered in a `names = [ ... ]` list, for one default.nix.
registered() {
  awk '/names = \[/,/\];/' "$1" 2>/dev/null | grep -oE '"[a-z0-9-]+"' | tr -d '"' | sort -u
}

# ── skills: registered names must exist as dirs, and vice versa ───────────────
say "↣ Skills"
for pair in \
  "home/common/ai/skills/default.nix:home/common/ai/skills/local" \
  "home/roles/personal/ai/default.nix:home/roles/personal/ai/skills/local" \
  "home/roles/work/ai/default.nix:home/roles/work/ai/skills/local"; do
  nix=${pair%%:*}; dir=${pair##*:}
  [ -f "$nix" ] || continue
  reg=$(registered "$nix")
  for n in $reg; do
    [ -d "$dir/$n" ] || bad "$nix registers skill '$n' but $dir/$n does not exist"
    [ -f "$dir/$n/SKILL.md" ] || bad "$dir/$n has no SKILL.md"
  done
  if [ -d "$dir" ]; then
    for d in "$dir"/*/; do
      [ -d "$d" ] || continue
      n=$(basename "$d")
      printf '%s\n' "$reg" | grep -qx "$n" || bad "$dir/$n exists but is not in $nix's names list"
    done
  fi
done

# ── agents and workflows: same contract, different extension ─────────────────
for kind in agents:md workflows:js; do
  name=${kind%%:*}; ext=${kind##*:}
  say "↣ ${name^}"
  for base in home/common/ai home/roles/personal/ai home/roles/work/ai; do
    nix="$base/$name/default.nix"; dir="$base/$name/local"
    [ -f "$nix" ] || continue
    reg=$(registered "$nix")
    for n in $reg; do
      [ -f "$dir/$n.$ext" ] || bad "$nix registers $name '$n' but $dir/$n.$ext is missing"
    done
    if [ -d "$dir" ]; then
      for f in "$dir"/*."$ext"; do
        [ -f "$f" ] || continue
        n=$(basename "$f" ".$ext")
        printf '%s\n' "$reg" | grep -qx "$n" || bad "$f exists but is not in $nix's names list"
      done
    fi
  done
done

# ── agent frontmatter `skills:` must name a real skill ───────────────────────
# Only in-repo skills are checkable; a plugin-provided name is skipped, since
# resolving it needs the marketplace (that is verify-plugins.sh's job).
say "↣ Agent skill preloads"
known=$(find home -type d -path '*/skills/local/*' -maxdepth 6 -mindepth 1 \
          -exec test -f '{}/SKILL.md' \; -print | xargs -n1 basename | sort -u)
while read -r f; do
  [ -n "$f" ] || continue
  while read -r s; do
    [ -n "$s" ] || continue
    printf '%s\n' "$known" | grep -qx "$s" \
      || say "  ? $(basename "$f") preloads '$s' (not in-repo; must come from a plugin)"
  done < <(awk '/^skills:/{flag=1;next}/^[a-z_-]+:/{flag=0}flag&&/^ *- /{print $2}' "$f" || true)
done < <(find home -path '*/agents/local/*.md' || true)

# ── nix module imports must point at files that exist ────────────────────────
say "↣ Module imports"
while read -r f; do
  d=$(dirname "$f")
  while read -r ref; do
    [ -n "$ref" ] || continue
    t="$d/${ref#./}"
    [ -e "$t" ] || [ -e "$t.nix" ] || bad "$f imports $ref which does not exist"
  done < <(grep -oE '^[[:space:]]+\./[A-Za-z0-9_./-]+' "$f" 2>/dev/null | tr -d ' ' || true)
done < <(find home lib modules hosts -name '*.nix')

# ── repo-relative paths named in docs ────────────────────────────────────────
# Only docs, README and CLAUDE.md. Skill and agent files are excluded on
# purpose: their `scripts/...` paths are relative to their own directory, and
# they name paths inside *target* repos (a project's own docs/CONVENTIONS.md).
say "↣ Referenced repo paths"
while read -r p; do
  [ -n "$p" ] || continue
  case "$p" in *'<'*|*'*'*) continue;; esac
  [ -e "$p" ] || bad "a doc references $p which does not exist"
done < <(rg -oN --no-heading -g '*.md' -g '!**/skills/local/**' -g '!**/agents/local/**' \
   -e '`(home/[a-zA-Z0-9_./-]+|lib/[a-zA-Z0-9_./-]+\.nix|scripts/[a-zA-Z0-9_./-]+|docs/[a-zA-Z0-9_./-]+\.md)`' . 2>/dev/null \
  | grep -oE '`[a-z]+/[A-Za-z0-9_./-]+`' | tr -d '`' | sort -u || true)

if [ "$fail" -eq 0 ]; then
  say ""
  say "verify-references: no dangling references"
else
  printf '\nverify-references: dangling references found\n' >&2
fi
exit "$fail"
