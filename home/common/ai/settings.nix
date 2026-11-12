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
  # forms: the rtk hook turns `cat ~/.ssh/id_ed25519` into
  # `rtk read ~/.ssh/id_ed25519` before any allow/deny rule sees it, so the
  # cat form alone stops nothing once rtk is on PATH.
  rtkSecretDenies =
    lib.concatMap (
      sub: map (path: "Bash(rtk ${sub} ${path}:*)") readerSecretPaths
    )
    aiLib.rtkReaderSubcommands;
  settings = {
    theme = "dark-daltonized";

    # model/modelSettings are app-written (/model); never declare them and never add model to dropKeys,
    # mergeJsonObject keeps undeclared live keys, so declaring it would fight the picker on every deploy.

    telemetry.enabled = false;
    attribution = {
      commit = "";
      pr = "";
    };

    # Off: the Obsidian vault is the only learned-fact store; memory duplicated it into every session.
    # https://code.claude.com/docs/en/memory
    autoMemoryEnabled = false;

    # No autoCompactWindow set: model-tuned default, see docs/ai-lessons.md.
    autoCompactEnabled = true;
    # Role-scoped list of in-scope vault folders (the work role drops
    # personal-context folders). Nothing injects vault content at session start
    # anymore; this env var is the deployed source of truth the vault-lint
    # agent reads for its scope-coverage check.
    env.CLAUDE_VAULT_FOLDERS = lib.concatStringsSep " " config.home.ai.vaultFolders;
    # Ranks below a per-call `model` and an agent's `model:`, so silence means
    # sonnet instead of the parent. No _FORCE: it would override the haiku
    # agents' own choice and drag them up a tier.
    env.CLAUDE_CODE_SUBAGENT_MODEL = "sonnet";
    # A goal left waiting on background tasks triggers a check-in, and each one
    # is a full-context turn. Background work already notifies on completion.
    env.CLAUDE_CODE_GOAL_CHECKIN_MINUTES = "0";
    # ponytail's SubagentStart hook injects its full ruleset into every subagent
    # unless this regex (unanchored, case-insensitive, on agent_type) narrows it
    # to the agents that actually write code.
    env.PONYTAIL_SUBAGENT_MATCHER = "general-purpose|cavecrew-builder";
    # Distinct inline Read/Grep/Glob targets per main-thread turn before delegate-nudge.sh denies.
    env.CLAUDE_RECON_LIMIT = "8";

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
      # does not turn every status/log/diff into a permission prompt. The
      # rewrite itself is unconditional inside the rtk binary and happens before
      # any rule is consulted (same reason rtkSecretDenies exists), so this list
      # decides only which REWRITTEN forms skip the prompt, never what gets
      # rewritten. Mirror a command here only when its plain form is already
      # allowed: an entry grants the rtk spelling exactly what the bare
      # spelling has, no more. Deny rules still win regardless.
      #
      # Deliberately not a blanket `Bash(rtk:*)`. Because every command is
      # rewritten, a blanket rule would hand silent approval to the rewritten
      # form of destructive commands too, which is precisely the prompt worth
      # keeping. Verbose-but-safe commands only; anything that writes, pushes,
      # installs or deletes stays out and keeps asking.
      "Bash(rtk git status:*)"
      "Bash(rtk git log:*)"
      "Bash(rtk git diff:*)"
      "Bash(rtk git show:*)"
      "Bash(rtk git blame:*)"
      "Bash(rtk ls:*)"
      "Bash(rtk find:*)"
      "Bash(rtk grep:*)"
      "Bash(rtk read:*)"
      "Bash(rtk deps:*)"
      "Bash(rtk gain:*)"
      # Read-only forge queries. `gh pr diff` is the best per-call saver in the
      # rtk history and was prompting on every use. `gh api` stays out: it is a
      # write surface, and block-ai-attribution.sh guards it.
      "Bash(rtk gh pr diff:*)"
      "Bash(rtk gh pr view:*)"
      "Bash(rtk gh pr list:*)"
      "Bash(rtk gh pr checks:*)"
      "Bash(rtk gh run list:*)"
      "Bash(rtk gh run view:*)"
      "Bash(rtk gh issue view:*)"
      "Bash(rtk gh issue list:*)"
      # The read-only half of the dev loop, where a TS monorepo produces the
      # noisiest output rtk compresses. Script runners are named per script so
      # `pnpm install` and friends are not swept in.
      "Bash(rtk test:*)"
      "Bash(rtk vitest:*)"
      "Bash(rtk jest:*)"
      "Bash(rtk lint:*)"
      "Bash(rtk tsc:*)"
      "Bash(rtk biome:*)"
      "Bash(rtk prettier:*)"
      "Bash(rtk playwright:*)"
      "Bash(rtk pnpm test:*)"
      "Bash(rtk pnpm lint:*)"
      "Bash(rtk pnpm typecheck:*)"
      "Bash(rtk pnpm build:*)"
      "Bash(rtk docker ps:*)"
      "Bash(rtk kubectl get:*)"
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
          {
            type = "command";
            command = "\"$HOME/.claude/hooks/destructive-guard.sh\"";
            timeout = 5;
            statusMessage = "Checking for irreversible commands";
          }
        ];
      }
      # rtk (github.com/rtk-ai/rtk) rewrites the command to its token-compressed form.
      # Must stay the literal "rtk hook claude": rtk verify/discover only recognise that spelling.
      {
        matcher = "Bash";
        hooks = [
          {
            type = "command";
            command = "rtk hook claude";
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
            statusMessage = "Enforcing delegation on inline recon";
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
      {
        matcher = "Agent";
        hooks = [
          {
            type = "command";
            command = "\"$HOME/.claude/hooks/subagent-model-gate.sh\"";
            timeout = 5;
            statusMessage = "Checking subagent model";
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
  home.file.".claude/hooks/subagent-model-gate.sh" = {
    source = ./subagent-model-gate.sh;
    force = true;
  };
  home.file.".claude/hooks/destructive-guard.sh" = {
    source = ./destructive-guard.sh;
    force = true;
  };
  # Shared turn-boundary logic sourced by delegate-nudge.sh and
  # force-delegation.sh; must live under hooks/lib/ next to them.
  home.file.".claude/hooks/lib/turn-key.sh" = {
    source = ./turn-key.sh;
    force = true;
  };
  home.file.".claude/hooks/biome-fix.sh" = {
    source = ./biome-fix.sh;
    force = true;
  };

  # Merge, not overwrite: Claude Code writes its own keys here (push-notification
  # toggles) and Orca appends its hook events. Nix owns the keys it declares;
  # foreign top-level keys are left alone, but a foreign hook event survives only
  # if it is in keepHookEvents. Anything else is cleared on deploy.
  home.activation.claudeSettings = lib.hm.dag.entryAfter ["writeBoundary"] (
    aiLib.mergeJsonObject {
      file = "$HOME/.claude/settings.json";
      value = lib.recursiveUpdate settings {env = config.home.ai.claudeEnv;};
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
        "SessionStart"
        "SessionEnd"
        "UserPromptSubmit"
        "PostToolBatch"
        "Elicitation"
        "ElicitationResult"
      ];
      # Deliberately undeclared above so Claude Code uses its model-tuned
      # default (the comment on autoCompactEnabled explains why). Without this
      # the merge's keep-foreign-keys rule would preserve a hand-set value
      # forever, silently overriding the decision.
      dropKeys = ["autoCompactWindow"];
    }
  );
}
