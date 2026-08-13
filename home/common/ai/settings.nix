{
  config,
  lib,
  ...
}: let
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
    permissions.additionalDirectories = ["~/Obsidian"];

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

    # Nix is fully authoritative for enabledPlugins — the whole file is
    # rewritten on every deploy, so a plugin dropped from home.ai.plugins is
    # simply gone on the next `./nix.sh`. Never add plugins via the UI; they
    # do not survive the next deploy.
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
    printf '%s\n' "$base" > "$target.tmp" && mv "$target.tmp" "$target"
  '';
}
