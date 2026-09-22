# opencode Setup

opencode is the second terminal AI harness, **personal machine only** (installed
via `home/roles/personal/packages.nix`, configured via `home/roles/personal/opencode/`).
The work machine has neither the binary nor the module. Everything Claude reads is
generated from this repo; opencode follows the same rule, sharing instruction
sources with Claude wherever the two harnesses agree.

## What is shared vs. diverged

| Mechanism | Claude | opencode |
|-----------|--------|----------|
| Always-on instructions | `~/.claude/rules/workflow.md`, concatenated from `home/common/ai/instructions/` | `~/.config/opencode/AGENTS.md`, generated from the same `shared-instructions.md` + `model-quality.md` + `learned-rules.md`, plus `opencode-delegation.md` and `opencode-models.md` |
| Delegation contract | `instructions/delegation.md` + `UserPromptSubmit` hook | `agents/orchestrator.md` (the default primary) + the same contract in the generated `AGENTS.md`, convention only, not enforced by any permission |
| Inline-edit allowance | 2 distinct files per turn, hook-enforced (`force-delegation.sh` hard-denies the spread) | "a single already-known file", deliberately stricter wording: there is no hook backstop in opencode, so the wording carries the weight enforcement provides on the Claude side |
| Skills | `~/.claude/skills/` (deployed copies) | `~/.claude/skills` plus `~/.agents/skills` (the `npx skills add` tree, see below) plus a project-relative `.claude/skills` entry, all listed in `skills.paths`. `OPENCODE_DISABLE_EXTERNAL_SKILLS=1` kills the external scans, including project-local `.claude/skills`/`.agents/skills` discovery (same branch in `skill/index.ts`); the relative entry restores project-local parity, resolving against the session directory |
| Subagents | `~/.claude/agents/*.md` | `~/.config/opencode/agents/*.md` (orchestrator, code-reviewer, dev-lifecycle, vault-lint, vault-search) |
| Council | Workflow tool, `llm-council.js` | `/council` command + hidden model-seat agents (no workflow engine exists) |
| MCP servers | merged into `~/.claude.json` | declared in `opencode.json` (Nix owns the file wholesale), with explicit per-server timeouts. Every server's tool schemas ride in the system prompt of every request, used or not, so a server earns its place only when its tools beat the bash equivalent; `postgres` was removed for that reason (psql covers it with no always-on cost), and `playwright` moved to per-project opt-in (below). `code-review-graph` is trimmed with `--tools` to the four tools actually called, from the 30 the server ships |
| Compaction | `autoCompactEnabled = true`, model-tuned default window | `compaction.auto = true` in `config.nix` |
| LSP | none | `lsp = true` in `config.nix`; `nixd` (via `home/roles/personal/packages.nix`) provides Nix language support |
| Vault context | none: no automatic injection, `vault-search` on demand | same, the plugin's system-prompt vault index was removed together with Claude's `vault-context.sh` hook |
| Statusline | `statusline.sh` | no equivalent, dropped |
| Plugins/marketplaces | `home.ai.plugins` | no marketplace mechanism, dropped |
| Format on edit | `biome-fix.sh` on `PostToolUse` | `formatter` in `config.nix`, opencode's built-in formatters with every `$PATH`-only-gated one switched off |
| Bash auto-rewrite | `rtk-rewrite` on `PreToolUse:Bash` | `opencode-parity.js`'s `tool.execute.before`, pipes the command through `rtk hook claude` (rtk has no `opencode` hook subcommand, and the old `rtk rewrite` subcommand is gone) and swaps in the rewrite when stdout is non-empty |
| Secret deny-list | `permissions.deny` in `home/common/ai/settings.nix` | `permission.read` and `permission.bash` deny globs in `config.nix`, generated from the same paths |
| Permission defaults | classifier-gated `auto` mode: a call the classifier judges safe runs unprompted, anything else asks, deny list absolute | open by default (`edit`/`webfetch`/`websearch` allow, `bash` allow-all via `bashRules`), but `bashRules` now layers a destructive-command ask/deny set on top of the secret denies, see below; every non-hidden subagent's own block repeats the same `edit`/`bash`/`read` shape |
| Co-author / AI attribution block | `block-ai-attribution.sh` on `PreToolUse` | the SAME deployed script, invoked from `opencode-parity.js`'s `tool.execute.before`: candidate bash commands (`git commit` / `gh pr` / `gh api`, the script's own filter) are piped in as PreToolUse JSON and a deny decision becomes a thrown error that blocks the call; fails open when the script is missing or errors. `.hooks/commit-msg` remains one layer below both harnesses as the commit-message backstop |
| Additional directories | `permissions.additionalDirectories = ["~/Obsidian"]` | no filesystem MCP server (its per-tool permission globs don't enforce, see `config.nix`'s `readDenies` comment); `permission.external_directory` asks by default and allows only the Obsidian/`.dotfiles`/Developer trees, see below |
| Council entry point | Workflow tool | `/council` command bound to the `council-chair` primary agent (coordination only: `edit`/`bash` denied, `task` allowed), not the general `orchestrator` |
- **Delegation depth**: `subagent_depth = 1` in `config.nix`, orchestrator to one subagent and no deeper. Every non-hidden subagent (`code-reviewer`, `dev-lifecycle`, `vault-lint`, `vault-search`, the council seats and peer-reviewer) carries `permission.task."*" = "deny"`, so a second dispatch level had nothing left that could use it. `/council` fans its seats out directly from the chair, itself a primary agent, so it still fits in one level.

