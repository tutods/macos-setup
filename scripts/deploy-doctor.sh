#!/usr/bin/env bash
# Deploy doctor: shows what the next deploy will DELETE or RESET in the Claude
# Code state before `darwin-rebuild switch` runs, so nothing is eaten silently.
#
# The destructive places, all previewed below except the last:
#   - customSkillsReconcile deletes any undeclared entry in ~/.claude/skills,
#     directory or symlink.
#   - enabledPlugins is rewritten whole: every plugin not in home.ai.plugins
#     is disabled (dropped from settings.json).
#   - mergeJsonObject drops any settings.json hook event Nix does not
#     declare AND is not in keepHookEvents (lib/ai.nix, settings.nix).
#   - permissions.allow is fully Nix-owned and rewritten whole on every
#     deploy, so any click-granted "don't ask again" rule beyond what's
#     declared is cleared.
#   - homebrew.onActivation (cleanup = "uninstall" + --force-cleanup) runs
#     `brew bundle --cleanup --force-cleanup`, force-uninstalling every brew
#     formula/cask/tap not in the generated Brewfile, no prompt
#     (modules/darwin/homebrew/default.nix). Previewed via a `brew bundle
#     cleanup` dry run against the pending config's Brewfile — but only when
#     the target config is this machine's: brew's live state is per-machine.
#   - NOT previewed: home.activation.opencodePlugins empties
#     ~/.config/opencode/plugin{,s} of everything but the two names it keeps
#     (home/roles/personal/opencode/default.nix). Personal machine only, and
#     the only one of these outside ~/.claude.
#
# Usage: ./scripts/deploy-doctor.sh [macbook|work]   (default: this machine's
# config inferred from the hostname)
#
# Exit codes (nix.sh gates the apply on these):
#   0  clean preview — nothing destructive predicted
#   2  destructive changes predicted (deletions/drops listed above exit)
#   3  cannot certify — bad config, failed flake eval, missing jq, corrupt
#      settings.json; the caller must abort rather than apply blind
# Deps: nix, jq. brew is optional: without it (fresh machine) the brew
# cleanup preview is skipped with a note, everything else still runs.
set -uo pipefail

cd "$(dirname "$0")/.." || exit 3

# jq parses every list below; without it the skill section would report every
# dir as "will delete" and the settings sections would print a bogus all-clear.
command -v jq >/dev/null 2>&1 || {
  echo "deploy-doctor: jq not found — aborting" >&2
  exit 3
}

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'
print_warn() { echo -e "  ${YELLOW}⚠${NC}  $1"; }
print_ok()   { echo -e "  ${GREEN}✔${NC}  $1"; }
# Every predicted deletion goes through print_del, which also feeds the final
# exit code (0 clean / 2 destructive). The print_del loops below run in the
# current shell (`< <(...)`, not pipes), so the counter survives them.
DESTRUCTIVE=0
print_del()  { echo -e "  ${RED}✖ will delete${NC} $1"; DESTRUCTIVE=$((DESTRUCTIVE+1)); }

# ── Config and user for this machine ──────────────────────────────────────────
# LOCAL_CONFIG is the config this machine's hostname maps to. It is the
# default target, and it gates the brew cleanup preview below: brew's live
# state only exists here, so previewing it for the *other* host would lie.
case "$(scutil --get ComputerName 2>/dev/null || hostname)" in
  *MacBook*|*macbook*) LOCAL_CONFIG="macbook" ;;
  *) LOCAL_CONFIG="work" ;;
esac
CONFIG="${1:-$LOCAL_CONFIG}"

if ! USER_NAME=$(nix --extra-experimental-features "nix-command flakes" eval --raw \
      --file ./hosts.nix --apply "h: h.\"$CONFIG\".user" 2>/dev/null) || [ -z "$USER_NAME" ]; then
  echo "deploy-doctor: unknown config '$CONFIG' or hosts.nix eval failed (expected macbook|work)" >&2
  exit 3
fi

# Quoted attr: usernames can contain dots (daniel.a.sousa), which would
# otherwise parse as nested attribute path segments. The eval selects the
# darwin config root (not the HM user) because the brew preview needs the
# darwin-level homebrew.brewfile too; HM names the user subtree in messages.
DARWIN=".#darwinConfigurations.$CONFIG.config"
HM="$DARWIN.home-manager.users.\"$USER_NAME\""
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

# ── Flake eval, once for everything ──────────────────────────────────────────
# One full-flake eval selects every attr this script needs; the per-attr evals
# it replaces each re-evaluated nixpkgs + nix-darwin + the whole HM tree. The
# opencode attrs exist only on macbook, so they fall back to null via `or`.
# An empty/failed result would report every skill dir as "will delete", so a
# failed eval must abort rather than proceed with an empty allowlist.
if ! doctor_json=$("${NIX[@]}" "$DARWIN" --apply "
  cfg: let hm = cfg.home-manager.users.\"$USER_NAME\"; in {
    customSkills = hm.home.ai.customSkills;
    externallyManagedSkills = hm.home.ai.externallyManagedSkills;
    plugins = hm.home.ai.plugins;
    brewfile = cfg.homebrew.brewfile or null;
    brewOwner = cfg.homebrew.user or null;
  }" 2>/dev/null) || [ -z "$doctor_json" ]; then
  echo "deploy-doctor: could not eval $HM (customSkills/plugins/opencode attrs) — aborting instead of showing a bogus delete list" >&2
  exit 3
