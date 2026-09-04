#!/usr/bin/env bash
# Deploy doctor: shows what the next deploy will DELETE or RESET in the Claude
# Code state before `darwin-rebuild switch` runs, so nothing is eaten silently.
#
# The destructive places, all previewed below except the last:
#   - customSkillsReconcile deletes any real dir in ~/.claude/skills the
#     flake does not declare (symlinks are left alone).
#   - enabledPlugins is rewritten whole: every plugin not in home.ai.plugins
#     is disabled (dropped from settings.json).
#   - mergeJsonObject drops any settings.json hook event Nix does not
#     declare AND is not in keepHookEvents (lib/ai.nix, settings.nix).
#   - permissions.allow is fully Nix-owned and rewritten whole on every
#     deploy, so any click-granted "don't ask again" rule beyond what's
#     declared is cleared.
#   - opencodeSkillsReconcile deletes any dir under ~/.agents/skills whose
#     .skill-lock.json source is not one of skills.nix's declared sources,
#     when home.ai.opencodeSkillsPrune is true (personal machine only).
#   - NOT previewed: home.activation.opencodePlugins empties
#     ~/.config/opencode/plugin{,s} of everything but the two names it keeps
#     (home/roles/personal/opencode/default.nix). Personal machine only, and
#     the only one of these outside ~/.claude.
#
# Usage: ./scripts/deploy-doctor.sh [macbook|work]   (default: this machine's
# config inferred from the hostname)
#
# Exit 0 on a clean preview. Exits 1 only when it cannot run at all (bad
# config, failed flake eval), never as a deploy gate. Deps: nix, jq.
set -uo pipefail

cd "$(dirname "$0")/.." || exit 1

# jq parses every list below; without it the skill section would report every
# dir as "will delete" and the settings sections would print a bogus all-clear.
command -v jq >/dev/null 2>&1 || {
  echo "deploy-doctor: jq not found — aborting" >&2
  exit 1
}

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

# Quoted attr: usernames can contain dots (daniel.a.sousa), which would
# otherwise parse as nested attribute path segments.
HM=".#darwinConfigurations.$CONFIG.config.home-manager.users.\"$USER_NAME\""
NIX=(nix --extra-experimental-features "nix-command flakes" eval --json)

# On work, the deploy is run as admin.daniel.a.sousa (Homebrew owner) but
# Home Manager configures daniel.a.sousa — $HOME alone would silently check
# the wrong account's (nonexistent) ~/.claude, exactly the split-account case
# this script exists to get right. Mirrors nix.sh's get_target_user pattern.
TARGET_HOME="/Users/$USER_NAME"
[ "$USER_NAME" = "${USER:-}" ] && TARGET_HOME="$HOME"

echo ""
echo -e "  ${BOLD}${CYAN}▸${NC} ${BOLD}Deploy doctor${NC} ${DIM}config=$CONFIG user=$USER_NAME home=$TARGET_HOME${NC}"
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

SKILLS_DIR="$TARGET_HOME/.claude/skills"
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

SETTINGS="$TARGET_HOME/.claude/settings.json"
if [ -f "$SETTINGS" ]; then
  # A corrupt settings.json would print green "nothing drops out" for every
  # section below — a false all-clear from the tool meant to catch deletions.
  jq empty "$SETTINGS" 2>/dev/null || {
    echo "deploy-doctor: $SETTINGS is not valid JSON — aborting instead of showing a bogus all-clear" >&2
    exit 1
  }
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

