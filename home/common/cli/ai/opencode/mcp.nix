{
  config,
  pkgs,
  lib,
  ...
}: let
  servers = import ../mcp-servers.nix {homeDir = config.home.homeDirectory;};

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
  home.activation.opencodeMcp = lib.hm.dag.entryAfter ["writeBoundary" "opencodeConfig"] ''
    target="$HOME/.config/opencode/opencode.json"
    nix_servers='${builtins.toJSON allServers}'

    if [ -f "$target" ]; then
      ${pkgs.jq}/bin/jq --argjson mcp "$nix_servers" \
        '. + {mcp: $mcp}' "$target" \
        > "$target.tmp" && mv "$target.tmp" "$target"
    else
      echo "{\"mcp\": $nix_servers}" | ${pkgs.jq}/bin/jq '.' > "$target"
    fi
  '';
}
