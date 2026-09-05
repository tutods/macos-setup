# opencode Setup

opencode is the second terminal AI harness, **personal machine only** (installed
via `hosts/darwin/macbook/packages.nix`, configured via `home/roles/personal/opencode/`).
The work machine has neither the binary nor the module. Everything Claude reads is
generated from this repo; opencode follows the same rule, sharing instruction
sources with Claude wherever the two harnesses agree.

## What is shared vs. diverged

| Mechanism | Claude | opencode |
|-----------|--------|----------|
| Always-on instructions | `~/.claude/rules/workflow.md`, concatenated from `home/common/ai/instructions/` | `~/.config/opencode/AGENTS.md`, generated from the same `shared-instructions.md` + `model-quality.md` + `learned-rules.md`, plus `opencode-delegation.md` and `opencode-models.md` |
| Delegation contract | `instructions/delegation.md` + `UserPromptSubmit` hook | `agents/orchestrator.md` (the default primary, full-auto permissions same as every other agent) + the same contract in the generated `AGENTS.md`, convention only, not enforced by any permission |
| Skills | `~/.claude/skills/` (deployed copies) | `~/.claude/skills` plus `~/.agents/skills` (the `npx skills add` tree, see below), both listed in `skills.paths` after `OPENCODE_DISABLE_EXTERNAL_SKILLS=1` kills both external scans |
| Subagents | `~/.claude/agents/*.md` | `~/.config/opencode/agents/*.md` (ported: orchestrator, code-reviewer, dev-lifecycle, vault-lint, vault-search) |
| Council | Workflow tool, `llm-council.js` | `/council` command + hidden model-seat agents (no workflow engine exists) |
| MCP servers | merged into `~/.claude.json` | declared in `opencode.json` (Nix owns the file wholesale) |
| Vault context | `SessionStart` hook | `experimental.chat.system.transform` in the plugin |
| Statusline | `statusline.sh` | no equivalent, dropped |
| Plugins/marketplaces | `home.ai.plugins` | no marketplace mechanism, dropped |
| Format on edit | `biome-fix.sh` on `PostToolUse` | `formatter` in `config.nix`, opencode's built-in formatters with every `$PATH`-only-gated one switched off |
| Bash auto-rewrite | `rtk-rewrite` on `PreToolUse:Bash` | `opencode-parity.js`'s `tool.execute.before`, pipes the command through `rtk hook claude` (rtk has no `opencode` hook subcommand, and the old `rtk rewrite` subcommand is gone) and swaps in the rewrite when stdout is non-empty |
| Secret deny-list | `permissions.deny` in `home/common/ai/settings.nix` | `permission.read` and `permission.bash` deny globs in `config.nix`, generated from the same paths |
| Permission defaults | curated per-tool allow/ask/deny in `settings.nix`, most bash commands prompt | full-auto: top-level permission sets `edit`/`webfetch`/`websearch = "allow"` and `bash` allow-all; `orchestrator`'s own block repeats the same `edit`/`bash`/`read` shape (it inherits `webfetch`/`websearch` from the top level), held back only by the secret-path denies above |
| Co-author / AI attribution block | `block-ai-attribution.sh` on `PreToolUse` | `.hooks/commit-msg`, one layer below both harnesses; commit messages only, `gh` PR and review bodies are not guarded on the opencode side |
| Additional directories | `permissions.additionalDirectories = ["~/Obsidian"]` | `~/Obsidian` in the `filesystem` MCP server args, alongside `~/.dotfiles` and `~/Developer` |
| Council entry point | Workflow tool | `/council` command bound to the `council-chair` primary agent (coordination only: `edit`/`bash` denied, `task` allowed), not the general `orchestrator` |
- **Delegation depth**: `subagent_depth = 2` in `config.nix` allows orchestrator $\rightarrow$ subagent $\rightarrow$ subagent. `/council` fans its seats out directly from the chair.

Models come from Ollama Cloud (`provider/model` ids, API key in
`~/.local/share/opencode/auth.json`, never in Nix). The tier table
(fast/default/best) and the six council seats are in
`instructions/opencode-models.md`, machine-readable in `config.nix`, change both together.

## Files

