{
  pkgs,
  lib,
  ...
}: let
  base = {
    "\$schema" = "https://opencode.ai/config.json";
    plugin = ["@warp-dot-dev/opencode-warp"];
    experimental.openTelemetry = false;
    share = "disabled";
    autoupdate = "manual";
    snapshot = false;
    logLevel = "WARN";
    disabled_providers = ["openai" "azure" "vertex" "bedrock"];
    permission.bash = {
      "git *" = "allow";
      "*" = "ask";
    };
  };
in {
  # opencode: ~/.config/opencode/opencode.json  (base config)
  # Nix wins for static fields; mcp/provider/env preserved by later activations.
  home.activation.opencodeConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    target="$HOME/.config/opencode/opencode.json"
    base='${builtins.toJSON base}'

    mkdir -p "$HOME/.config/opencode"

    if [ -f "$target" ]; then
      existing_mcp=$(${pkgs.jq}/bin/jq -c '.mcp // {}' "$target")
      existing_provider=$(${pkgs.jq}/bin/jq -c '.provider // {}' "$target")
      existing_env=$(${pkgs.jq}/bin/jq -c '.env // {}' "$target")
      echo "$base" \
        | ${pkgs.jq}/bin/jq \
            --argjson mcp      "$existing_mcp" \
            --argjson provider "$existing_provider" \
            --argjson env      "$existing_env" \
            '. + {mcp: $mcp, provider: $provider, env: $env}' \
        > "$target.tmp" && mv "$target.tmp" "$target"
    else
      echo "$base" | ${pkgs.jq}/bin/jq '.' > "$target"
    fi
  '';
}
