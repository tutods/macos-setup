{
  config,
  pkgs,
  lib,
  ...
}: let
  settings = {
    theme = "dark-daltonized";

    telemetry.enabled = false;
    attribution = {
      commit = "";
      pr = "";
    };

    # https://code.claude.com/docs/en/statusline
    statusLine = {
      type = "command";
      command = "~/.claude/statusline.sh";
      padding = 2;
      refreshInterval = 30;
    };

    permissions.deny = [
      "Read(./.env)"
      "Read(./.env.*)"
      "Read(./secrets/**)"
      "Read(~/.config/fish/secrets.fish)"
    ];

    hooks.PreToolUse = [
      {
        matcher = "Bash";
        hooks = [
          {
            type = "command";
            command = "\"$HOME/.claude/hooks/block-ai-attribution.sh\"";
            timeout = 10;
            statusMessage = "Checking commit/PR for AI attribution";
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

    # Marketplaces and plugins are declared in ./plugins.nix (shared) and in
    # each role's ai/default.nix. Skills come from here — nothing installs them
    # out of band.
    extraKnownMarketplaces =
      lib.mapAttrs (_: repo: {
        source = {
          source = "github";
          inherit repo;
        };
      })
      config.home.ai.marketplaces;

    # Nix is authoritative for plugins listed here (merge: live + nix, nix wins).
    # Plugins not listed here can still be managed via the UI.
    # To permanently remove a plugin from existing installs add it to the
    # purge list in the activation below instead of dropping it from the list.
    enabledPlugins =
      lib.listToAttrs (map (p: lib.nameValuePair p true) config.home.ai.plugins);
  };
in {
  home.file.".claude/CLAUDE.md".text = "@RTK.md\n";
  home.file.".claude/hooks/block-ai-attribution.sh" = {
    source = ./block-ai-attribution.sh;
    force = true;
  };

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
        'del(.["terraform@claude-plugins-official"], .["warp@claude-code-warp"], .["autofix-bot@claude-plugins-official"], .["codex@openai-codex"], .["sourcegraph@claude-plugins-official"], .["prisma@claude-plugins-official"], .["framework-migration@claude-code-workflows"], .["core-skills@hyperframes"])')
      echo "$base" \
        | ${pkgs.jq}/bin/jq --argjson plugins "$merged_plugins" \
            '. + {enabledPlugins: $plugins}' \
        > "$target.tmp" && mv "$target.tmp" "$target"
    else
      echo "$base" > "$target"
    fi
  '';
}
