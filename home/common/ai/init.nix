# Post-deploy init, run as the HOME user on every `darwin-rebuild switch`.
# Every block is guarded so it only acts when the tool isn't set up yet.
{
  pkgs,
  lib,
  ...
}: {
  home.activation.aiInit = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Ensure config dirs exist before tool init
    mkdir -p "$HOME/.claude"

    # ── pipx packages ─────────────────────────────────────────────────────
    # Check pipx list before installing to avoid re-installing on every switch.
    # Inject pkgs.pipx into PATH; activation runs before shell PATH is set up.
    echo "↣ pipx packages"
    export PATH="${pkgs.pipx}/bin:$HOME/.local/bin:$PATH"
    if ! pipx list 2>/dev/null | grep -q 'code-review-graph'; then
      pipx install code-review-graph || echo "  ⚠ pipx install code-review-graph failed"
    fi
  '';
}
