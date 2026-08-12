# ── Shared MCP server definitions ─────────────────────────────────────────────
#
# Pure data — no activations. Imported by tools/claude/mcp.nix.
#
# Note that enabling a Claude Code plugin also registers any MCP servers in its
# bundled `.mcp.json`, so `claude mcp list` can show servers that are not
# declared here. Those are removed by dropping the plugin, not by editing this
# file — see tools/claude/plugins.nix.
#
# ── GitHub Token ──────────────────────────────────────────────────────────────
# github server reads GITHUB_PERSONAL_ACCESS_TOKEN from env.
# The wrapper maps GITHUB_TOKEN → GITHUB_PERSONAL_ACCESS_TOKEN at spawn.
#
# Store in secrets (never commit):
#   echo 'set -gx GITHUB_TOKEN "ghp_xxx"' >> ~/.config/fish/secrets.fish
#
{pkgs}: {
  # GitHub's official server, from nixpkgs — a real binary, no npx/Docker.
  # Replaces @modelcontextprotocol/server-github, which upstream archived.
  #
  # ${ } inside the arg string below is shell expansion at server spawn;
  # ${pkgs...} is Nix interpolation at build time.
  github = {
    command = "sh";
    args = [
      "-c"
      "GITHUB_PERSONAL_ACCESS_TOKEN=\"\${GITHUB_TOKEN:-}\" ${pkgs.github-mcp-server}/bin/github-mcp-server stdio"
    ];
  };

  playwright = {
    command = "npx";
    args = ["-y" "@playwright/mcp" "--isolated" "--headless"];
  };
}