### Claude auto vs. opencode danger list: a deliberate split

The two harnesses no longer share one permission posture, on purpose. Claude runs `settings.nix`'s `auto` mode: a built-in classifier judges each call and prompts only for what it flags, on top of an absolute deny list. opencode has no such classifier, so `auto` is not an option there; instead `bashRules` in `config.nix` keeps the top-level permission open (everything not matched falls through to `"*" = "allow"`) and buys back a prompt only for commands whose damage outlives the session: `dangerAsk` (`sudo *`, `rm -rf *`, `git push --force*`, `git reset --hard*`, `chmod -R *`, `curl * | sh*`, `nix-collect-garbage*`, and similar) resolves to `"ask"`, and `dangerDeny` (`dd *`, `mkfs*`, `diskutil erase*`, `shred *`) resolves to `"deny"` outright, no prompt offered, because nothing downstream of them is recoverable. Before this, opencode's `bash` permission denied only secret reads and allowed every one of those commands unprompted, on the top-level permission and on every agent that inherited it. The generated `permission.bash` block has one allow (the `"*"` catch-all, sorted first because opencode's findLast matcher orders by ASCII and every danger key starts with a letter), the rest split between ask and deny. Same caveat as the secret denies: this matches literal command text, so `rm  -rf` with a double space, or the flags held in a shell variable, slips past. It is a guardrail against the command a model reaches for by default, not a sandbox.

### `external_directory` shape fix

`permission.external_directory` was set to a list of path globs, but opencode's schema wants a `PermissionRuleConfig`: the string `"ask"`/`"allow"`/`"deny"`, or an object mapping a glob to one of those, never a bare list. A list passed the repo's own build-time assertion, because that assertion only checked permission key names, and opencode rejected the whole config file at startup with "Configuration is invalid at ~/.config/opencode/opencode.json ... Expected PermissionRuleConfig, got [...]" plus "Things to fix!" on every launch. `config.nix` now sets it as an object: `"*"` maps to `"ask"`, and the Obsidian, `.dotfiles` and Developer trees map to `"allow"`. The assertion in `config.nix` now checks value shape as well as key names, so a list can't ship here again; see [ai-lessons.md](ai-lessons.md) for the lesson.

Models come from Ollama Cloud (`provider/model` ids, API key in
`~/.local/share/opencode/auth.json`, never in Nix). The tier table
(fast/default/best) and the council seats are in
`instructions/opencode-models.md`, machine-readable in `config.nix`. Per-agent
models for the markdown-backed agents live in the agent frontmatter, which is
the single source of truth: opencode merges markdown over `opencode.json`
(markdown wins), so `config.nix` sets models only for the config-only council
agents. A tier change edits the frontmatter and the table together.

## Files

| Path | Role |
|------|------|
| `home/roles/personal/opencode/default.nix` | composition, AGENTS.md generation, agent/command/plugin deploys |
| `home/roles/personal/opencode/config.nix` | `opencode.json` (models, agents, permissions, MCP, skills.paths) |
| `home/roles/personal/opencode/skills.nix` | installs the `npx skills add` sources with no Claude marketplace.json into `~/.agents/skills`, opencode only |
| `home/roles/personal/opencode/agents/` | orchestrator + 5 subagents (see the table below) |
| `home/roles/personal/opencode/commands/council.md` | the `/council` fan-out |
| `home/roles/personal/opencode/plugins/opencode-parity.js` | the Claude hooks with no opencode config key: the `block-ai-attribution.sh` guard on bash commits/PRs, rtk bash rewrite, crg-autobuild on `session.created`, project-settings skill bridge via the `config` hook |
| `home/roles/personal/opencode/instructions/` | opencode-specific deltas folded into AGENTS.md |
| `home/roles/personal/opencode/maintenance.nix` | weekly launchd prune of `~/.local/share/opencode/{log,storage}` entries older than 30 days (`auth.json` is outside both trees and untouched) |

## Documented exceptions (out-of-band content)

Same posture as Orca's hook events in `~/.claude/settings.json`: left alone,
listed here so a future cleanup finds them.

- `~/.config/opencode/plugins/supacode-presence.js` — Supacode-generated, marked do-not-edit.
- `~/.config/opencode/skills/{graphify,supacode-cli,supacode-deeplinks}` — installed by their own tools, still scanned via opencode's default skills dir.
- `~/.local/share/opencode/auth.json` — provider keys, secrets never enter Nix.

Everything else in `~/.config/opencode/plugin{,s}/` is deleted on every deploy by `home.activation.opencodePlugins` in `default.nix`, which keeps only the Nix-managed `opencode-parity.js` and the `supacode-presence.js` exception above. That directory is auto-loaded wholesale, so a stray file is not inert: `crg-plugin.ts` (broken against the 1.18.21 plugin API, `app.on is not a function`, and duplicating the `code-review-graph` MCP server now declared in `config.nix`) kept coming back from a Supacode tool and crashed startup each time. The activation script is the thing that keeps it gone.

`~/.config/opencode/{package.json,node_modules,...}` used to be deleted by the same activation step as leftovers of an old bun/npm bootstrap, but current opencode background-installs `@opencode-ai/plugin` into the config dir and re-creates them on every startup, so the prune was a fight the deploy always lost and it is gone. They are expected to exist; `opencode-parity.js` still imports nothing from them by design.

## The plugin-to-skill bridge

Claude Code installs skills inside plugins (marketplace installs live under
`~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/skills/<name>/`), and
typing the same skill names twice — once for Claude, once for opencode — was
exactly the repetition to avoid. Two mechanisms close that gap:

1. **Global bridge** (`home.activation.opencodePlugins` in `default.nix`): every
   deploy walks `~/.claude/plugins/cache` only (never `marketplaces/`, those are
   full repo clones whose skills belong to plugins that may never have been
   installed), finds each `skills/` directory, and symlinks every skill dir
   into `~/.config/opencode/skills/` (`ln -sfn`, last plugin wins when two
   plugins ship the same skill name — `frontend-design` exists in three
   caches). A destination that is a real directory (tool-installed) is skipped,
   BSD `ln -sfn` onto a real dir would nest a junk symlink inside it. The same
   step creates the skills dir if missing and prunes any stale bridge symlink
   (one pointing into `~/.claude/plugins` whose target is gone, one under
   `marketplaces/`, or one whose plugin is not in the bridged set). opencode's
   default skills scan picks the links up from there. A plugin updated by
   Claude Code keeps the same symlink valid because the link points at the
   versioned cache path; a re-install that bumps the version refreshes the
   link on the next deploy.

   Two filters decide what is bridged, both in `default.nix`:
   `home.ai.plugins` is the source (only enabled plugins bridge), and
   `opencodeBridgeExclude` subtracts seven plugins kept for Claude Code but
   excluded from the opencode bridge — `figma`, `mattpocock-skills`,
   `superpowers`, `ponytail`, `caveman`, `web-quality-skills`, `frontend-slides` —
   because opencode never loaded any of their skills (ponytail/caveman are
   hook-driven in Claude only). The exclusion only stops the symlink.
2. **Project-local discovery** (`opencode-parity.js`, `config` hook): the
   plugin reads `.claude/settings.json` and `.claude/settings.local.json` in
   the project and appends any `skills` entry paths to `skills.paths`, so a
   project that declares skills for Claude gets them in opencode without any
   extra config. History: this originally registered a `session.start` hook,
   which does not exist in opencode's plugin API (valid hooks are `event`,
   `config`, `chat.*`, `tool.execute.*`, `permission.ask`, `experimental.*`),
   so both this bridge and the crg-autobuild trigger were silently dead — no
   warning logged, the hook simply never fired. crg-autobuild now rides the
   `event` hook filtered on `session.created`; this bridge rides `config`,
   the one hook that can mutate the loaded config. Separately, the relative
   `.claude/skills` entry in `skills.paths` (config.nix) restores plain
   project-local skill-directory discovery, which
   `OPENCODE_DISABLE_EXTERNAL_SKILLS=1` also disables.

