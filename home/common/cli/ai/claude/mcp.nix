{
  config,
  pkgs,
  lib,
  ...
}: let
  servers = import ../mcp-servers.nix {homeDir = config.home.homeDirectory;};

  # Nix-authoritative: full MCP server list. Add servers here, not via UI.
  allServers =
    {
      filesystem = servers.filesystem;
      github = servers.github;
      playwright = servers.playwright;
    }
    // config.home.ai.extraMcpServers;
in {
  home.activation.claudeMcp = lib.hm.dag.entryAfter ["writeBoundary"] ''
    target="$HOME/.claude/claude_desktop_config.json"
    nix_servers='${builtins.toJSON allServers}'

    mkdir -p "$HOME/.claude"

    if [ -f "$target" ]; then
      ${pkgs.jq}/bin/jq --argjson servers "$nix_servers" \
        '. + {mcpServers: $servers}' "$target" \
        > "$target.tmp" && mv "$target.tmp" "$target"
    else
      echo "{\"mcpServers\": $nix_servers}" | ${pkgs.jq}/bin/jq '.' > "$target"
    fi
  '';
}
