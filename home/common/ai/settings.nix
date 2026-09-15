{
  aiLib,
  config,
  lib,
  ...
}: let
  # Bash() permission rules support only exact matches and `prefix:*` prefix
  # matches: a mid-string `*` is a literal star, and `~` is never expanded (it
  # matches a literal tilde in the command text). So every secret family is
  # emitted in every spelling the model might type: home-scoped families as
  # literal `~/` and absolute, project-scoped families (mirroring opencode's
  # `*.env*` and `*secrets/*` globs) as bare and ./-prefixed. The families,
  # the reader commands and the rtk reader subcommands are the canonical
  # definitions in lib/ai.nix (aiLib.secretPathFamilies etc.), shared with
  # opencode's glob rendering in home/roles/personal/opencode/config.nix.
  readerSecretPaths =
    lib.concatMap (aiLib.secretPrefixSpellings config.home.homeDirectory)
    aiLib.secretPathFamilies;
  # Same paths as the reader denies below, in rtk's reader-subcommand
  # forms: rtk-rewrite.sh turns `cat ~/.ssh/id_ed25519` into
  # `rtk read ~/.ssh/id_ed25519` before any allow/deny rule sees it, so the
  # cat form alone stops nothing once rtk is on PATH.
  rtkSecretDenies =
    lib.concatMap (
      sub: map (path: "Bash(rtk ${sub} ${path}:*)") readerSecretPaths
    )
    aiLib.rtkReaderSubcommands;
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
    # Role-scoped list of in-scope vault folders (the work role drops
    # personal-context folders). Nothing injects vault content at session start
    # anymore; this env var is the deployed source of truth the vault-lint
    # agent reads for its scope-coverage check.
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
      ]
      # Defense in depth: the Read() rules above gate only the Read tool, so
      # without these a `cat ~/.ssh/id_ed25519` is one reflexive approval away.
      # These are `prefix:*` rules (the only wildcard Bash() supports), each
      # path in every spelling the model types: they catch a command that
      # STARTS with `<reader> <secret path>` and nothing more — best-effort
      # against the casual path, since `cd ~/.ssh && cat id_ed25519`, a shell
      # variable, or any unlisted reader command still evades them. The reader
      # list is aiLib.secretReaders (lib/ai.nix), the same canonical source
      # opencode's secretDenies matrix renders from in
      # home/roles/personal/opencode/config.nix.
      ++ lib.concatMap (
        reader: map (path: "Bash(${reader} ${path}:*)") readerSecretPaths
      )
      aiLib.secretReaders
      ++ rtkSecretDenies;
    permissions.additionalDirectories = ["~/Obsidian"];
    # Classifier-guarded default: reads, in-project edits and read-only Bash run
    # without a prompt; network, destructive Bash and out-of-project writes still
    # ask. The deny list above stays absolute in every mode.
    permissions.defaultMode = "auto";
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
    ];

    hooks.SessionStart = [
      {
        hooks = [
          {
            type = "command";
            command = "\"$HOME/.claude/hooks/crg-autobuild.sh\"";
            timeout = 10;
            statusMessage = "Refreshing code-review-graph";
          }
        ];
      }
      # Latches the compaction sentinel when a resumed or forked session
      # inherits an already-compacted transcript, so the reminder below keeps
      # firing under the new session id. Own group so removing it never
      # touches the crg hook. See compaction-sentinel.sh.
      {
        hooks = [
          {
            type = "command";
            command = "\"$HOME/.claude/hooks/compaction-sentinel.sh\"";
            timeout = 15;
            statusMessage = "Checking for a compaction boundary";
          }
        ];
      }
    ];

    # Latches the compaction sentinel before the boundary lands, so the first
    # post-compaction prompt already sees it. PreCompact and not PostCompact:
    # PostCompact is in keepHookEvents below (Orca appends its own entry) and
    # the deploy merge lets the Nix value win, so declaring it here would drop
    # Orca's hook.
    hooks.PreCompact = [
      {
        hooks = [
          {
            type = "command";
            command = "\"$HOME/.claude/hooks/compaction-sentinel.sh\"";
            timeout = 10;
            statusMessage = "Latching the compaction sentinel";
          }
        ];
      }
    ];

    # Re-states the Delegation Contract once the session has been compacted
    # (the rules file alone drifts then); before that boundary the full
    # contract is already in context and the hook stays silent. It reads that
    # verdict off the sentinel compaction-sentinel.sh latches, so the check is
    # one `[ -f ]` and forks nothing; the transcript scan it used to do here
    # every prompt blew this timeout on the work laptop. See
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
      # Hard gate, not a nudge: denies main-thread Edit/Write once a
      # turn would spread past a small distinct-file allowance (matching the
      # "single already-known file or one-line change" exception in
      # delegation.md); repeat edits to an already-allowed file stay free.
      # Subagents are never restricted (agent_id present). See
      # force-delegation.sh.
      {
        matcher = "Edit|Write";
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
        matcher = "Edit|Write";
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
    # Everything after the LAST '@' is the pin — same field
    # scripts/verify-plugins.sh reads (${spec##*@}) — and it must be a full
    # 40-char commit sha: a branch or tag there would be silently accepted by
    # Claude Code as a moving ref, defeating the supply-chain pin.
    extraKnownMarketplaces =
      lib.mapAttrs (
        name: spec: let
          parts = lib.splitString "@" spec;
          pinned = builtins.length parts > 1;
          repo =
            if pinned
            then lib.concatStringsSep "@" (lib.init parts)
            else spec;
          sha = lib.last parts;
        in {
          source =
            {
              source = "github";
              inherit repo;
            }
            // lib.optionalAttrs pinned {
              sha =
                if builtins.match "[0-9a-f]{40}" sha != null
                then sha
                else
                  throw ''
                    home.ai.marketplaces.${name} = "${spec}": the pin after the
                    last '@' ("${sha}") is not a full 40-char lowercase commit
                    sha. Branch/tag pins defeat the supply-chain pin; get the
                    commit with `git ls-remote https://github.com/${repo} HEAD`
                    and pin that.
                  '';
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
  home.file.".claude/hooks/delegate-nudge.sh" = {
    source = ./delegate-nudge.sh;
    force = true;
  };
  home.file.".claude/hooks/force-delegation.sh" = {
    source = ./force-delegation.sh;
    force = true;
  };
  # Shared turn-boundary logic sourced by delegate-nudge.sh and
  # force-delegation.sh; must live under hooks/lib/ next to them.
  home.file.".claude/hooks/lib/turn-key.sh" = {
    source = ./turn-key.sh;
    force = true;
  };
  home.file.".claude/hooks/delegation-reminder.sh" = {
    source = ./delegation-reminder.sh;
    force = true;
  };
  # Companion to delegation-reminder.sh: wired to PreCompact and SessionStart,
  # it latches the sentinel that hook tests.
  home.file.".claude/hooks/compaction-sentinel.sh" = {
    source = ./compaction-sentinel.sh;
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
  home.file.".claude/hooks/crg-autobuild.sh" = {
    source = ./crg-autobuild.sh;
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