| Path | Role |
|------|------|
| `home/roles/personal/opencode/default.nix` | composition, AGENTS.md generation, agent/command/plugin deploys |
| `home/roles/personal/opencode/config.nix` | `opencode.json` (models, agents, permissions, MCP, skills.paths) |
| `home/roles/personal/opencode/skills.nix` | installs the `npx skills add` sources with no Claude marketplace.json into `~/.agents/skills`, opencode only |
| `home/roles/personal/opencode/agents/` | orchestrator + 4 ported subagents |
| `home/roles/personal/opencode/commands/council.md` | the `/council` fan-out |
| `home/roles/personal/opencode/plugins/opencode-parity.js` | vault index in the system prompt, the one Claude hook with no opencode config key |
| `home/roles/personal/opencode/instructions/` | opencode-specific deltas folded into AGENTS.md |

## Documented exceptions (out-of-band content)

Same posture as Orca's hook events in `~/.claude/settings.json`: left alone,
listed here so a future cleanup finds them.

- `~/.config/opencode/plugins/supacode-presence.js` — Supacode-generated, marked do-not-edit.
- `~/.config/opencode/skills/{graphify,supacode-cli,supacode-deeplinks}` — installed by their own tools, still scanned via opencode's default skills dir.
- `~/.local/share/opencode/auth.json` — provider keys, secrets never enter Nix.

Everything else in `~/.config/opencode/plugin{,s}/` is deleted on every deploy by `home.activation.opencodePlugins` in `default.nix`, which keeps only the Nix-managed `opencode-parity.js` and the `supacode-presence.js` exception above. That directory is auto-loaded wholesale, so a stray file is not inert: `crg-plugin.ts` (broken against the 1.18.21 plugin API, `app.on is not a function`, and duplicating the `code-review-graph` MCP server now declared in `config.nix`) kept coming back from a Supacode tool and crashed startup each time. The activation script is the thing that keeps it gone.

The same activation step also deletes `~/.config/opencode/{package.json,package-lock.json,bun.lock,node_modules}` if they reappear. An old bun/npm bootstrap left them pinning a stale `@opencode-ai/plugin` against the running binary; nothing in this config imports from that tree (`opencode-parity.js` is import-free by design), so it is removed rather than left to drift.

## The plugin-to-skill bridge

Claude Code installs skills inside plugins (marketplace installs live under
`~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/skills/<name>/`), and
typing the same skill names twice — once for Claude, once for opencode — was
exactly the repetition to avoid. Two mechanisms close that gap:

1. **Global bridge** (`home.activation.opencodePlugins` in `default.nix`): every
   deploy walks the plugin cache, finds each `skills/` directory, and symlinks
   every skill dir into `~/.config/opencode/skills/` (`ln -sfn`, last plugin
   wins when two plugins ship the same skill name — `frontend-design` exists in
   three caches). opencode's default skills scan picks them up from there. A
   plugin updated by Claude Code keeps the same symlink valid because the link
   points at the versioned cache path; a re-install that bumps the version
   refreshes the link on the next deploy.
2. **Project-local discovery** (`opencode-parity.js`, `session.start`): when a
   session starts, the plugin reads `.claude/settings.json` and
   `.claude/settings.local.json` in the project and registers any `skills`
   entries into the session, so a project that declares skills for Claude gets
   them in opencode without any extra config.

Known collision source: `skills.paths` also loads `~/.claude/skills`, so a name
that exists both as a standalone skill there and inside a plugin yields a
duplicate-skill warning. `scripts/verify-opencode.sh` counts those warnings
only from the last deploy's timestamp onwards, so old-log noise does not mask
the live state.

## Deliberately not ported

`delegate-nudge` and `force-delegation` are Claude-only: per-turn counters over a hook stream opencode has no equivalent for. They used to reconstruct a boundary opencode enforced statically, the `orchestrator` agent's `edit: deny`. That permission is gone: every opencode agent, orchestrator included, now runs full-auto (see Permission defaults above), so there is no static enforcement left to reconstruct. The delegation boundary on opencode is convention now, stated in the generated `AGENTS.md` and nowhere else, not a permission the harness holds it to. The per-turn delegation reminder that used to live in `opencode-parity.js` stays gone, for the same reason it always did: no hook stream to count turns over.

