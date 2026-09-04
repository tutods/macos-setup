{
  aiLib,
  config,
  lib,
  ...
}: let
  # Same paths as the Bash(cat ...) denies below, in rtk's reader-subcommand
  # forms: rtk-rewrite.sh turns `cat ~/.ssh/id_ed25519` into
  # `rtk read ~/.ssh/id_ed25519` before any allow/deny rule sees it, so the
  # cat form alone stops nothing once rtk is on PATH.
  rtkSecretDenies = lib.concatMap (
    sub:
      map (path: "Bash(rtk ${sub} ${path})") [
        "~/.ssh/*"
        "~/.aws/*"
        "~/.config/fish/secrets.fish*"
        "~/.config/git/private*"
        "~/.config/gcloud/*"
      ]
  ) ["read" "ls" "tree" "grep" "rg" "json" "env" "find" "smart" "wc" "diff" "log"];
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

    permissions.deny =
      [
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
        # Defense in depth: the Read() rules above gate only the Read tool, so
        # without these a `cat ~/.ssh/id_ed25519` is one reflexive approval away.
        # Prefix-matched, not airtight — the point is stopping the casual path.
        "Bash(cat ~/.ssh/*)"
        "Bash(cat ~/.aws/*)"
        "Bash(cat ~/.config/fish/secrets.fish*)"
        "Bash(cat ~/.config/git/private*)"
        "Bash(cat ~/.config/gcloud/*)"
        "Bash(base64 ~/.ssh/*)"
        "Bash(base64 ~/.aws/*)"
      ]
      ++ rtkSecretDenies;
    permissions.additionalDirectories = ["~/Obsidian"];
    # Classifier-guarded default: reads, in-project edits and read-only Bash run
    # without a prompt; network, destructive Bash and out-of-project writes still
    # ask. The deny list above stays absolute in every mode.
    permissions.defaultMode = "full-auto";
    # Declared entries persist across deploys; any click-granted allows not
    # declared here are cleared on every deploy.
    permissions.allow = [
      # RTK rewrites of read-only commands, declared so the PreToolUse rewrite
      # does not turn every status/log/diff into a permission prompt. RTK only
      # rewrites when the ORIGINAL command matched an allow rule, so this list
      # stays the authority; deny rules still win regardless.
      "Bash(rtk git status:*)"
      "Bash(rtk git log:*)"
      "Bash(rtk git diff:*)"
      "Bash(rtk git show:*)"
      "Bash(rtk ls:*)"
      "Bash(rtk find:*)"
      "Bash(rtk grep:*)"
      "Bash(rtk read:*)"
      "Bash(rtk deps:*)"
      "Bash(rtk gain:*)"
      "Bash(*)"
      "Edit(*)"
      "Write(*)"
      "MultiEdit(*)"
    ];

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
      # RTK auto-rewrite: rewrites commands through rtk for token-cheap output.
      # Own matcher group (not appended to the attribution hook above) so a
      # future removal only touches this group, never the attribution hook.
      # rtk-rewrite.sh is a defensive wrapper: it resolves the rtk binary and
      # exits 0 (silent passthrough) when rtk (now Nix-provided, see
      # modules/packages/development.nix) is not on PATH, so a machine without
      # it loses only the savings, never the session. Deny from the
      # attribution hook still wins over any rewrite; both hooks run in
      # parallel. See docs/ai-lessons.md for the revisit decision.
      {
        matcher = "Bash";
        hooks = [
          {
            type = "command";
            command = "\"$HOME/.claude/hooks/rtk-rewrite.sh\"";
            timeout = 10;
            statusMessage = "Rewriting command through rtk";
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
      # Hard gate, not a nudge: denies main-thread Edit/Write/MultiEdit past a
      # small per-turn grace allowance (matching the "single already-known
      # file or one-line change" exception in delegation.md). Subagents are
      # never restricted (agent_id present). See force-delegation.sh.
      {
        matcher = "Edit|Write|MultiEdit";
        hooks = [
          {
            type = "command";
            command = "\"$HOME/.claude/hooks/force-delegation.sh\"";
            timeout = 5;
            statusMessage = "Enforcing delegation on file mutations";
          }
        ];
      }
    ];

    # Silent no-op unless the project has a biome config and a PATH-installed
    # biome; fixes only the edited file. See biome-fix.sh.
    hooks.PostToolUse = [
      {
        matcher = "Edit|Write|MultiEdit";
        hooks = [
          {
            type = "command";
            command = "\"$HOME/.claude/hooks/biome-fix.sh\"";
            timeout = 30;
            statusMessage = "Running biome on the edited file";
          }
        ];
      }
    ];

    # "<owner>/<repo>[@<sha>]"; the sha pins the marketplace to a reviewed
    # commit (Claude Code prefers `sha` over any ref when both are set).
    extraKnownMarketplaces =
      lib.mapAttrs (
        _: spec: let
          parts = lib.splitString "@" spec;
          repo = builtins.head parts;
        in {
          source =
            {
              source = "github";
              inherit repo;
            }
            // lib.optionalAttrs (builtins.length parts > 1) {
              sha = builtins.elemAt parts 1;
            };
        }
      )
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
  home.file.".claude/hooks/force-delegation.sh" = {
    source = ./force-delegation.sh;
    force = true;
  };
  home.file.".claude/hooks/delegation-reminder.sh" = {
    source = ./delegation-reminder.sh;
    force = true;
  };
  home.file.".claude/hooks/biome-fix.sh" = {
    source = ./biome-fix.sh;
    force = true;
  };
  home.file.".claude/hooks/rtk-rewrite.sh" = {
    source = ./rtk-rewrite.sh;
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
