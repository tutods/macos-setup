{
  config,
  pkgs,
  lib,
  ...
}: let
  servers = import ../mcp-servers.nix {homeDir = config.home.homeDirectory;};

  mcpServers = {
    filesystem = servers.filesystem;
    github = servers.github;
    playwright = servers.playwright;
  };
in {
  home.activation.claudeMcp = lib.hm.dag.entryAfter ["writeBoundary"] ''
    target="$HOME/.claude/claude_desktop_config.json"
    nix_servers='${builtins.toJSON mcpServers}'

    mkdir -p "$HOME/.claude"

    if [ -f "$target" ]; then
      existing=$(${pkgs.jq}/bin/jq -c '.mcpServers // {}' "$target")
      merged=$(${pkgs.jq}/bin/jq -cn \
        --argjson nix "$nix_servers" \
        --argjson live "$existing" \
        '$nix + $live')
      ${pkgs.jq}/bin/jq --argjson servers "$merged" \
        '. + {mcpServers: $servers}' "$target" \
        > "$target.tmp" && mv "$target.tmp" "$target"
    else
      echo "{\"mcpServers\": $nix_servers}" | ${pkgs.jq}/bin/jq '.' > "$target"
    fi
  '';

  home.activation.claudeMcpExtra = lib.hm.dag.entryAfter ["writeBoundary" "claudeMcp"] ''
    target="$HOME/.claude/claude_desktop_config.json"
    extra='${builtins.toJSON config.home.ai.extraMcpServers}'

    if [ "$extra" != "{}" ] && [ -f "$target" ]; then
      existing=$(${pkgs.jq}/bin/jq -c '.mcpServers // {}' "$target")
      merged=$(${pkgs.jq}/bin/jq -cn \
        --argjson nix "$extra" \
        --argjson live "$existing" \
        '$nix + $live')
      ${pkgs.jq}/bin/jq --argjson servers "$merged" \
        '. + {mcpServers: $servers}' "$target" \
        > "$target.tmp" && mv "$target.tmp" "$target"
    fi
  '';
}
