#!/usr/bin/env bash
# Deploy doctor: shows what the next deploy will DELETE or RESET in the Claude
# Code state before `darwin-rebuild switch` runs, so nothing is eaten silently.
#
# A deploy is destructive in four places:
#   1. customSkillsReconcile deletes any real dir in ~/.claude/skills the
#      flake does not declare (symlinks are left alone).
#   2. enabledPlugins is rewritten whole: every plugin not in home.ai.plugins
#      is disabled (dropped from settings.json).
#   3. mergeJsonObject drops any settings.json hook event Nix does not
#      declare AND is not in keepHookEvents (lib/ai.nix, settings.nix).
#   4. permissions.allow is declared empty, so click-granted "don't ask again"
#      rules are cleared.
#
# Usage: ./scripts/deploy-doctor.sh [macbook|work]   (default: this machine's
# config inferred from the hostname)
#
# Exit 0 on a clean preview. Exits 1 only when it cannot run at all (bad
# config, failed flake eval), never as a deploy gate. Deps: nix, jq.
set -uo pipefail

cd "$(dirname "$0")/.." || exit 1

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'
print_warn() { echo -e "  ${YELLOW}⚠${NC}  $1"; }
print_ok()   { echo -e "  ${GREEN}✔${NC}  $1"; }
print_del()  { echo -e "  ${RED}✖ will delete${NC} $1"; }

# ── Config and user for this machine ──────────────────────────────────────────
CONFIG="${1:-}"
if [ -z "$CONFIG" ]; then
  case "$(scutil --get ComputerName 2>/dev/null || hostname)" in
    *MacBook*|*macbook*) CONFIG="macbook" ;;
    *) CONFIG="work" ;;
  esac
fi

if ! USER_NAME=$(nix --extra-experimental-features "nix-command flakes" eval --raw \
      --file ./hosts.nix --apply "h: h.\"$CONFIG\".user" 2>/dev/null) || [ -z "$USER_NAME" ]; then
  echo "deploy-doctor: unknown config '$CONFIG' or hosts.nix eval failed (expected macbook|work)" >&2
  exit 1
fi

HM=".#darwinConfigurations.$CONFIG.config.home-manager.users.$USER_NAME"
NIX=(nix --extra-experimental-features "nix-command flakes" eval --json)

echo ""
echo -e "  ${BOLD}${CYAN}▸${NC} ${BOLD}Deploy doctor${NC} ${DIM}config=$CONFIG user=$USER_NAME${NC}"
echo ""

# ── 1. Skills the reconcile will delete ──────────────────────────────────────
# An empty result here would report every skill dir as "will delete", so a
# failed eval must abort rather than proceed with an empty allowlist.
if ! skills_json=$("${NIX[@]}" "$HM.home.ai.customSkills" 2>/dev/null) || [ -z "$skills_json" ]; then
  echo "deploy-doctor: could not eval $HM.home.ai.customSkills — aborting instead of showing a bogus delete list" >&2
  exit 1
fi
declare -a declared_skills
while IFS= read -r s; do declared_skills+=("$s"); done < <(printf '%s' "$skills_json" | jq -r '.[]')

