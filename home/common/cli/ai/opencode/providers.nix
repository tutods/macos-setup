{
  pkgs,
  lib,
  ...
}: {
  # opencode: ~/.config/opencode/opencode.json  (provider block)
  # Overrides the built-in zai provider's baseURL to the Coding Plan endpoint.
  # API key is stored via /connect → ~/.local/share/opencode/auth.json.
  home.activation.opencodeProviders = lib.hm.dag.entryAfter ["writeBoundary" "opencodeConfig"] ''
    target="$HOME/.config/opencode/opencode.json"
    [ -f "$target" ] || exit 0

    ${pkgs.jq}/bin/jq '.provider.zai = {
      "options": {
        "baseURL": "https://api.z.ai/api/coding/paas/v4"
      }
    }' "$target" > "$target.tmp" && mv "$target.tmp" "$target"
  '';
}
