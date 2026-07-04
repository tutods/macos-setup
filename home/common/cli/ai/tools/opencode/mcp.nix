{
  config,
  pkgs,
  lib,
  ...
}: let
  ai = import ../../../../../../lib/ai.nix {inherit pkgs;};
  servers = import ../../mcp-servers.nix {homeDir = config.home.homeDirectory;};

  # opencode wants `type = "local"; enabled = true;` on every server entry.
  withOcAttrs = v:
    v
    // {
      type = "local";
      enabled = true;
    };

  # Nix-authoritative: full MCP server list. Add servers here, not via UI.
  allServers =
    {
      filesystem = withOcAttrs servers.filesystem;
      github = withOcAttrs servers.github;
      playwright = withOcAttrs servers.playwright;
    }
    // lib.mapAttrs (_: withOcAttrs) config.home.ai.extraMcpServers;
in {
  home.activation.opencodeMcp = lib.hm.dag.entryAfter ["writeBoundary" "opencodeConfig" "aiInit"] (
    ai.mergeJsonKey {
      file = "$HOME/.config/opencode/opencode.json";
      key = "mcp";
      value = allServers;
    }
  );
}
