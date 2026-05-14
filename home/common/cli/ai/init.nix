# ── AI Post-deploy Initialization ─────────────────────────────────────────────
#
# Runs during every `darwin-rebuild switch` as the HOME user.
# Each block is guarded so it only acts when the tool is missing / not yet set up.
#
# Ordering: writeBoundary ensures home files are written first; mkdir at the
# top of the script creates any config dirs that may still be missing.
#
{lib, ...}: {
  home.activation.aiInit = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Ensure config dirs exist before tool init
    mkdir -p "$HOME/.claude" "$HOME/.config/opencode" "$HOME/.codex"

    # ── rtk proxy ─────────────────────────────────────────────────────────
    # rtk init is idempotent — safe to re-run on every switch
    if command -v rtk > /dev/null 2>&1; then
      rtk init -g            2>/dev/null || true
      rtk init -g --opencode 2>/dev/null || true
      rtk init -g --codex    2>/dev/null || true
    fi

    # ── pipx packages ─────────────────────────────────────────────────────
    # Check pipx list before installing to avoid re-installing on every switch
    if command -v pipx > /dev/null 2>&1; then
      pipx list 2>/dev/null | grep -q 'code-review-graph' \
        || pipx install code-review-graph 2>/dev/null || true
      pipx list 2>/dev/null | grep -qw 'ttok' \
        || pipx install ttok 2>/dev/null || true
    fi

    # ── AI skills ─────────────────────────────────────────────────────────
    # fish function reads manifest.txt and runs `npx skills add` for each entry
    if command -v fish > /dev/null 2>&1; then
      fish -c "ai-skills-sync" 2>/dev/null || true
    fi
  '';
}
