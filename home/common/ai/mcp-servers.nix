# ── Shared MCP server definitions ─────────────────────────────────────────────
#
# Pure data — no activations. Imported by ./mcp.nix.
#
# Note that enabling a Claude Code plugin also registers any MCP servers in its
# bundled `.mcp.json`, so `claude mcp list` can show servers that are not
# declared here. Those are removed by dropping the plugin, not by editing this
# file — see ./plugins.nix.
#
# ── GitHub Token ──────────────────────────────────────────────────────────────
# github server reads GITHUB_PERSONAL_ACCESS_TOKEN from env.
# The wrapper maps GITHUB_TOKEN → GITHUB_PERSONAL_ACCESS_TOKEN at spawn.
#
# Store in secrets (never commit):
#   echo 'set -gx GITHUB_TOKEN "ghp_xxx"' >> ~/.config/fish/secrets.fish
#
{
  pkgs,
  homeDir,
}: {
  # GitHub's official server, from nixpkgs — a real binary, no npx/Docker.
  # Replaces @modelcontextprotocol/server-github, which upstream archived.
  #
  # Toolsets are pinned rather than left on the default set
  # (context, repos, issues, pull_requests, users, copilot):
  #   + actions          — CI run/job status, which the default set omits
  #   - users, copilot   — unused here, and copilot alone is a large surface
  #
  # ${ } inside the arg string below is shell expansion at server spawn;
  # ${pkgs...} is Nix interpolation at build time.
  github = {
    command = "sh";
    args = [
      "-c"
      ''GITHUB_PERSONAL_ACCESS_TOKEN="''${GITHUB_TOKEN:-}" ${pkgs.github-mcp-server}/bin/github-mcp-server stdio --toolsets context,repos,issues,pull_requests,actions''
    ];
  };

  playwright = {
    command = "npx";
    args = ["-y" "@playwright/mcp" "--isolated" "--headless"];
  };

  # Tree-sitter code graph, so review/impact questions query structure instead
  # of re-reading files. Complements rtk: rtk compresses command output, this
  # avoids reading in the first place.
  #
  # Deliberately NOT installed via `code-review-graph install`. That command
  # auto-detects every agent on the machine and writes config for Cursor,
  # Gemini, Codex, Windsurf, Zed and the rest — and its Claude Code half writes
  # hooks into ~/.claude/settings.json, which this repo overwrites on every
  # deploy. Declaring the server here gives the same MCP tools and touches
  # nothing else. (`install --platform claude-code` would narrow the blast
  # radius but still fights settings.json.)
  #
  # Per-repo setup is still manual and required: `code-review-graph build`
  # inside a project before its graph answers anything.
  code-review-graph = {
    command = "${homeDir}/.local/bin/code-review-graph";
    args = ["serve"];
  };
}
