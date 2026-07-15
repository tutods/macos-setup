{
  pkgs,
  lib,
  ...
}: let
  base = {
    "\$schema" = "https://opencode.ai/config.json";
    experimental.openTelemetry = false;
    share = "disabled";
    autoupdate = false;
    snapshot = false;
    logLevel = "WARN";
    disabled_providers = ["azure" "vertex" "bedrock"];
  };
in {
  # opencode: ~/.config/opencode/opencode.json  (base config)
  # Nix wins for static fields; mcp/provider preserved by later activations.
  home.activation.opencodeConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    target="$HOME/.config/opencode/opencode.json"
    base='${builtins.toJSON base}'

    mkdir -p "$HOME/.config/opencode"

    if [ -f "$target" ]; then
      existing_mcp=$(${pkgs.jq}/bin/jq -c '.mcp // {}' "$target")
      existing_provider=$(${pkgs.jq}/bin/jq -c '.provider // {}' "$target")
      echo "$base" \
        | ${pkgs.jq}/bin/jq \
            --argjson mcp      "$existing_mcp" \
            --argjson provider "$existing_provider" \
            'del(.env) + {mcp: $mcp, provider: $provider}' \
        > "$target.tmp" && mv "$target.tmp" "$target"
    else
      echo "$base" | ${pkgs.jq}/bin/jq '.' > "$target"
    fi
  '';
}