The bridge carries skills only, a known limit rather than a bug: agents and
commands a Claude plugin ships are not bridged, so a plugin's subagents and
slash commands exist only on the Claude side.

Known collision source: `skills.paths` also loads `~/.claude/skills`, so a name
that exists both as a standalone skill there and inside a plugin yields a
duplicate-skill warning. `scripts/verify-opencode.sh` counts those warnings
only from the last deploy's timestamp onwards, so old-log noise does not mask
the live state.

## Agents and commands

Same two-direction deploy contract as Claude's agents (a build-time assertion
in `default.nix` fails `nix flake check` when a file and its name list drift
apart), but opencode-native:

| Agent | Model tier | Role |
|-------|-----------|------|
| `orchestrator` (default primary) | default | Plans, dispatches subagents, relays and verifies. File work is delegated, never inline |
| `code-reviewer` | default | Reviews a diff, branch or PR in one isolated context |
| `dev-lifecycle` | best | Full lifecycle in one context: recon, plan, implement, test, commit, push, draft PR. `steps = 150` for long runs |
| `vault-lint` / `vault-search` | fast | Obsidian vault health check / content lookup, both read-only with `task`/`webfetch`/`websearch`/`skill` denied so they can never fan out |
| `council-*` seats + peer review | one model family each | Hidden subagents, only invoked by `/council` |