fi
skills_json=$(printf '%s' "$doctor_json" | jq -c '.customSkills')
extskills_json=$(printf '%s' "$doctor_json" | jq -c '.externallyManagedSkills')
plugins_json=$(printf '%s' "$doctor_json" | jq -c '.plugins')
brewfile=$(printf '%s' "$doctor_json" | jq -r '.brewfile // empty')
brew_owner=$(printf '%s' "$doctor_json" | jq -r '.brewOwner // empty')

# ── 1. Skills the reconcile will delete ──────────────────────────────────────
declare -a declared_skills
while IFS= read -r s; do declared_skills+=("$s"); done < <(printf '%s' "$skills_json" | jq -r '.[]')
while IFS= read -r s; do declared_skills+=("$s"); done < <(printf '%s' "$extskills_json" | jq -r '.[]')

SKILLS_DIR="$TARGET_HOME/.claude/skills"
deleted=0
for path in "$SKILLS_DIR"/*; do
  [ -L "$path" ] || [ -d "$path" ] || continue
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
declare -a declared_plugins
while IFS= read -r p; do declared_plugins+=("$p"); done < <(printf '%s' "$plugins_json" | jq -r '.[]')

SETTINGS="$TARGET_HOME/.claude/settings.json"
if [ -f "$SETTINGS" ]; then
  # A corrupt settings.json would print green "nothing drops out" for every
  # section below — a false all-clear from the tool meant to catch deletions.
  jq empty "$SETTINGS" 2>/dev/null || {
    echo "deploy-doctor: $SETTINGS is not valid JSON — aborting instead of showing a bogus all-clear" >&2
    exit 3
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

# ── 6. brew formulae/casks/taps the cleanup will uninstall ───────────────────
# The deploy runs `brew bundle --cleanup --force-cleanup` against the Brewfile
# nix-darwin generates, uninstalling everything unlisted without prompting.
# Preview: write the pending config's Brewfile (config.homebrew.brewfile, the
# exact text the deploy will use) to a temp file and run `brew bundle cleanup`
# WITHOUT --force — a dry run that lists what would be uninstalled and removes
# nothing (exit 0 when clean, exit 1 + "Would uninstall/untap" lines when not).
if [ "$CONFIG" != "$LOCAL_CONFIG" ]; then
  print_warn "brew cleanup preview skipped ${DIM}(config $CONFIG is not this machine; brew's live state is per-machine — run the doctor there)${NC}"
elif ! command -v brew >/dev/null 2>&1; then
  print_warn "brew cleanup preview skipped ${DIM}(brew not installed yet)${NC}"
elif [ -z "$brewfile" ]; then
  echo "deploy-doctor: $DARWIN.homebrew.brewfile is empty/missing — aborting instead of previewing brew cleanup against a bogus Brewfile" >&2
  exit 3
else
  pending_brewfile=$(mktemp "${TMPDIR:-/tmp}/deploy-doctor-brewfile.XXXXXX") || {
    echo "deploy-doctor: mktemp failed — cannot preview brew cleanup" >&2
    exit 3
  }
  trap 'rm -f "$pending_brewfile"' EXIT
  printf '%s\n' "$brewfile" >"$pending_brewfile"
  # brew resolves its trust file from $HOME, so the dry run must run as brew_owner
  # (-H) whenever that differs from the invoking user, mirroring nix.sh's as_user.
  brew_as_user=()
  [ -n "$brew_owner" ] && [ "$brew_owner" != "${USER:-}" ] && brew_as_user=(sudo -u "$brew_owner" -H)
  cleanup_out=$("${brew_as_user[@]+"${brew_as_user[@]}"}" env HOMEBREW_NO_AUTO_UPDATE=1 brew bundle cleanup --file="$pending_brewfile" 2>&1)
  cleanup_rc=$?
  if [ "$cleanup_rc" -eq 0 ]; then
    print_ok "brew: everything installed is in the pending Brewfile, cleanup uninstalls nothing"
  elif printf '%s\n' "$cleanup_out" | grep -q '^Would '; then
    while IFS=$'\t' read -r kind name; do
      [ -z "$name" ] && continue
      print_del "brew $kind $name  ${DIM}(not in the pending Brewfile — cleanup uninstalls it, no prompt)${NC}"
    done < <(printf '%s\n' "$cleanup_out" | awk '
      /^Would uninstall formulae:/     { kind = "formula"; next }
      /^Would uninstall casks:/        { kind = "cask";    next }
      /^Would untap:/                  { kind = "tap";     next }
      /^Would /                        { kind = "item";    next }
      /^Run `brew bundle cleanup/      { kind = "";        next }
      kind != "" && NF > 0             { print kind "\t" $1 }')
  else
    # Neither a clean pass nor a would-remove list: brew itself failed
    # (broken tap, bad Brewfile line, ...). Certifying anything would be a lie.
    echo "deploy-doctor: brew bundle cleanup dry run failed (exit $cleanup_rc) — cannot certify brew cleanup:" >&2
    printf '%s\n' "$cleanup_out" | sed 's/^/    /' >&2
    exit 3
  fi
fi

# ── 7. opencode provider auth (personal machine only) ────────────────────────
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
echo -e "  ${DIM}in the flake (home.ai.customSkills / home.ai.plugins) to survive,${NC}"
echo -e "  ${DIM}externally-managed skill dirs belong in home.ai.externallyManagedSkills, and a${NC}"
echo -e "  ${DIM}brew formula/cask must be in homebrew.brews/casks (or the host's homebrew/).${NC}"
echo ""

# Exit protocol (see header): 2 tells the caller a deploy would destroy the
# items listed above; 0 certifies a clean preview.
[ "$DESTRUCTIVE" -gt 0 ] && exit 2
exit 0
