{
  config,
  lib,
  ...
}: let
  # Ollama Cloud model seats. Tier table lives in
  # instructions/opencode-models.md; this is the machine-readable half.
  # Council seats are deliberately one model FAMILY each (Z.ai, DeepSeek,
  # Moonshot, MiniMax, Alibaba, NVIDIA, OpenAI): a reviewer from the family
  # that wrote an answer inherits its blind spots. Concurrency on the Pro
  # plan is 3, so the 5-seat fan-out runs in 2 waves, accepted.
  m = rec {
    fast = "ollama-cloud/glm-5.3-flash";
    default = "ollama-cloud/glm-5.3";
    best = "ollama-cloud/deepseek-v4-pro";
    small = "ollama-cloud/gpt-oss:20b";
    seats = {
      first-principles = "ollama-cloud/deepseek-v4-pro";
      expansionist = "ollama-cloud/kimi-k3";
      outsider = "ollama-cloud/minimax-m3";
      executor = "ollama-cloud/qwen3.5:397b";
      contrarian = "ollama-cloud/nemotron-3-ultra";
    };
    peerReview = "ollama-cloud/gpt-oss:120b";
  };

  # Secret paths, mirroring home/common/ai/settings.nix permissions.deny. A glob
  # here is a full-command anchored regex where `*` also matches `/`, so the
  # leading `*` covers both `~/.ssh/x` and `/Users/<me>/.ssh/x`.
  secretGlobs = [
    "*.ssh/*"
    "*.aws/*"
    "*.config/gcloud/*"
    "*.config/fish/secrets.fish*"
    "*.config/git/private*"
    "*.env*"
    "*secrets/*"
  ];

  # The real backstop: opencode's built-in read defaults are `read:* allow` with
  # only `*.env*` set to ask, so the read tool opens ~/.ssh/id_ed25519 with no
  # prompt. Config rules are appended after the defaults and resolved with
  # findLast, and "*" sorts before every deny, so the denies win.
  readDenies = {"*" = "allow";} // lib.genAttrs secretGlobs (_: "deny");

  # Command-prefixed rather than path-only: a bash rule resolves with findLast
  # over the JSON key order (Nix sorts alphabetically), and a listed
  # reader+glob pair (e.g. "cat *.ssh/*") out-sorts the catch-all
  # "*" = "allow", so a listed reader is reliably denied. Prefix-matched, not
  # airtight: the match is against the command's literal text, so anything
  # that doesn't literally start with a listed reader falls through to the
  # catch-all allow. `git diff; cat ~/.ssh/id_ed25519` doesn't start with a
  # listed reader and is allowed. Quoting defeats the glob too: `cat
  # ~/."ssh"/id_rsa` rewrites to `rtk read ~/."ssh"/id_rsa`, whose literal
  # text has no `.ssh/` substring. A symlink hop does the same: `ln -s
  # ~/.ssh/id_rsa /tmp/x && cat /tmp/x` becomes `rtk read /tmp/x`.
  # xxd/od/strings/cp/python -c are also unlisted. This stops the casual
  # path; readDenies is what actually holds.
  # rtk readers are two words ("rtk read", not "rtk"), since the plugin's
  # rewrite hook turns `cat ~/.ssh/id_ed25519` into `rtk read ~/.ssh/id_ed25519`
  # and a bare "rtk" prefix would blanket-deny every rtk subcommand, not just
  # the reader ones.
  secretDenies = lib.listToAttrs (
    lib.concatMap (
      reader: map (glob: lib.nameValuePair "${reader} ${glob}" "deny") secretGlobs
    ) [
      "cat"
      "bat"
      "less"
      "head"
      "tail"
      "base64"
      "rtk read"
      "rtk ls"
      "rtk tree"
      "rtk grep"
      "rtk rg"
      "rtk json"
      "rtk smart"
      "rtk env"
      "rtk find"
      "rtk wc"
      "rtk diff"
      "rtk log"
    ]
  );

  # Destructive commands. Everything else stays allow: the point of full-auto
  # is not being asked about `pnpm test`. These are the commands whose damage
  # outlives the session, so they buy back a prompt. Same findLast mechanics as
  # secretDenies: every key starts with a letter, so all of them out-sort the
  # "*" = "allow" catch-all (ASCII 42) once Nix serialises the attrset.
  # Prefix-matched against literal command text, so `rm  -rf` (double space) or
  # a shell variable holding the flags slips through. This is the guardrail for
  # the command the model reaches for by default, not a sandbox.
  dangerAsk = [
    "sudo *"
    "rm -rf *"
    "rm -fr *"
    "rm -r *"
    "git push --force*"
    "git push -f *"
    "git push --delete*"
    "rtk git push*"
    "git reset --hard*"
    "git clean -f*"
    "git checkout -- *"
    "git branch -D *"
    "chmod -R *"
    "chown -R *"
    "curl * | sh*"
    "curl * | bash*"
    "wget * | sh*"
    "wget * | bash*"
    "docker system prune*"
    "docker volume rm*"
    "npm publish*"
    "pnpm publish*"
    "dropdb *"
    "killall *"
    "pkill *"
    "nix-collect-garbage*"
    "shutdown*"
    "reboot*"
  ];

  # No prompt offered: nothing downstream of these is recoverable, so an
  # approval click is the wrong affordance. Run them in a terminal yourself.
  dangerDeny = [
    "dd *"
    "mkfs*"
    "diskutil erase*"
    "shred *"
  ];

  bashRules =
    secretDenies
    // lib.genAttrs dangerAsk (_: "ask")
    // lib.genAttrs dangerDeny (_: "deny")
    // {"*" = "allow";};

  councilAgents = lib.mapAttrs' (persona: model:
    lib.nameValuePair "council-${persona}" {
      inherit model;
      mode = "subagent";
      hidden = true;
      temperature = 0.4;
      description = "Council advisor seat. Invoked only by the council command or the orchestrator, never directly.";
      permission.task."*" = "deny";
    })
  m.seats;

  cfg = {
    "$schema" = "https://opencode.ai/config.json";

    model = m.default;
    small_model = m.small;
    default_agent = "orchestrator";
    # One level: primary -> subagent. Every subagent now carries
    # permission.task."*" = "deny", so a second level had nothing left that
    # could use it. /council fans its seats out from the chair, itself a
    # primary, so it fits in one level too.
    subagent_depth = 1;

    # Global rules file, generated by default.nix from the same instruction
    # sources Claude reads. skills.paths re-adds the Nix-deployed repo skills
    # after OPENCODE_DISABLE_EXTERNAL_SKILLS turns off both external scans
    # (~/.claude/skills and ~/.agents/skills), so the skill set is exactly
    # what this repo declares, deterministically.
    skills.paths = ["~/.claude/skills" "~/.agents/skills"];

    autoupdate = false;
    lsp = true;
    share = "disabled";
    snapshot = false;
    logLevel = "WARN";
    compaction.auto = true;
    disabled_providers = ["azure" "vertex" "bedrock"];

    mcp = {
      filesystem = {
        type = "local";
        command = ["npx" "-y" "@modelcontextprotocol/server-filesystem" "${config.home.homeDirectory}/.dotfiles" "${config.home.homeDirectory}/Developer" "${config.home.homeDirectory}/Obsidian"];
        enabled = true;
        timeout = 30000;
      };
      github = {
        type = "local";
        command = ["sh" "-c" "GITHUB_PERSONAL_ACCESS_TOKEN=\"\${GITHUB_TOKEN:-}\" npx -y @modelcontextprotocol/server-github"];
        enabled = true;
      };
      playwright = {
        type = "local";
        command = ["npx" "-y" "@playwright/mcp" "--isolated" "--headless"];
        enabled = true;
      };
      postgres = {
        type = "local";
        command = ["sh" "-c" "doppler run -- npx -y @modelcontextprotocol/server-postgres"];
        enabled = true;
        timeout = 15000;
      };
      shadcn = {
        type = "local";
        command = ["npx" "-y" "shadcn@latest" "mcp"];
        enabled = true;
      };
      code-review-graph = {
        type = "local";
        command = ["${config.home.homeDirectory}/.local/bin/code-review-graph" "serve"];
        enabled = true;
        timeout = 30000;
      };
    };

    agent =
      {
        # Primary orchestrator: the port of the Claude Delegation Contract.
        # Full-auto like every other agent below; the contract text itself
        # lives in the generated AGENTS.md, not in a per-turn injection.
        orchestrator = {
          mode = "primary";
          model = m.default;
          description = "Default primary agent. Orchestrates: plans, dispatches subagents, relays and verifies results. File work is delegated, never inline.";
          prompt = "{file:./agents/orchestrator.md}";
          permission = {
            edit = "allow";
            bash = bashRules;
            read = readDenies;
            task = {
              "*" = "allow";
            };
          };
        };
        # Config-level model overrides make config.nix the single source for
        # the tier table in instructions/opencode-models.md: the values in the
        # agent markdown frontmatter are overridden at merge time, so a tier
        # change here is the only edit needed (change both files anyway, the
        # table documents the tiers).
        code-reviewer.model = m.default;
        code-reviewer.permission.task."*" = "deny";
        # The one agent that runs unsupervised through implement/commit/push,
        # so it gets edit and bash without a prompt. Not a bare `bash = "allow"`:
        # that becomes a single {resource:"*",effect:"allow"} rule appended last
        # and outranks every deny under findLast, handing an unattended agent
        # zero-prompt `cat ~/.ssh/id_ed25519`.
        dev-lifecycle = {
          model = m.best;
          permission = {
            edit = "allow";
            bash = bashRules;
            read = readDenies;
            task."*" = "deny";
          };
          steps = 150;
        };
        vault-lint.model = m.fast;
        vault-lint.permission.task."*" = "deny";
        vault-search.model = m.fast;
        vault-search.permission.task."*" = "deny";
      }
      // councilAgents
      // {
        # Dedicated primary for /council: coordination only. No bash at all
        # (it never commits, unlike the orchestrator), just task spawn + text
        # synthesis. Inline prompt keeps the agents/ dir untouched.
        council-chair = {
          mode = "primary";
          model = m.default;
          description = "Primary agent for /council: fans out the advisor seats, runs the blind peer review, writes the chairman synthesis. No file or shell access.";
          prompt = "You are the council chair, a coordination-only primary agent. You never edit files or run shell commands. Dispatch the council seats exactly as the /council command template instructs, collect their answers, run the anonymised peer review, then write the chairman synthesis. All procedure comes from the command template.";
          permission = {
            edit = "deny";
            bash = "deny";
            task = {
              "*" = "allow";
            };
          };
        };
        # 6th family for peer review: never shares a family with a seat.
        council-peer-review = {
          model = m.peerReview;
          mode = "subagent";
          hidden = true;
          temperature = 0.2;
          description = "Blind peer reviewer for the council. Sees anonymised responses only, never advisor identities.";
          permission.task."*" = "deny";
        };
      };

    permission = {
      edit = "allow";
      webfetch = "allow";
      websearch = "allow";
      bash = bashRules;
      read = readDenies;
      # PermissionRuleConfig, not a path list: opencode rejects the whole file
      # with "Expected PermissionRuleConfig, got [...]" and prints it on every
      # startup. The assertion below only checks key names, which is why an
      # array shipped. "*" = "ask" keeps anything outside these three trees
      # behind a prompt rather than silently allowed.
      external_directory = {
        "*" = "ask";
        "${config.home.homeDirectory}/Obsidian/**" = "allow";
        "${config.home.homeDirectory}/.dotfiles/**" = "allow";
        "${config.home.homeDirectory}/Developer/**" = "allow";
      };
    };

    # Claude's PostToolUse biome-fix.sh, as opencode's native on-edit formatter.
    # The object form registers every built-in and then applies these overrides
    # (Format init, opencode 1.18.21), so it is not an allowlist: biome stays on,
    # carrying its own gate (biome.json/biome.jsonc up-tree AND @biomejs/biome
    # resolvable), a silent no-op everywhere else. Do not override
    # formatter.biome.command: supplying a command replaces that gate with an
    # unconditional run.
    #
    # disabled: every built-in whose enabled() gate is only `which <bin>` on
    # $PATH, with no project config file checked up-tree, so it can never
    # silently reformat a file here with conventions this repo did not opt into
    # (e.g. .nix is alejandra, not nixfmt). Config-file-gated built-ins stay on:
    # they no-op until a project opts in (biome's biome.json, prettier's
    # package.json dep, ruff's pyproject, oxfmt, pint, ocamlformat,
    # clang-format). Exception: uv (.py) is $PATH-only too, but opencode drops
    # ruff whenever uv is disabled, so it is left on.
    formatter = {
      air.disabled = true;
      cljfmt.disabled = true;
      dart.disabled = true;
      dfmt.disabled = true;
      gleam.disabled = true;
      gofmt.disabled = true;
      htmlbeautifier.disabled = true;
      ktlint.disabled = true;
      latexindent.disabled = true;
      mix.disabled = true;
      nixfmt.disabled = true;
      ormolu.disabled = true;
      rubocop.disabled = true;
      rustfmt.disabled = true;
      shfmt.disabled = true;
      standardrb.disabled = true;
      terraform.disabled = true;
      zig.disabled = true;
    };
  };

  # opencode permission actions, read off the schema the installed binary ships
  # (share/config.json, $defs/PermissionConfig; checked against 1.18.25). The
  # named list there is a subset of what the runtime accepts:
  # additionalProperties takes any key, and opencode's own default ruleset uses
  # "*", plan_enter and plan_exit, which the schema does not name. An unknown
  # key is silently inert at runtime, so this is the only thing that catches a
  # typo. Agent markdown frontmatter is not covered.
  permissionActions = [
    "*"
    "bash"
    "doom_loop"
    "edit"
    "external_directory"
    "glob"
    "grep"
    "list"
    "lsp"
    "plan_enter"
    "plan_exit"
    "question"
    "read"
    "skill"
    "task"
    "todowrite"
    "webfetch"
    "websearch"
  ];

  permissionBlocks =
    {"permission" = cfg;}
    // lib.mapAttrs' (name: agent: lib.nameValuePair "agent.${name}.permission" agent) cfg.agent;

  unknownKeys = block: lib.subtractLists permissionActions (lib.attrNames (block.permission or {}));

  # Every permission value is a PermissionRuleConfig: the string "ask"/"allow"/
  # "deny", or an attrset of glob to one of those. A list passes the key-name
  # check above and still makes opencode reject the entire file at startup, so
  # the shape is asserted too.
  validActions = ["ask" "allow" "deny"];
  badValues = block:
    lib.filter (k: let
      v = block.permission.${k};
    in
      !(
        (lib.isString v && builtins.elem v validActions)
        || (lib.isAttrs v && lib.all (a: builtins.elem a validActions) (lib.attrValues v))
      ))
    (lib.attrNames (block.permission or {}));
in {
  assertions =
    lib.mapAttrsToList (loc: block: {
      assertion = unknownKeys block == [] && badValues block == [];
      message = "opencode: ${loc} has invalid permission entries. Unknown key(s): ${toString (unknownKeys block)}. Bad value shape (must be \"ask\"/\"allow\"/\"deny\" or an attrset of glob to those, never a list) for: ${toString (badValues block)}. Valid keys: ${toString permissionActions}";
    })
    permissionBlocks;

  # Nix owns this file wholesale: opencode never writes opencode.json itself
  # (verified against 1.18.21, mtime only moves on manual edits). If a future
  # version starts self-writing, switch to aiLib.mergeJsonObject like
  # home/common/ai/settings.nix does. Escape hatch if this file breaks startup:
  # OPENCODE_CONFIG_CONTENT='{"$schema":"https://opencode.ai/config.json"}'.
  home.file.".config/opencode/opencode.json".text = builtins.toJSON cfg;
  home.file.".config/opencode/opencode.json".force = true;
}