Slash commands, deployed as managed files in `~/.config/opencode/commands/`:

| Command | Runs |
|---------|------|
| `/council` | The five-advisor multi-model council on a question |
| `/deploy` | `./nix.sh macbook` |
| `/doctor` | `./scripts/deploy-doctor.sh macbook` — preview what the next deploy deletes |
| `/nixcheck` | `nix fmt && nix flake check` |
| `/verify-setup` | `./scripts/verify-opencode.sh` — the full verification suite below |

## Deliberately not ported

`delegate-nudge` and `force-delegation` are Claude-only: per-turn counters over a hook stream opencode has no equivalent for. They used to reconstruct a boundary opencode enforced statically, the `orchestrator` agent's `edit: deny`. That permission is gone: `orchestrator` allows `edit` and `bash` like every other opencode agent (see Permission defaults above), so there is no static enforcement left to reconstruct. opencode's permission schema also has no per-turn counter to express Claude's grace-allowance-then-hard-deny shape, only a static allow/ask/deny per key, so even a reintroduced `edit: deny` on `orchestrator` could not express "allow the first two". The delegation boundary on opencode is convention now, stated in the generated `AGENTS.md` and nowhere else, not a permission the harness holds it to. The per-turn delegation reminder that used to live in `opencode-parity.js` stays gone, for the same reason it always did: no hook stream to count turns over.

