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
    # Version-pinned: PyPI is the one fetch here the flake lock doesn't cover,
    # so an unpinned install would run whatever was published last. Bump the
    # pin deliberately (`pipx upgrade` never runs on its own).
    echo "↣ pipx packages"
    # doCheck = false: same override (and rationale) as modules/packages/development.nix
    export PATH="${pkgs.pipx.overridePythonAttrs (_: {doCheck = false;})}/bin:$HOME/.local/bin:$PATH"
    if ! pipx list 2>/dev/null | grep -q 'code-review-graph 2.3.8'; then
      pipx install --force code-review-graph==2.3.8 \
        || echo "  ⚠ pipx install code-review-graph failed; the code-review-graph MCP server (mcp.nix) will be broken until it succeeds"
    fi
  '';
}
