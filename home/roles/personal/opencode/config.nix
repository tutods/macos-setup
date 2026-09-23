{
  aiLib,
  config,
  lib,
  ...
}: let
  # Tier ids; instructions/opencode-delegation.md mirrors them, change both together.
  # Council seats are deliberately one model FAMILY each (Z.ai, DeepSeek,
  # Moonshot, MiniMax, Alibaba, NVIDIA, OpenAI): a reviewer from the family
  # that wrote an answer inherits its blind spots. Concurrency on the Pro
  # plan is 3, so the 5-seat fan-out runs in 2 waves, accepted.
  # Hidden subagents cost 0 always-on tokens (opencode filters `hidden` out of
  # the agent list it puts in the prompt); only the visible chair's description
  # is paid. That is why the council is kept while nix-architect (visible, 214
  # chars, never dispatched once in 8 weeks) was deleted; /council is the
  # council's only dispatcher. vault-lint stays despite 0 dispatches: the
  # shared obsidian-vault skill instructs agents to dispatch it by name.
  # fast/best are no longer referenced by Nix code: markdown-backed agents
  # take their model from frontmatter (which wins the merge), so those two
  # keys stay only as the machine-readable tier ids the frontmatter mirrors.
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

  # Secret paths: the anchored-glob rendering of the canonical family list in
  # lib/ai.nix (aiLib.secretPathFamilies), the same source
  # home/common/ai/settings.nix renders its Bash() prefix rules from. A glob
  # here is a full-command anchored regex where `*` also matches `/`, so the
  # leading `*` covers both `~/.ssh/x` and `/Users/<me>/.ssh/x`.
  secretGlobs =
    aiLib.secretOpencodeGlobs
    # opencode-only addition: provider auth written by /connect lands in
    # ~/.local/share/opencode/auth.json. It is not in the shared families,
    # and the tool-output external_directory allow below would otherwise
    # leave it one allowed tree away from an unprompted read (read defaults
    # allow). Same anchored-glob shape: the leading * spans /Users/<me>/.
    ++ ["*local/share/opencode/auth.json*"];

  # The real backstop: opencode's built-in read defaults are `read:* allow` with
  # only `*.env*` set to ask, so the read tool opens ~/.ssh/id_ed25519 with no
  # prompt. Config rules are appended after the defaults and resolved with
  # findLast, and "*" sorts before every deny, so the denies win.
  readDenies = {"*" = "allow";} // lib.genAttrs secretGlobs (_: "deny");
  # MCP tool asks always carry pattern ["*"], so per-path glob rules can never
  # gate an MCP tool; built-in read + edit + readDenies are the only backstop
  # that enforces (corrected finding: docs/ai-lessons.md).
  #
  # No github/postgres/playwright MCP servers: gh/psql via bash cover the same
  # ground with no always-on schema cost; playwright is opted into per-project
  # instead (docs/opencode-setup.md).
  mcpServers = {
    shadcn = {
      type = "local";
      command = ["npx" "-y" "shadcn@latest" "mcp"];
      enabled = true;
      timeout = 15000;
    };
  };

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
  # Readers and rtk reader subcommands are the canonical lists in lib/ai.nix
  # (aiLib.secretReaders / aiLib.rtkReaderSubcommands), shared with the Claude
  # rendering. rtk readers become two words ("rtk read", not "rtk"), since the
  # plugin's rewrite hook turns `cat ~/.ssh/id_ed25519` into
  # `rtk read ~/.ssh/id_ed25519` and a bare "rtk" prefix would blanket-deny
  # every rtk subcommand, not just the reader ones.
  secretDenies = lib.listToAttrs (
    lib.concatMap (
      reader: map (glob: lib.nameValuePair "${reader} ${glob}" "deny") secretGlobs
    ) (aiLib.secretReaders ++ map (sub: "rtk ${sub}") aiLib.rtkReaderSubcommands)
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

  # Read-only git forms, pinned to allow explicitly. Belt-and-braces, not a
  # live fix: the 7 recorded `git diff` asks all predate the bashRules deploy
  # (the catch-all already allows them today, the log shows zero since, and
  # today's bash asks are the intended dangerAsk ones). Pinned so a future
  # default tightening or an rtk-rewrite miss cannot reintroduce prompts on
  # read-only git. Shadowing checked: no rule here shares a literal prefix
  # with any dangerAsk or secretDenies form (e.g. `git branch --list*` never
  # matches text starting `git branch -D`), so the asks and denies keep winning.
  readOnlyGitAllow = [
    "git status*"
    "git log*"
    "git diff*"
    "git show*"
    "git blame*"
    "git rev-parse*"
    "git ls-files*"
    "git branch --list*"
    "git remote -v*"
    "git tag --list*"
    "git describe*"
    "rtk git status*"
    "rtk git log*"
    "rtk git diff*"
    "rtk git show*"
    "rtk git blame*"
  ];

  bashRules =
    secretDenies
    // lib.genAttrs readOnlyGitAllow (_: "allow")
    // lib.genAttrs dangerAsk (_: "ask")
    // lib.genAttrs dangerDeny (_: "deny")
    // {"*" = "allow";};

  councilAgents = lib.mapAttrs' (persona: model:
    lib.nameValuePair "council-${persona}" {
      inherit model;
      mode = "subagent";
      hidden = true;
      temperature = 0.4;
      # A seat answers one prompt. The Sep 8 run showed what an uncapped
      # council loop does (6.8h, 455M tokens), so every seat hard-stops.
      steps = 20;
      description = "Council advisor seat. Invoked only by the council command, never directly.";
      permission.task."*" = "deny";
    })
  m.seats;

  cfg = {
    "$schema" = "https://opencode.ai/config.json";

    model = m.default;
    small_model = m.small;
    # One level: primary -> subagent. Every subagent now carries
    # permission.task."*" = "deny", so a second level had nothing left that
    # could use it. /council fans its seats out from the chair, itself a
    # primary, so it fits in one level too.
    subagent_depth = 1;

    # skills.paths re-adds the Nix-deployed repo skills after
    # OPENCODE_DISABLE_EXTERNAL_SKILLS turns off the ~/.claude/skills external
    # scan, so the skill set is exactly what this repo declares,
    # deterministically. That env var also disables project-local
    # .claude/skills discovery (same branch in skill/index.ts), so the
    # relative ".claude/skills" entry restores project-local parity: relative
    # paths resolve against the session directory (skill/index.ts:213).
    skills.paths = ["~/.claude/skills" ".claude/skills"];

    autoupdate = false;
    lsp = true;
    share = "disabled";
    snapshot = false;
    # No logLevel key here: it is schema-valid but nothing reads it. The log
    # level only comes from OPENCODE_LOG_LEVEL (set as a session variable in
    # default.nix) or the --log-level flag.
    compaction.auto = true;
    disabled_providers = ["azure" "vertex" "bedrock"];

    mcp = mcpServers;

    agent =
      {
        # Agent models live in the markdown frontmatter, the single source of
        # truth: opencode merges markdown over opencode.json (markdown wins),
        # so a model set here for a markdown-backed agent is silently dead.
        # config.nix carries models only for the config-only agents with no
        # markdown file (the council seats, chair and peer-reviewer below).
        # The tier ids above are the source of truth; a tier change edits the
        # frontmatter and instructions/opencode-delegation.md together.
        vault-lint.permission.task."*" = "deny";
        vault-search.permission.task."*" = "deny";
      }
      // councilAgents
      // {
        # Dedicated primary for /council: coordination only, no bash at all,
        # just task spawn + text synthesis. Inline prompt keeps the agents/
        # dir untouched.
        council-chair = {
          mode = "primary";
          model = m.default;
          steps = 40;
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
          steps = 15;
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
      # No filesystem MCP server: per-argument permission globs don't enforce
      # (see the readDenies comment above); built-in read/edit stay the backstop.
      # external_directory: allow the working trees plus scratch/config space.
      # The "*" = "ask" catch-all stays — an unlisted path still prompts — but
      # the temp trees are pure friction: opencode itself keeps scratch output
      # in $TMPDIR and its own tool-output dir under ~/.local/share, and 122
      # recorded asks were agents verifying work in /tmp. Both spellings are
      # listed because macOS symlinks /tmp -> /private/tmp and the glob match
      # is on the literal path text, so /tmp/* does not cover /private/tmp/*.
      external_directory = {
        "*" = "ask";
        "${config.home.homeDirectory}/Obsidian/**" = "allow";
        "${config.home.homeDirectory}/.dotfiles/**" = "allow";
        "${config.home.homeDirectory}/Developer/**" = "allow";
        "/tmp/*" = "allow";
        "/private/tmp/*" = "allow";
        "${config.home.homeDirectory}/.config/opencode/**" = "allow";
        "${config.home.homeDirectory}/.local/share/opencode/**" = "allow";
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
  # typo. Agent markdown frontmatter is not covered — and frontmatter
  # permission maps resolve with findLast over YAML *insertion* order, not the
  # alphabetical order Nix gives this file, so in frontmatter the "*" catch-all
  # must be the FIRST key of a map: listed last it out-matches every specific
  # rule, and a last-match "*"+deny makes opencode drop the tool entirely
  # (see agents/vault-lint.md).
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
