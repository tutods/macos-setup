{
  config,
  pkgs,
  lib,
  ...
}: let
  ai = import ../../../../../../lib/ai.nix {inherit pkgs;};
  servers = import ../../mcp-servers.nix {homeDir = config.home.homeDirectory;};

  # Nix-authoritative: full MCP server list. Add servers here, not via UI.
  allServers =
    {
      filesystem = servers.filesystem;
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
