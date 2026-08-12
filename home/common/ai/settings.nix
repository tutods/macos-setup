{
  config,
  pkgs,
  lib,
  ...
}: let
  # Plugins deliberately removed from home.ai.plugins, deleted from the live
  # settings.json on every deploy.
  #
  # This list is load-bearing, not cosmetic: enabledPlugins merges live + nix,
  # so dropping an entry from home.ai.plugins alone leaves it enabled on any
  # machine that already installed it.
  #
  # Entries can be retired once every machine has deployed past them — the date
  # records when the entry was added, so it is clear what is safe to drop.
  purgedPlugins = [
    # ── pre-2026-08 ────────────────────────────────────────────────────────
    "terraform@claude-plugins-official"
    "warp@claude-code-warp"
    "autofix-bot@claude-plugins-official"
    "codex@openai-codex"

    # ── 2026-08 cleanup ────────────────────────────────────────────────────
    # MCP wrappers whose bundled .mcp.json registered servers we did not want
    "sourcegraph@claude-plugins-official"
    "prisma@claude-plugins-official"
    "sanity@claude-plugins-official"
    # superseded, unused, or redundant with a custom skill
    "framework-migration@claude-code-workflows"
    "core-skills@hyperframes" # strict subset of hyperframes@hyperframes
    "pm-skills@claude-code-skills" # acli custom skill + jira MCP cover this
    "code-simplifier@claude-plugins-official" # harness ships /simplify
    "commit-commands@claude-plugins-official" # conventional-commit custom skill
    "pr-review-toolkit@claude-plugins-official" # code-review + deep-review
    "claude-md-management@claude-plugins-official"
    # generic advice the model does not need spelled out
    "engineering@knowledge-work-plugins"
    "product-management@knowledge-work-plugins"
    "ui-design@claude-code-workflows" # half of it is mobile-native design
    "agent-teams@claude-code-workflows" # harness orchestrates natively
    # large bundles for occasional work — re-add if they earn their keep
    "marketing-skills@marketingskills" # 49 skills
    "hyperframes@hyperframes" # 25 skills, Remotion-specific
    "brand-voice@knowledge-work-plugins" # content-writer + humanizer cover it
    # duplicate of the personal optimize-images custom skill, which is more
    # specific (1500px longest side, WebP, metadata stripped) and backed by the
    # imagemagick/jpegoptim/optipng already in modules/packages/media.nix
    "image-optimization@claude-skills"
    # generic REST advice that contradicts api-conventions — most of it
    # recommends the { data, error } envelope this house style bans
    "rest-api-design@claude-skills"
    # ts-advanced-types / js-testing duplicate ts-conventions and
    # testing-conventions; nodejs-backend and modern-js are covered by
    # nestjs-best-practices + backend-development@claude-code-workflows
    "javascript-typescript@claude-code-workflows"
  ];

  purgeExpr = "del(${lib.concatMapStringsSep ", " (p: ''.["${p}"]'') purgedPlugins})";

  settings = {
    theme = "dark-daltonized";
    model = "opusplan";

    telemetry.enabled = false;
    attribution = {
      commit = "";
      pr = "";
    };

    # Auto memory off. Claude Code would otherwise read and write its own
    # memory directory, which is a second source of rules alongside the ones
    # this repo generates — and the only one not under version control.
    # Instructions live in ~/.claude/rules/, conventions live in skills.
    # https://code.claude.com/docs/en/memory
    autoMemoryEnabled = false;

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
      merged_plugins=$(echo "$merged_plugins" | ${pkgs.jq}/bin/jq -c '${purgeExpr}')
      echo "$base" \
        | ${pkgs.jq}/bin/jq --argjson plugins "$merged_plugins" \
            '. + {enabledPlugins: $plugins}' \
        > "$target.tmp" && mv "$target.tmp" "$target"
    else
      echo "$base" > "$target"
    fi
  '';
}
