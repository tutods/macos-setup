# ── AI Post-deploy Initialization ─────────────────────────────────────────────
#
# Runs during every `darwin-rebuild switch` as the HOME user.
# Each block is guarded so it only acts when the tool is missing / not yet set up.
#
# Ordering: writeBoundary ensures home files are written first; mkdir at the
# top of the script creates any config dirs that may still be missing.
#
{
  pkgs,
  lib,
  ...
}: {
  home.activation.aiInit = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Ensure config dirs exist before tool init
    mkdir -p "$HOME/.claude" "$HOME/.config/ai"

    # ── pipx packages ─────────────────────────────────────────────────────
    # Check pipx list before installing to avoid re-installing on every switch.
    # Inject pkgs.pipx into PATH; activation runs before shell PATH is set up.
    echo "↣ pipx packages"
    export PATH="${pkgs.pipx}/bin:$HOME/.local/bin:$PATH"
    if ! pipx list 2>/dev/null | grep -q 'code-review-graph'; then
      pipx install code-review-graph || echo "  ⚠ pipx install code-review-graph failed"
    fi
    if ! pipx list 2>/dev/null | grep -qw 'ttok'; then
      pipx install ttok || echo "  ⚠ pipx install ttok failed"
    fi

    # ── graphify removal (one-time migration) ─────────────────────────────
    # `graphify install` registered a PreToolUse hook in ~/.claude/settings.json
    # and a skill tree at ~/.claude/skills/graphify/. Dropping the package
    # without unwinding that first would orphan both — the hook would fire on
    # every Bash/Read/Glob call and point at a binary that no longer exists.
    # Self-clearing: a no-op once graphify is gone.
    if command -v graphify >/dev/null 2>&1; then
      echo "↣ Removing graphify (hook + skill tree, then the package)"
      graphify uninstall || echo "  ⚠ graphify uninstall failed — check ~/.claude/skills/graphify"
      pipx uninstall graphifyy || echo "  ⚠ pipx uninstall graphifyy failed"
      rm -f "$HOME/.config/ai/.graphify-version"
    fi
  '';
}