`block-ai-attribution.sh` is now invoked directly: `opencode-parity.js`'s `tool.execute.before` pipes candidate bash commands into the deployed `~/.claude/hooks/block-ai-attribution.sh` with the same PreToolUse JSON payload Claude sends, and throws the script's deny reason so opencode blocks the call (fail open on any script failure). The script owns all the regexes, so `gh pr create|edit|comment|review` and `gh api` bodies are guarded on the opencode side too, not just commits. Below both harnesses, `.hooks/commit-msg` in this repo still rejects co-author trailers and AI attribution in commit messages, covering a plain terminal with no harness API involved; its regex mirrors `block-ai-attribution.sh` exactly, so neither catches a `claude.ai/code/session_*` link, which is a session reference rather than an attribution.

`biome-fix.sh` is replaced by the `formatter` block in `config.nix`. opencode ships a built-in biome formatter that runs `biome format --write $FILE` on an edited file, gated on finding `biome.json`/`biome.jsonc` up-tree and resolving `@biomejs/biome` in the project, so it stays silent everywhere else. It formats but does not apply lint fixes, the one behavioural difference from Claude's `biome check --write`. Overriding `formatter.biome.command` to get `check` back would replace that gate with an unconditional run, so it stays as-is.

The gates are not uniform across the built-ins, which is why the config is an object rather than `true`. Config-file-gated formatters (biome via `biome.json`, prettier via a `package.json` dep, oxfmt, ruff, pint, ocamlformat, clang-format) stay on: they no-op until a project opts in. Every formatter whose only gate is `which <bin>` on `PATH` is switched off, because it would otherwise reformat a file here with conventions this repo never opted into (this repo formats `.nix` with alejandra, not `nixfmt`). The disabled set was read off opencode 1.18.21's built-in registry: `air`, `cljfmt`, `dart`, `dfmt`, `gleam`, `gofmt`, `htmlbeautifier`, `ktlint`, `latexindent`, `mix`, `nixfmt`, `ormolu`, `rubocop`, `rustfmt`, `shfmt`, `standardrb`, `terraform`, `zig`. `uv` is `PATH`-only too but left on, because opencode drops `ruff` whenever `uv` is disabled. The object form registers every built-in and then applies the overrides, so the rest, biome included, stay enabled.

## Opting a project into playwright

