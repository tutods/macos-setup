{
  pkgs,
  lib,
  ...
}: {
  # opencode: ~/.config/opencode/opencode.json  (provider block)
  # z.AI Coding Plan uses @ai-sdk/anthropic with a custom baseURL.
  # Written only when Z_AI_API_KEY exists in env or secrets.fish.
  home.activation.opencodeProviders = lib.hm.dag.entryAfter ["writeBoundary" "opencodeConfig"] ''
    target="$HOME/.config/opencode/opencode.json"
    [ -f "$target" ] || exit 0

    has_key() {
      local var="$1"
      [ -n "$(printenv "$var" 2>/dev/null)" ] && return 0
      if command -v fish > /dev/null 2>&1; then
        local val
        val=$(fish -c "
          if test -f ~/.config/fish/secrets.fish
            source ~/.config/fish/secrets.fish
          end
          echo \$$var
        " 2>/dev/null || true)
        [ -n "$val" ] && return 0
      fi
      return 1
    }

    if has_key "Z_AI_API_KEY"; then
      ${pkgs.jq}/bin/jq '. + {
        "provider": {
          "zai-anthropic": {
            "npm": "@ai-sdk/anthropic",
            "options": {
              "baseURL": "https://api.z.ai/api/anthropic/v1",
              "apiKey": "{env:Z_AI_API_KEY}"
            }
          }
        }
      }' "$target" > "$target.tmp" && mv "$target.tmp" "$target"
    fi
  '';
}
