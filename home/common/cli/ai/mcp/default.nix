# ── MCP Servers ───────────────────────────────────────────────────────────────
#
# Manages MCP server config for Claude Code CLI and opencode.
#
# On re-deploy: Nix merges new servers into existing config.
# Servers added manually (claude mcp add / opencode UI) are preserved.
#
# ── GitHub Token ──────────────────────────────────────────────────────────────
# The GitHub MCP server reads GITHUB_PERSONAL_ACCESS_TOKEN from env.
# The wrapper below maps GITHUB_TOKEN → GITHUB_PERSONAL_ACCESS_TOKEN at spawn.
#
# 1. Create token: https://github.com/settings/tokens/new
#    Scopes: repo, read:org, read:user
#    Preferred: fine-grained token scoped to your orgs
#
# 2. Store in secrets (never commit):
#    echo 'set -gx GITHUB_TOKEN "ghp_xxx"' >> ~/.config/fish/secrets.fish
#    # or via doppler (personal machine):
#    doppler secrets set GITHUB_TOKEN ghp_xxx
#
{
  config,
  pkgs,
  lib,
  ...
}: let
  home = config.home.homeDirectory;

  # Maps GITHUB_TOKEN → GITHUB_PERSONAL_ACCESS_TOKEN at runtime.
  # ${ } is shell expansion at server spawn, not Nix build time.
  githubServer = {
    command = "sh";
    args = ["-c" "GITHUB_PERSONAL_ACCESS_TOKEN=\"\${GITHUB_TOKEN:-}\" npx -y @modelcontextprotocol/server-github"];
  };

  filesystemServer = {
    command = "npx";
    args = ["-y" "@modelcontextprotocol/server-filesystem" "${home}/.dotfiles" "${home}/Developer"];
  };

  playwrightServer = {
    command = "npx";
    args = ["-y" "@playwright/mcp" "--isolated" "--headless"];
  };

  # ── Claude Code CLI ──────────────────────────────────────────────────────────
  # File: ~/.claude/claude_desktop_config.json
  # Claude Code reads this on startup; does NOT write to it unless `claude mcp add`.
  claudeMcpServers = {
    filesystem = filesystemServer;
    github = githubServer;
    playwright = playwrightServer;
  };

  # ── opencode ─────────────────────────────────────────────────────────────────
  # File: ~/.config/opencode/opencode.json  (mcp key, type = "local" for stdio)
  # Merged into existing config — preserves plugin, experimental, share.
  opencodeMcpServers = {
    filesystem =
      filesystemServer
      // {
        type = "local";
        enabled = true;
      };
    github =
      githubServer
      // {
        type = "local";
        enabled = true;
      };
    playwright =
      playwrightServer
      // {
        type = "local";
        enabled = true;
      };
  };

  opencodeBaseConfig = {
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
  # Claude Code: ~/.claude/claude_desktop_config.json
  home.activation.claudeMcp = lib.hm.dag.entryAfter ["writeBoundary"] ''
    target="$HOME/.claude/claude_desktop_config.json"
    nix_servers='${builtins.toJSON claudeMcpServers}'

    mkdir -p "$HOME/.claude"

    if [ -f "$target" ]; then
      existing_servers=$(${pkgs.jq}/bin/jq -c '.mcpServers // {}' "$target")
      merged=$(${pkgs.jq}/bin/jq -cn \
        --argjson nix "$nix_servers" \
        --argjson live "$existing_servers" \
        '$nix + $live')
      ${pkgs.jq}/bin/jq --argjson servers "$merged" \
        '. + {mcpServers: $servers}' "$target" \
        > "$target.tmp" && mv "$target.tmp" "$target"
    else
      echo "{\"mcpServers\": $nix_servers}" | ${pkgs.jq}/bin/jq '.' > "$target"
    fi
  '';

  # opencode: ~/.config/opencode/opencode.json  (base config: schema, plugin, experimental, share)
  # Runs before opencodeMcp so MCP servers merge on top of the base.
  home.activation.opencodeConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    target="$HOME/.config/opencode/opencode.json"
    base='${builtins.toJSON opencodeBaseConfig}'

    mkdir -p "$HOME/.config/opencode"

    if [ -f "$target" ]; then
      # Nix wins for static fields; preserve mcp, provider, env (managed by later activations)
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

  # opencode: ~/.config/opencode/opencode.json  (mcp key)
  home.activation.opencodeMcp = lib.hm.dag.entryAfter ["writeBoundary" "opencodeConfig"] ''
    target="$HOME/.config/opencode/opencode.json"
    nix_servers='${builtins.toJSON opencodeMcpServers}'

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

  # Role-specific MCP servers (e.g. personal: docker, postgres, shadcn)
  home.activation.claudeMcpExtra = lib.hm.dag.entryAfter ["writeBoundary" "claudeMcp"] ''
    target="$HOME/.claude/claude_desktop_config.json"
    extra_servers='${builtins.toJSON config.home.ai.extraMcpServers}'

    if [ "$extra_servers" != "{}" ] && [ -f "$target" ]; then
      existing=$(${pkgs.jq}/bin/jq -c '.mcpServers // {}' "$target")
      merged=$(${pkgs.jq}/bin/jq -cn \
        --argjson extra "$extra_servers" \
        --argjson live "$existing" \
        '$extra + $live')
      ${pkgs.jq}/bin/jq --argjson servers "$merged" \
        '. + {mcpServers: $servers}' "$target" \
        > "$target.tmp" && mv "$target.tmp" "$target"
    fi
  '';

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

  # Conditionally write AI provider configs based on which API keys are configured.
  # Uses {env:VAR} syntax — opencode resolves at runtime from fish environment.
  # Keys live in ~/.config/fish/secrets.fish (never committed).
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
          "options": {"baseURL": "https://api.z.ai/api/paas/v4", "apiKey": "{env:Z_AI_API_KEY}"},
          "models": {
            "glm-5.1":      {"name": "GLM-5.1"},
            "glm-4.7":      {"name": "GLM-4.7"},
            "glm-z1-flash": {"name": "GLM-Z1-Flash (fast)"}
          }
        }
      }')
    fi

    if has_key "OLLAMA_CLOUD_API_KEY"; then
      provider=$(echo "$provider" | ${pkgs.jq}/bin/jq '. + {
        "ollama-cloud": {
          "npm": "@ai-sdk/openai-compatible",
          "name": "Ollama Cloud",
          "options": {"baseURL": "https://ollama.com/v1", "apiKey": "{env:OLLAMA_CLOUD_API_KEY}"},
          "models": {
            "qwen2.5-coder:32b": {"name": "Qwen2.5 Coder 32B"},
            "qwen2.5-coder:7b":  {"name": "Qwen2.5 Coder 7B (fast)"}
          }
        }
      }')
    fi

    if has_key "OPENAI_API_KEY"; then
      provider=$(echo "$provider" | ${pkgs.jq}/bin/jq '. + {
        "codex": {
          "npm": "@ai-sdk/openai",
          "name": "Codex",
          "options": {"apiKey": "{env:OPENAI_API_KEY}"},
          "models": {
            "codex-mini-latest": {"name": "Codex Mini"},
            "gpt-4.1-mini":      {"name": "GPT-4.1 Mini (fast)"}
          }
        }
      }')
    fi

    if has_key "NVIDIA_API_KEY"; then
      provider=$(echo "$provider" | ${pkgs.jq}/bin/jq '. + {
        "nvidia": {
          "npm": "@ai-sdk/openai-compatible",
          "name": "NVIDIA NIM",
          "options": {"baseURL": "https://integrate.api.nvidia.com/v1", "apiKey": "{env:NVIDIA_API_KEY}"},
          "models": {
            "meta/llama-3.3-70b-instruct":             {"name": "Llama 3.3 70B"},
            "nvidia/llama-3.1-nemotron-ultra-253b-v1": {"name": "Nemotron Ultra 253B"}
          }
        }
      }')
    fi

    # OpenCode Go: built-in provider, OPENCODE_API_KEY read from env at runtime
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