# ── 5. opencode skills the reconcile will prune (personal machine only) ─────
# This duplicates the module's own .skill-lock.json + jq lookup instead of
# sharing code with it.
if [ "$CONFIG" = "macbook" ]; then
  if ! prune_flag=$("${NIX[@]}" "$HM.home.ai.opencodeSkillsPrune" 2>/dev/null) || [ -z "$prune_flag" ]; then
    echo "deploy-doctor: could not eval $HM.home.ai.opencodeSkillsPrune — aborting instead of showing a bogus prune preview" >&2
    exit 1
  fi
  if ! sources_json=$("${NIX[@]}" "$HM.home.ai.opencodeSkillsSources" 2>/dev/null) || [ -z "$sources_json" ]; then
    echo "deploy-doctor: could not eval $HM.home.ai.opencodeSkillsSources — aborting instead of showing a bogus prune preview" >&2
    exit 1
  fi

  OC_SKILLS_DIR="$TARGET_HOME/.agents/skills"
  OC_LOCK_FILE="$TARGET_HOME/.agents/.skill-lock.json"
  if [ ! -d "$OC_SKILLS_DIR" ]; then
    print_ok "$OC_SKILLS_DIR does not exist yet"
  else
    declare -a owned_skills=()
    lock_state="ok"
    if [ ! -f "$OC_LOCK_FILE" ]; then
      lock_state="missing"
    elif ! jq empty "$OC_LOCK_FILE" 2>/dev/null; then
      lock_state="invalid"
    else
      while IFS= read -r k; do owned_skills+=("$k"); done < <(jq -r --argjson srcs "$sources_json" \
        '.skills // {} | to_entries[] | select(.value.source as $s | $srcs | index($s)) | .key' \
        "$OC_LOCK_FILE" 2>/dev/null)
    fi

    declare -a unowned_skills=()
    for path in "$OC_SKILLS_DIR"/*; do
      [ -d "$path" ] || continue
      name=$(basename "$path")
      keep=0
      for s in "${owned_skills[@]-}"; do [ "$name" = "$s" ] && { keep=1; break; }; done
      [ "$keep" -eq 0 ] && unowned_skills+=("$name")
    done

    if [ "${#unowned_skills[@]}" -eq 0 ]; then
      print_ok "no unmanaged opencode skill dirs"
    elif [ "${#owned_skills[@]}" -eq 0 ]; then
      case "$lock_state" in
        missing) reason="$OC_LOCK_FILE not found" ;;
        invalid) reason="$OC_LOCK_FILE is not valid JSON" ;;
        *) reason="no entry in $OC_LOCK_FILE resolves to a declared source" ;;
      esac
      print_warn "$reason ${DIM}(module refuses to prune, nothing will be deleted)${NC}"
    elif [ "$prune_flag" = "true" ]; then
      for name in "${unowned_skills[@]-}"; do
        print_del "opencode skill dir $name  ${DIM}(not from a declared source)${NC}"
      done
      echo -e "  ${DIM}${#unowned_skills[@]} dir(s) will be deleted on next deploy${NC}"
    else
      for name in "${unowned_skills[@]-}"; do
        print_warn "opencode skill dir $name  ${DIM}(not from a declared source, only listed — opencodeSkillsPrune is false)${NC}"
      done
      echo -e "  ${DIM}${#unowned_skills[@]} dir(s) would be pruned if opencodeSkillsPrune were true${NC}"
    fi
  fi
fi

# ── 6. opencode provider auth (personal machine only) ────────────────────────
# ~/.local/share/opencode/auth.json is written interactively by `opencode`
# /connect and is deliberately never in Nix. The deployed opencode.json points
# at Ollama Cloud models; with no ollama-cloud entry every model call fails
# with nothing tying it back to "you never ran /connect".
if [ "$CONFIG" = "macbook" ]; then
  OPENCODE_AUTH="$TARGET_HOME/.local/share/opencode/auth.json"
  if [ -f "$OPENCODE_AUTH" ] && jq -e '.["ollama-cloud"]' "$OPENCODE_AUTH" >/dev/null 2>&1; then
    print_ok "opencode ollama-cloud auth is set up"
  else
    print_warn "opencode auth not set up — run ${BOLD}opencode${NC} then ${BOLD}/connect${NC} and pick the Ollama Cloud provider"
  fi
fi

echo ""
echo -e "  ${DIM}Preview only — nothing was changed. Re-run after editing the flake if${NC}"
echo -e "  ${DIM}anything above is unexpected; a deleted skill/plugin needs to be declared${NC}"
echo -e "  ${DIM}in the flake (home.ai.customSkills / home.ai.plugins) to survive.${NC}"
echo ""
exit 0
