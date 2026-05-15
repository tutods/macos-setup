{
  pkgs,
  lib,
  ...
}: {
  # opencode: ~/.config/opencode/opencode.json  (provider + env blocks)
  # Only writes providers whose API key exists in env or secrets.fish.
  # Models are auto-discovered from each provider's GET /v1/models endpoint.
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

    provider="{}"

    if has_key "Z_AI_API_KEY"; then
      provider=$(echo "$provider" | ${pkgs.jq}/bin/jq '. + {
        "z-ai": {
          "npm": "@ai-sdk/openai-compatible",
          "name": "z.AI (GLM)",
          "options": {"baseURL": "https://api.z.ai/api/paas/v4", "apiKey": "{env:Z_AI_API_KEY}"}
        }
      }')
    fi

    if has_key "OLLAMA_CLOUD_API_KEY"; then
      provider=$(echo "$provider" | ${pkgs.jq}/bin/jq '. + {
        "ollama-cloud": {
          "npm": "@ai-sdk/openai-compatible",
          "name": "Ollama Cloud",
          "options": {"baseURL": "https://ollama.com/v1", "apiKey": "{env:OLLAMA_CLOUD_API_KEY}"}
        }
      }')
    fi

    if has_key "NVIDIA_API_KEY"; then
      provider=$(echo "$provider" | ${pkgs.jq}/bin/jq '. + {
        "nvidia": {
          "npm": "@ai-sdk/openai-compatible",
          "name": "NVIDIA NIM",
          "options": {"baseURL": "https://integrate.api.nvidia.com/v1", "apiKey": "{env:NVIDIA_API_KEY}"}
        }
      }')
    fi

    # OpenCode Go: built-in provider, reads OPENCODE_API_KEY from env at runtime.
    env_block="{}"
    if has_key "OPENCODE_API_KEY"; then
      env_block='{"OPENCODE_API_KEY": "{env:OPENCODE_API_KEY}"}'
    fi

    ${pkgs.jq}/bin/jq \
      --argjson p "$provider" \
      --argjson e "$env_block" \
      'if $p != {} then . + {provider: $p} else . end |
       if $e != {} then . + {env: $e}      else . end' \
      "$target" > "$target.tmp" && mv "$target.tmp" "$target"
  '';
}
