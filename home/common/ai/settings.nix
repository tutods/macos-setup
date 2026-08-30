{
  aiLib,
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

    # Off so the harness's own memory dir isn't a second, unversioned source of
    # rules alongside ~/.claude/rules/. https://code.claude.com/docs/en/memory
    autoMemoryEnabled = false;

    # No autoCompactWindow set: model-tuned default, see docs/ai-lessons.md.
    autoCompactEnabled = true;
    env.CLAUDE_VAULT_BUDGET = "12288";
    # Role-scoped folder list for the SessionStart vault index; the work role
    # overrides this to drop personal-context folders. vault-context.sh reads
    # it, defaulting to the full list when unset.
    env.CLAUDE_VAULT_FOLDERS = lib.concatStringsSep " " config.home.ai.vaultFolders;

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
      "Read(~/.ssh/**)"
      "Read(~/.aws/**)"
      "Read(~/.config/gcloud/**)"
      "Read(~/.config/git/private)"
      "Read(**/.env)"
      "Read(**/.env.*)"
    ];
    permissions.additionalDirectories = ["~/Obsidian"];
    # Declared so the merge owns it: a "yes, don't ask again" click writes a rule
    # here, and without Nix declaring the key that rule would survive every
    # deploy. Empty means every deploy clears click-granted allows; add wanted
    # ones here.
    permissions.allow = [];

    # ./vault-context.sh owns the folder list. Titles only, never bodies.
    hooks.SessionStart = [
      {
        hooks = [
          {
            type = "command";
            command = "\"$HOME/.claude/hooks/vault-context.sh\"";
            timeout = 30;
            statusMessage = "Injecting Obsidian vault context";
          }
        ];
      }
    ];

    # Re-states the Delegation Contract once the session has been compacted
    # (the rules file alone drifts then); before that boundary the full
    # contract is already in context and the hook stays silent. See
    # delegation-reminder.sh.
    hooks.UserPromptSubmit = [
      {
        hooks = [
          {
            type = "command";
            command = "\"$HOME/.claude/hooks/delegation-reminder.sh\"";
            timeout = 5;
            statusMessage = "Reinforcing delegation rules";
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
      {
        matcher = "Read|Grep|Glob";
        hooks = [
          {
            type = "command";
            command = "\"$HOME/.claude/hooks/delegate-nudge.sh\"";
            timeout = 5;
            statusMessage = "Counting inline recon calls";
          }
        ];
      }
    ];

    # Silent no-op unless the project has a biome config.
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

    extraKnownMarketplaces =
      lib.mapAttrs (_: repo: {
        source = {
          source = "github";
          inherit repo;
        };
      })
      config.home.ai.marketplaces;

    # Rewritten whole on every deploy, so dropping a plugin from
    # home.ai.plugins disables it. Adding one via the UI will not survive.
    enabledPlugins =
      lib.listToAttrs (map (p: lib.nameValuePair p true) config.home.ai.plugins);
  };
in {
  home.file.".claude/hooks/block-ai-attribution.sh" = {
    source = ./block-ai-attribution.sh;
    force = true;
  };
  home.file.".claude/hooks/vault-context.sh" = {
    source = ./vault-context.sh;
    force = true;
  };
  home.file.".claude/hooks/delegate-nudge.sh" = {
    source = ./delegate-nudge.sh;
    force = true;
  };
  home.file.".claude/hooks/delegation-reminder.sh" = {
    source = ./delegation-reminder.sh;
    force = true;
  };

  # Merge, not overwrite: Claude Code writes its own keys here (push-notification
  # toggles) and Orca appends its hook events. Nix owns the keys it declares;
  # foreign top-level keys are left alone, but a foreign hook event survives only
  # if it is in keepHookEvents. Anything else is cleared on deploy.
  home.activation.claudeSettings = lib.hm.dag.entryAfter ["writeBoundary"] (
    aiLib.mergeJsonObject {
      file = "$HOME/.claude/settings.json";
      value = settings;
      # Orca (github.com/.../orca) appends these; nothing else may persist a hook.
      keepHookEvents = [
        "Stop"
        "StopFailure"
        "SubagentStart"
        "SubagentStop"
        "TeammateIdle"
        "PostToolUseFailure"
        "PermissionRequest"
        "PostCompact"
      ];
    }
  );
}
