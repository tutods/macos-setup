{
  pkgs,
  lib,
  ...
}: {
  # opencode: ~/.config/opencode/opencode.json  (provider block)
  # z.AI Coding Plan via Anthropic-compatible endpoint.
  # API key stored via /connect → ~/.local/share/opencode/auth.json.
  home.activation.opencodeProviders = lib.hm.dag.entryAfter ["writeBoundary" "opencodeConfig"] ''
    target="$HOME/.config/opencode/opencode.json"
    [ -f "$target" ] || exit 0

    ${pkgs.jq}/bin/jq '. + {
      "provider": {
        "zai-anthropic": {
          "npm": "@ai-sdk/anthropic",
          "options": {
            "baseURL": "https://api.z.ai/api/anthropic",
            "apiKey": "{env:Z_AI_API_KEY}"
          },
          "models": {
            "glm-5":   {"name": "GLM-5"},
            "glm-5.1": {"name": "GLM-5.1"},
            "glm-4.7": {"name": "GLM-4.7"}
          }
        }
      }
    }' "$target" > "$target.tmp" && mv "$target.tmp" "$target"
  '';
}
