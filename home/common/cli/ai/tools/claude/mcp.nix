{
  config,
  pkgs,
  lib,
  ...
}: let
  ai = import ../../../../../../lib/ai.nix {inherit pkgs;};
  servers = import ../../mcp-servers.nix {inherit pkgs;};

  # Nix-authoritative: full MCP server list. Add servers here, not via UI.
  #
  # `filesystem` was dropped — it was scoped to ~/.dotfiles and ~/Developer,
  # exactly where Claude Code's native Read/Glob/Grep already reach, so it only
  # added duplicate tool schemas to every session.
  allServers =
    {
      github = servers.github;
      playwright = servers.playwright;
    }
    // config.home.ai.extraMcpServers;
in {
  home.activation.claudeMcp = lib.hm.dag.entryAfter ["writeBoundary" "aiInit"] (
    ai.mergeJsonKey {
      file = "$HOME/.claude/claude_desktop_config.json";
      key = "mcpServers";
      value = allServers;
    }
  );
}