`block-ai-attribution.sh` moved down a layer instead of being ported: `.hooks/commit-msg` in this repo rejects co-author trailers and AI attribution in the message, which covers Claude, opencode and a plain terminal with no harness API involved. Two deliberate limits. It sees commit messages only, so the `gh pr create|edit|comment|review` and `gh api` bodies the Claude hook also guards are unguarded when opencode drives them. And its regex mirrors `block-ai-attribution.sh` exactly, so it does not catch a `claude.ai/code/session_*` link, which is a session reference rather than an attribution.

`biome-fix.sh` is replaced by the `formatter` block in `config.nix`. opencode ships a built-in biome formatter that runs `biome format --write $FILE` on an edited file, gated on finding `biome.json`/`biome.jsonc` up-tree and resolving `@biomejs/biome` in the project, so it stays silent everywhere else. It formats but does not apply lint fixes, the one behavioural difference from Claude's `biome check --write`. Overriding `formatter.biome.command` to get `check` back would replace that gate with an unconditional run, so it stays as-is.

The gates are not uniform across the built-ins, which is why the config is an object rather than `true`. Config-file-gated formatters (biome via `biome.json`, prettier via a `package.json` dep, oxfmt, ruff, pint, ocamlformat, clang-format) stay on: they no-op until a project opts in. Every formatter whose only gate is `which <bin>` on `PATH` is switched off, because it would otherwise reformat a file here with conventions this repo never opted into (this repo formats `.nix` with alejandra, not `nixfmt`). The disabled set was read off opencode 1.18.21's built-in registry: `air`, `cljfmt`, `dart`, `dfmt`, `gleam`, `gofmt`, `htmlbeautifier`, `ktlint`, `latexindent`, `mix`, `nixfmt`, `ormolu`, `rubocop`, `rustfmt`, `shfmt`, `standardrb`, `terraform`, `zig`. `uv` is `PATH`-only too but left on, because opencode drops `ruff` whenever `uv` is disabled. The object form registers every built-in and then applies the overrides, so the rest, biome included, stay enabled.

## The npx skills tree

`~/.agents/skills` (the `npx skills` tree) is deliberately in use again, opencode only. `skills.nix` installs into it, and `config.nix`'s `skills.paths` lists it alongside `~/.claude/skills` so opencode loads both; Claude never reads this directory. The two skills Claude used to symlink out of it are unaffected, both are fetched from upstream at build time now (`orchestration`, `orca-cli`; see `mkFetchedSkills` in [ai-setup.md](ai-setup.md)) or dropped (`find-skills`, whose whole job was promoting `npx skills add`).

The sources installed are the ones in [dropped-skill-sources.md](dropped-skill-sources.md) with no `.claude-plugin/marketplace.json`, so they can never become a Claude Code plugin: `vercel-labs/agent-skills`, `biomejs/biome`, `mindrally/skills`, `vercel/turborepo`, `remotion-dev/skills`. `home.activation.opencodeSkillsInstall` runs `npx -y skills@latest add <src> -g -a opencode -s '*' -y --copy` for each, gated by a `command -v npx` check (skips with a warning if missing) and a manifest-hash stamp at `~/.agents/.skill-sources-hash`, so an unchanged source list skips the install loop entirely on redeploy.

`home.activation.opencodeSkillsReconcile` runs after install and diffs `~/.agents/skills` against `.skill-lock.json`'s per-skill `source` field (one source can produce several skill directories, so this matches on that field rather than the source list directly). Any directory the current sources don't own gets listed. `home.ai.opencodeSkillsPrune` still defaults to `false` in `skills.nix`, which only prints the stale list and the exact `rm -rf` command to run by hand, but `home/roles/personal/opencode/default.nix` sets it to `true` for the personal role, so on this machine the reconcile step deletes those directories on every deploy instead of only printing them.

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
7. `~/.agents/skills` holds a directory for each source declared in `skills.nix` (cross-check `~/.agents/.skill-lock.json`); since the personal role sets `opencodeSkillsPrune = true`, unmanaged directories are deleted on deploy rather than only listed, and the reconcile step's pruned-directory print names exactly what it removed

Escape hatches: `OPENCODE_DISABLE_PROJECT_CONFIG=1` skips a broken project
config; `OPENCODE_CONFIG_CONTENT='{"$schema":"https://opencode.ai/config.json"}'`
injects a minimal config. Config is loaded once at startup: quit and restart
opencode after every deploy.