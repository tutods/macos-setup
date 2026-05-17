{
  pkgs,
  lib,
  ...
}: let
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

    # Run biome check+fix after every file edit — only when biome config exists.
    # Falls back to ./node_modules/.bin/biome if not in PATH (project-local install).
    # Exits 0 silently when biome is unavailable or not configured.
    hooks.PostToolUse = [
      {
        matcher = "Edit|Write|MultiEdit";
        hooks = [
          {
            type = "command";
            command = "if [ -f biome.json ] || [ -f biome.jsonc ]; then if command -v biome >/dev/null 2>&1; then biome check --write 2>&1; elif [ -x ./node_modules/.bin/biome ]; then ./node_modules/.bin/biome check --write 2>&1; fi; fi";
          }
        ];
      }
    ];

    extraKnownMarketplaces = {
      caveman.source = {
        source = "github";
        repo = "JuliusBrussee/caveman";
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

    # Nix is authoritative for plugins listed here (merge: live + nix, nix wins).
    # Plugins not listed here can still be managed via the UI.
    # To permanently remove a plugin from existing installs add it to the
    # purge list in the activation below instead of setting false here.
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
      "prisma@claude-plugins-official" = true;
      "sanity@claude-plugins-official" = true;
      "autofix-bot@claude-plugins-official" = true;
      "claude-seo@agricidaniel-seo" = true;
      "codex@openai-codex" = true;
    };
  };
in {
  home.file.".claude/CLAUDE.md".text = "@RTK.md\n";

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
        '$live + $nix')
      # Purge plugins removed from this config (migration for existing installs).
      # No-op on fresh installs where these keys never existed.
      merged_plugins=$(echo "$merged_plugins" | ${pkgs.jq}/bin/jq -c \
        'del(.["terraform@claude-plugins-official"], .["warp@claude-code-warp"])')
      echo "$base" \
        | ${pkgs.jq}/bin/jq --argjson plugins "$merged_plugins" \
            '. + {enabledPlugins: $plugins}' \
        > "$target.tmp" && mv "$target.tmp" "$target"
    else
      echo "$base" > "$target"
    fi
  '';
}