SKILLS_DIR="$HOME/.claude/skills"
deleted=0
for path in "$SKILLS_DIR"/*; do
  [ -d "$path" ] || continue
  [ -L "$path" ] && continue    # symlinks point at non-Nix tooling, kept
  name=$(basename "$path")
  keep=0
  for s in "${declared_skills[@]-}"; do [ "$name" = "$s" ] && { keep=1; break; }; done
  if [ "$keep" -eq 0 ]; then
    print_del "skill dir $name  ${DIM}(not declared in the flake)${NC}"
    deleted=$((deleted+1))
  fi
done
[ "$deleted" -eq 0 ] && print_ok "no unmanaged skill dirs"
[ ! -d "$SKILLS_DIR" ] && print_ok "$SKILLS_DIR does not exist yet"

# ── 2. Plugins a deploy will disable ─────────────────────────────────────────
# Same failure mode as skills: an empty list marks every plugin for drop.
if ! plugins_json=$("${NIX[@]}" "$HM.home.ai.plugins" 2>/dev/null) || [ -z "$plugins_json" ]; then
  echo "deploy-doctor: could not eval $HM.home.ai.plugins — aborting instead of showing a bogus drop list" >&2
  exit 1
fi
declare -a declared_plugins
while IFS= read -r p; do declared_plugins+=("$p"); done < <(printf '%s' "$plugins_json" | jq -r '.[]')

SETTINGS="$HOME/.claude/settings.json"
if [ -f "$SETTINGS" ]; then
  dropped=0
  while IFS= read -r name; do
    [ -z "$name" ] && continue
    print_del "plugin $name  ${DIM}(drops out of enabledPlugins)${NC}"
    dropped=$((dropped+1))
  done < <(jq -r --argjson keep "$(printf '%s\n' "${declared_plugins[@]-}" | jq -Rsc 'split("\n") | map(select(length>0))')" \
    '.enabledPlugins // {} | keys[] | select(. as $k | $keep | index($k) | not)' "$SETTINGS" 2>/dev/null)
  [ "$dropped" -eq 0 ] && print_ok "no plugins drop out"

  # ── 3. Hook events the merge will drop ────────────────────────────────────
  # Sanctioned = events the Nix settings declare (grep: settings.nix is Nix,
  # not JSON) + the keepHookEvents literal from settings.nix.
  sanctioned=$( { grep -o 'hooks\.[A-Za-z]\+' home/common/ai/settings.nix 2>/dev/null | cut -d. -f2
                  grep -o '"[A-Za-z]*"' home/common/ai/settings.nix 2>/dev/null | grep -E '"(Stop|StopFailure|SubagentStart|SubagentStop|TeammateIdle|PostToolUseFailure|PermissionRequest|PostCompact)"' | tr -d '"'; } \
                | sort -u | jq -Rsc 'split("\n") | map(select(length>0))' )
  hooks_dropped=0
  while IFS= read -r ev; do
    [ -z "$ev" ] && continue
    print_del "hook event $ev  ${DIM}(not Nix-declared, not in keepHookEvents)${NC}"
    hooks_dropped=$((hooks_dropped+1))
  done < <(jq -r --argjson keep "$sanctioned" \
    '.hooks // {} | keys[] | select(. as $k | $keep | index($k) | not)' "$SETTINGS" 2>/dev/null)
  [ "$hooks_dropped" -eq 0 ] && print_ok "no unsanctioned hook events"

  # ── 4. permissions.allow entries a deploy clears ───────────────────────────
  declared_allows=$(sed -n '/permissions\.allow = \[/,/\];/p' home/common/ai/settings.nix | grep -o '"[^"]*"' | tr -d '"' | jq -Rsc 'split("\n") | map(select(length>0))')
  allow_dropped=0
  while IFS= read -r allow; do
    [ -z "$allow" ] && continue
    print_del "permission allow $allow  ${DIM}(not declared in settings.nix)${NC}"
    allow_dropped=$((allow_dropped+1))
  done < <(jq -r --argjson keep "$declared_allows" \
    '.permissions.allow // [] | .[] | select(. as $a | $keep | index($a) | not)' "$SETTINGS" 2>/dev/null)
  [ "$allow_dropped" -eq 0 ] && print_ok "no unmanaged permission allows"
else
  print_ok "no live settings.json yet"
fi

echo ""
echo -e "  ${DIM}Preview only — nothing was changed. Re-run after editing the flake if${NC}"
echo -e "  ${DIM}anything above is unexpected; a deleted skill/plugin needs to be declared${NC}"
echo -e "  ${DIM}in the flake (home.ai.customSkills / home.ai.plugins) to survive.${NC}"
echo ""
exit 0