`playwright` is not a global MCP server: 25 browser tools (~5.3k tokens of schema) would ride in the system prompt of every request, in every repo, for a capability only some projects need. Declare it in a project-root `opencode.json` instead, and opencode merges it with the global config for that directory only:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "playwright": {
      "type": "local",
      "command": ["npx", "-y", "@playwright/mcp", "--isolated", "--headless"],
      "enabled": true,
      "timeout": 20000
    }
  }
}
```

Verified against 1.18.31: `opencode mcp list` in a directory holding that file reports the project server alongside the global ones. No permission rule is needed, because opencode's built-in default ruleset is `{"*":"allow", doom_loop:"ask", ...}` and an MCP tool with no rule of its own matches that `*` (confirmed empirically: 319 completed MCP calls, zero permission rows). Add the file to the project's `.gitignore` if it is personal, or commit it if the team wants it.

The same pattern works for any other server that only some repos need. Keep the global set to the servers every session benefits from, since each one's schema is paid on every request.

## The npx skills tree

`~/.agents/skills` (the `npx skills` tree) is deliberately in use again, opencode only. `skills.nix` installs into it, and `config.nix`'s `skills.paths` lists it alongside `~/.claude/skills` so opencode loads both; Claude never reads this directory. The two skills Claude used to symlink out of it are unaffected: `orchestration` and `orca-cli` are managed by Orca's own updater now (see [ai-setup.md](ai-setup.md)), and `find-skills` was dropped, whose whole job was promoting `npx skills add`. Orca-sourced skills (`stablyai/orca`) — `orchestration`, `orca-cli`, and `computer-use` — are preserved by `home.ai.opencodeSkillsExternalSources`, which the reconcile treats as owned alongside `home.ai.opencodeSkillsSources`.

The source list is empty by measurement (2026-09-21): every source the tree ever carried (`vercel-labs/agent-skills`, `biomejs/biome`, `mindrally/skills`, `vercel/turborepo`, `remotion-dev/skills` — 23 skills, ~1.2k tokens of description in every request) recorded zero skill loads across all sessions; only Orca-sourced skills were ever loaded, and those stay via `home.ai.opencodeSkillsExternalSources`. The install loop is therefore a no-op until a source is re-added to `home.ai.opencodeSkillsSources` (the manifest hash changes with the list, so the stamp never masks it), and the reconcile step prunes the orphaned directories on the next deploy because the personal role sets `opencodeSkillsPrune = true`. Re-add a source only with evidence its skills get used — every skill in this tree is paid for in every opencode request, used or not.

`home.activation.opencodeSkillsReconcile` runs after install and diffs `~/.agents/skills` against `.skill-lock.json`'s per-skill `source` field (one source can produce several skill directories, so this matches on that field rather than the source list directly). Any directory the current sources don't own gets listed; `home.ai.opencodeSkillsExternalSources` (default `["stablyai/orca"]`) is merged into the owned set so Orca-installed skills survive. `home.ai.opencodeSkillsPrune` still defaults to `false` in `skills.nix`, which only prints the stale list and the exact `rm -rf` command to run by hand, but `home/roles/personal/opencode/default.nix` sets it to `true` for the personal role, so on this machine the reconcile step deletes those directories on every deploy instead of only printing them.

At the time this mechanism was added, the tree already held 291 stale skill directories dated July/August, none of them backed by a declared source, left over from before `skills.nix` existed. They surfaced in the reconcile step's stale-directory list until the personal role's prune flag deleted them; `docs/agents-skills-pre-prune.tsv` records the path and source of every directory as it stood right before that deletion, so the pruned set stays recoverable.

## Verification

After `./nix.sh macbook`:

0. `./scripts/verify-opencode.sh` (or `/verify-setup` inside opencode): one
   command for the whole checklist below — binaries, MCP servers, provider
   auth, managed files, plugin-bridge symlinks, and post-deploy log health.
   Read-only; warnings don't fail, failures do.
1. `opencode` starts with no plugin errors in `~/.local/share/opencode/log/opencode.log`
2. On a fresh machine, run `opencode` and `/connect` the Ollama Cloud provider, or every model call fails; `./scripts/deploy-doctor.sh macbook` warns when the `ollama-cloud` entry is missing from `auth.json`
3. Zero `duplicate skill name` warnings in the log (external scans off)
4. `/agents` shows the ported fleet; `@`-autocomplete shows only non-hidden agents
5. `/council <question>` convenes the five seats in one message
6. Skills list equals the repo-deployed set plus the three tool-installed exceptions
7. `~/.agents/skills` holds exactly the Orca-sourced skills (`stablyai/orca` via `home.ai.opencodeSkillsExternalSources`) until a source is re-added to `home.ai.opencodeSkillsSources`; since the personal role sets `opencodeSkillsPrune = true`, unmanaged directories are deleted on deploy rather than only listed, and the reconcile step's pruned-directory print names exactly what it removed

Escape hatches: `OPENCODE_DISABLE_PROJECT_CONFIG=1` skips a broken project
config; `OPENCODE_CONFIG_CONTENT='{"$schema":"https://opencode.ai/config.json"}'`
injects a minimal config. Config is loaded once at startup: quit and restart
opencode after every deploy.