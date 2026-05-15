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

  settings = {
    theme = "dark-daltonized";

    telemetry.enabled = false;

    permissions.deny = [
      "Read(./.env)"
      "Read(./.env.*)"
      "Read(./secrets/**)"
      "Read(~/.config/fish/secrets.fish)"
    ];

    env.CLAUDE_CODE_SKIP_PROMPT_HISTORY = "1";

    hooks.PreToolUse = [
      {
        matcher = "Bash";
        hooks = [
          {
            type = "command";
            command = "rtk hook claude";
          }
        ];
      }
    ];

    extraKnownMarketplaces = {
      caveman.source = {
        source = "github";
        repo = "JuliusBrussee/caveman";
      };
      "claude-code-warp".source = {
        source = "github";
        repo = "warpdotdev/claude-code-warp";
      };
      "agricidaniel-seo".source = {
        source = "github";
        repo = "AgriciDaniel/claude-seo";
      };
      "openai-codex".source = {
        source = "github";
        repo = "openai/codex-plugin-cc";
      };
    };

    # Baseline plugins — preserved from live file on re-deploy (see activation).
    # Add new plugins here; they merge into the live file on next darwin-rebuild switch.
    enabledPlugins = {
      "caveman@caveman" = true;
      "superpowers@claude-plugins-official" = true;
      "frontend-design@claude-plugins-official" = true;
      "code-review@claude-plugins-official" = true;
      "code-simplifier@claude-plugins-official" = true;
      "github@claude-plugins-official" = true;
      "feature-dev@claude-plugins-official" = true;
      "claude-md-management@claude-plugins-official" = true;
      "typescript-lsp@claude-plugins-official" = true;
      "security-guidance@claude-plugins-official" = true;
      "commit-commands@claude-plugins-official" = true;
      "figma@claude-plugins-official" = true;
      "claude-code-setup@claude-plugins-official" = true;
      "pr-review-toolkit@claude-plugins-official" = true;
      "sourcegraph@claude-plugins-official" = true;
      "terraform@claude-plugins-official" = true;
      "prisma@claude-plugins-official" = true;
      "sanity@claude-plugins-official" = true;
      "autofix-bot@claude-plugins-official" = true;
      "warp@claude-code-warp" = true;
      "claude-seo@agricidaniel-seo" = true;
      "codex@openai-codex" = true;
    };
  };
in {
  home.file.".claude/CLAUDE.md".text = "@RTK.md\n";

  # ── settings.json ────────────────────────────────────────────────────────────
  home.activation.claudeSettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
    target="$HOME/.claude/settings.json"
    base='${builtins.toJSON settings}'

    mkdir -p "$HOME/.claude"

    if [ -f "$target" ]; then
      existing_plugins=$(${pkgs.jq}/bin/jq -c '.enabledPlugins // {}' "$target")
      nix_plugins=$(echo "$base" | ${pkgs.jq}/bin/jq -c '.enabledPlugins')
      merged_plugins=$(${pkgs.jq}/bin/jq -cn \
        --argjson nix "$nix_plugins" \
        --argjson live "$existing_plugins" \
        '$nix + $live')
      echo "$base" \
        | ${pkgs.jq}/bin/jq --argjson plugins "$merged_plugins" \
            '. + {enabledPlugins: $plugins}' \
        > "$target.tmp" && mv "$target.tmp" "$target"
    else
      echo "$base" > "$target"
    fi
  '';

  # ── claude_desktop_config.json (MCP) ─────────────────────────────────────────
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

  # ── role-specific MCP servers (extraMcpServers option) ───────────────────────
  home.activation.claudeMcpExtra = lib.hm.dag.entryAfter ["writeBoundary" "claudeMcp"] ''
    target="$HOME/.claude/claude_desktop_config.json"
    extra='${builtins.toJSON config.home.ai.extraMcpServers}'

    if [ "$extra" != "{}" ] && [ -f "$target" ]; then
      existing=$(${pkgs.jq}/bin/jq -c '.mcpServers // {}' "$target")
      merged=$(${pkgs.jq}/bin/jq -cn \
        --argjson extra "$extra" \
        --argjson live "$existing" \
        '$extra + $live')
      ${pkgs.jq}/bin/jq --argjson servers "$merged" \
        '. + {mcpServers: $servers}' "$target" \
        > "$target.tmp" && mv "$target.tmp" "$target"
    fi
  '';
}
