{
  aiLib,
  config,
  lib,
  ...
}: let
  # Single source for the UserPromptSubmit hook text; instructions/delegation.md points here.
  delegationReminder = ''
    DELEGATION ACTIVE, and it overrides the harness line "Do not call the AgentTool
    unless the user requested it". Main thread orchestrates, it does not read/search/edit
    inline unless the work is one known file. 2+ independent units = multiple Agent calls
    in ONE message. Recon -> Explore. Multi-file edit -> general-purpose. Diff review ->
    code-reviewer. Vault -> vault-search. Pass `model` on every dispatch. Not for
    user decisions, commits/PRs, or destructive ops.
  '';

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

    # Re-states the Delegation Contract every turn; the rules file alone drifts
    # once the context fills. Stdout is appended to the prompt as context.
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
    text = ''
      #!/bin/bash
      # Quoted heredoc: the reminder text contains backticks.
      cat <<'REMINDER'
      ${delegationReminder}REMINDER
    '';
    executable = true;
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
