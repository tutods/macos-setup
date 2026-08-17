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

    # Compact earlier than the default (near-full context) — trigger once
    # ~60% of the real context window is used instead of waiting until
    # it's nearly full. A fixed-token autoCompactWindow was wrong here:
    # opusplan executes on Sonnet 5, which always runs a native 1M-token
    # window on the Anthropic API, so a value sized for 200k triggered
    # compaction way too early. CLAUDE_AUTOCOMPACT_PCT_OVERRIDE scales
    # with whatever window is actually in effect.
    autoCompactEnabled = true;
    env.CLAUDE_AUTOCOMPACT_PCT_OVERRIDE = "60";

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

    # Inject vault context into every session: lesson titles, convention +
    # decision titles, full convention bodies, and (matched against the
    # session's cwd) any note filed under the current project's slug. The
    # always-on "Prior Art" rule greps the vault by topic keywords, which
    # misses this — behavioral lessons and standing conventions don't always
    # match the session's keywords. Filesystem-derived (not a hand-maintained
    # index note) so it can't go stale. See ./vault-context.sh for the full
    # logic; silent no-op when the vault is absent.
    hooks.SessionStart = [
      {
        hooks = [
          {
            type = "command";
            command = "\"$HOME/.claude/hooks/vault-context.sh\"";
          }
        ];
      }
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
  home.file.".claude/hooks/vault-context.sh" = {
    source = ./vault-context.sh;
    force = true;
  };

  home.activation.claudeSettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
    target="$HOME/.claude/settings.json"
    base='${builtins.toJSON settings}'

    mkdir -p "$HOME/.claude"
    printf '%s\n' "$base" > "$target.tmp" && mv "$target.tmp" "$target"
  '';
}
