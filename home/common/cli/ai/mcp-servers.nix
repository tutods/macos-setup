# ── Shared MCP server definitions ─────────────────────────────────────────────
#
# Pure data — no activations. Imported by claude/default.nix and opencode/mcp.nix.
#
# ── GitHub Token ──────────────────────────────────────────────────────────────
# github server reads GITHUB_PERSONAL_ACCESS_TOKEN from env.
# The wrapper maps GITHUB_TOKEN → GITHUB_PERSONAL_ACCESS_TOKEN at spawn.
#
# Store in secrets (never commit):
#   echo 'set -gx GITHUB_TOKEN "ghp_xxx"' >> ~/.config/fish/secrets.fish
#
{homeDir}: {
  filesystem = {
    command = "npx";
    args = ["-y" "@modelcontextprotocol/server-filesystem" "${homeDir}/.dotfiles" "${homeDir}/Developer"];
  };

  # ${ } below is shell expansion at server spawn, not Nix build time.
  github = {
    command = "sh";
    args = ["-c" "GITHUB_PERSONAL_ACCESS_TOKEN=\"\${GITHUB_TOKEN:-}\" npx -y @modelcontextprotocol/server-github"];
  };

  playwright = {
    command = "npx";
    args = ["-y" "@playwright/mcp" "--isolated" "--headless"];
  };
}
