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
    mkdir -p "$HOME/.claude" "$HOME/.config/opencode" "$HOME/.codex"

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
    if ! pipx list 2>/dev/null | grep -q 'graphifyy'; then
      pipx install graphifyy || echo "  ⚠ pipx install graphifyy failed"
    fi
    # ── graphify init ─────────────────────────────────────────────────
    # Guard by version — only re-registers hooks when graphify updates
    graphify_stamp="$HOME/.config/ai/.graphify-version"
    graphify_ver=$(graphify --version 2>/dev/null || echo "")
    if [ -n "$graphify_ver" ] && { [ ! -f "$graphify_stamp" ] || [ "$(cat "$graphify_stamp")" != "$graphify_ver" ]; }; then
      echo "↣ graphify install (all agents) — $graphify_ver"
      graphify install                       || echo "  ⚠ graphify install (claude) failed"
      graphify install --platform opencode   || echo "  ⚠ graphify install (opencode) failed"
      graphify install --platform codex      || echo "  ⚠ graphify install (codex) failed"
      printf "%s" "$graphify_ver" > "$graphify_stamp"
    else
      echo "↣ graphify up to date ($graphify_ver)"
    fi
  '';
}
