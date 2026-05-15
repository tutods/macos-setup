{
  config,
  pkgs,
  lib,
  ...
}: let
  servers = import ../mcp-servers.nix {homeDir = config.home.homeDirectory;};

  mcpServers = {
    filesystem =
      servers.filesystem
      // {
        type = "local";
        enabled = true;
      };
    github =
      servers.github
      // {
        type = "local";
        enabled = true;
      };
    playwright =
      servers.playwright
      // {
        type = "local";
        enabled = true;
      };
  };
in {
  # opencode: ~/.config/opencode/opencode.json  (mcp key — base servers)
  home.activation.opencodeMcp = lib.hm.dag.entryAfter ["writeBoundary" "opencodeConfig"] ''
    target="$HOME/.config/opencode/opencode.json"
    nix_servers='${builtins.toJSON mcpServers}'

    if [ -f "$target" ]; then
      existing_mcp=$(${pkgs.jq}/bin/jq -c '.mcp // {}' "$target")
      merged=$(${pkgs.jq}/bin/jq -cn \
        --argjson nix "$nix_servers" \
        --argjson live "$existing_mcp" \
        '$nix + $live')
      ${pkgs.jq}/bin/jq --argjson mcp "$merged" \
        '. + {mcp: $mcp}' "$target" \
        > "$target.tmp" && mv "$target.tmp" "$target"
    else
      echo "{\"mcp\": $nix_servers}" | ${pkgs.jq}/bin/jq '.' > "$target"
    fi
  '';

  # opencode: ~/.config/opencode/opencode.json  (mcp key — role-specific extras)
  home.activation.opencodeMcpExtra = lib.hm.dag.entryAfter ["writeBoundary" "opencodeMcp"] ''
    target="$HOME/.config/opencode/opencode.json"
    extra_servers='${builtins.toJSON (
      lib.mapAttrs (_: v:
        v
        // {
          type = "local";
          enabled = true;
        })
      config.home.ai.extraMcpServers
    )}'

    if [ "$extra_servers" != "{}" ] && [ -f "$target" ]; then
      existing=$(${pkgs.jq}/bin/jq -c '.mcp // {}' "$target")
      merged=$(${pkgs.jq}/bin/jq -cn \
        --argjson extra "$extra_servers" \
        --argjson live "$existing" \
        '$extra + $live')
      ${pkgs.jq}/bin/jq --argjson mcp "$merged" \
        '. + {mcp: $mcp}' "$target" \
        > "$target.tmp" && mv "$target.tmp" "$target"
    fi
  '';
}
