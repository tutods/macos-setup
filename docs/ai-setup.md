# AI Setup

Everything Claude Code reads is generated from this repo. Nothing is installed
out of band, no sync script, no manifest, no `npx skills`.

opencode (personal machine) mirrors this from the same instruction sources:
see [opencode-setup.md](opencode-setup.md).

## Tools

Managed in `modules/packages/development.nix` (system-wide, both machines):

| Tool | Purpose |
|------|---------|
| `claude-code` | The AI coding assistant (CLI) |
| `pipx` | Installs `code-review-graph` post-deploy |
| `rtk` | Rewrite read-only commands to avoid permission prompts |

Model tiers are named in one place only: `instructions/model-selection.md`.

## Instructions (always-on)

Concatenated by `home/common/ai/instructions/default.nix` into
`~/.claude/rules/workflow.md`, loaded in every session.

| File | Purpose |
|------|---------|
| `instructions/delegation.md` | Subagent-first posture, which agent handles what, parallel fan-out |
| `instructions/shared-instructions.md` | CLI preferences, workflow, git, vault pointer, comment rule, destructive-op gates, human-voice writing |
| `instructions/model-quality.md` | Evidence-before-claims, scope guard, plan execution, skill discipline |
| `instructions/learned-rules.md` | Standing rules mined from past corrections |
| `instructions/model-selection.md` | Model tier table |
| `home/roles/<role>/ai/instructions.md` | Appended per role via `home.ai.extraInstructions` |

A file belongs here only if it applies to **every** session regardless of
subject. Anything stack-specific is a skill instead, so it loads on demand.

## Settings

`home/common/ai/settings.nix` merges its keys into `~/.claude/settings.json` on
every deploy via `aiLib.mergeJsonObject`. Nix is authoritative for every key it
declares, including `enabledPlugins`, so dropping a plugin from `home.ai.plugins`
is enough to remove it. A top-level key Nix does not declare (the
push-notification toggle Claude Code writes) is left in place. `hooks` is
stricter: an event Nix declares is replaced wholesale, and a foreign event
survives only if its name is in `keepHookEvents` (the Orca events); every other
foreign event is dropped on deploy, so nothing can leave a hook Nix never
sanctioned. `permissions.allow` is declared so that declared entries persist; any "yes, don't ask again" click writes a rule there that is cleared on every deploy. **Never add
a plugin through the Claude Code UI**; `enabledPlugins` is Nix-owned and the next
deploy drops it.

`permissions.defaultMode` is `auto`, Claude Code's classifier-gated mode: a tool call the classifier judges safe runs without a prompt, anything else still asks, and the deny list is absolute in every mode regardless (secret paths included). It was briefly `full-auto`, which is not a valid value for this key (the valid set is `default`/`manual`, `acceptEdits`, `plan`, `auto`, `dontAsk`, `bypassPermissions`) and raised a Settings Error dialog at session start instead of being silently ignored. The generated `settings.json` also used to carry four blanket allow rules, `Bash(*)`, `Edit(*)`, `Write(*)`, `MultiEdit(*)`; all four are gone. `Bash(*)` is a valid rule and matched every Bash call, which cancelled `auto` mode's classifier gating outright. `Write(*)` and `MultiEdit(*)` were dead weight regardless: Claude Code only consults path rules for `Edit` and `Read`, it accepts a path rule on `Write`/`NotebookEdit`/`MultiEdit`, warns about it at startup, then never applies it. The RTK rewrites of read-only commands stay declared in `permissions.allow` so the rewrite hook does not turn them into prompts; every entry left in that list is an rtk read-only form, with no blanket allow behind them. This diverges from opencode on purpose now: see [opencode-setup.md](opencode-setup.md) for opencode's open-with-a-danger-list posture and the reasoning for the split.

`autoMemoryEnabled` is off, so the harness remembers nothing on its own. The
Obsidian vault is the durable memory, written by the `obsidian-vault` skill and
read by the `vault-search` agent. Nothing injects vault content at session
start (the old `vault-context.sh` title index cost ~3k tokens per session and
was redundant next to `vault-search`); `home.ai.vaultFolders` still declares
the role-scoped folder set, exported as `CLAUDE_VAULT_FOLDERS` in
`settings.json` for `vault-lint`'s scope-coverage check.
Auto-memory stays off because it would add a fixed per-session injection and a second unversioned rules source alongside `~/.claude/rules/`.
`autoCompactEnabled` is true with no context-window override set, so compaction
fires at each session's model-tuned default, see [ai-lessons.md](ai-lessons.md).

### Hooks

| Hook | Trigger | Action |
|------|---------|--------|
| `SessionStart` | Every session | `crg-autobuild.sh`, resolves the git toplevel, exits at once with no repo, no `code-review-graph` binary, or no `.code-review-graph/graph.db` yet (opt a repo in by running `code-review-graph build` once, or the `crgb` abbreviation); once a graph exists it skips when a content stamp (HEAD + `git status --porcelain`, hashed) matches the last successful run — most sessions open on an unchanged tree — otherwise takes an atomic `mkdir` lock so two sessions in one repo can't both start a parse, then backgrounds an `update` under `nice -n 10`, logging to `.code-review-graph/autobuild.log` and re-stamping on success. Never blocks the session. opencode runs the same script from the plugin's `event` hook, filtered on `session.created` (the plugin API has no `session.start` hook). Manual path: `crgb`/`crgu`/`crgs` fish abbreviations for build/update/status |
| `SessionStart`, `PreCompact` | Compaction, and every session start | `compaction-sentinel.sh` latches a per-session sentinel file so the per-prompt reminder below is a single `[ -f ]` test instead of a transcript scan. `PreCompact` latches unconditionally; `SessionStart` latches only when the transcript already carries a `compact_boundary`, so a resumed or forked session keeps the reminder alive under its new id. `PreCompact` and not `PostCompact`: `PostCompact` is in `keepHookEvents` for Orca's own entry, and the deploy merge lets the Nix value win |
| `UserPromptSubmit` | Every prompt after compaction | `delegation-reminder.sh` re-states the Delegation Contract once the sentinel above exists; before that the full contract is already in context and the hook is silent. Forks nothing: the session id is parsed with bash builtins and the payload is a single `printf` |
| `PreToolUse` | Any `Bash` call | `block-ai-attribution.sh`, rejects AI attribution in commits/PRs/reviews |
| `PreToolUse` | Any `Bash` call | `rtk-rewrite.sh`, its own matcher group, wraps `rtk hook claude` to auto-rewrite commands for permission-free read-only ops (silent no-op when `rtk` is absent) |
| `PreToolUse` | `Read`, `Grep`, `Glob` | `delegate-nudge.sh`, counts inline recon calls per turn on the main thread (skips subagents via `agent_id`) and injects a delegation reminder on the sixth inline `Read`/`Grep`/`Glob` in a turn, once per turn |
| `PreToolUse` | `Edit`, `Write` | `force-delegation.sh`, hard gate (not a nudge): allows main-thread mutations to at most 4 distinct files per turn (repeat edits to those files are unlimited) and denies any mutation that would spread to a further file (skips subagents via `agent_id`), forcing multi-file work through a subagent. Turn-boundary logic (agent_id bail, `prompt_id` turn key — no key means allow, never a session-wide fallback — counter dir, 2h GC) is shared with `delegate-nudge.sh` via `hooks/lib/turn-key.sh` |
| `PostToolUse` | `Edit`, `Write` | `biome check --write`, no-op unless the project has a biome config |

## MCP Servers

Declared inline in `home/common/ai/mcp.nix` (shared) and via
`home.ai.extraMcpServers` in a role's `ai/default.nix`.

| Server | Scope | Purpose |
|--------|-------|---------|
| `code-review-graph` | both | Tree-sitter code graph, query structure instead of re-reading files. Needs a per-repo `code-review-graph build` first |
| `shadcn` | personal | shadcn/ui component registry |

Claude Code reads user-scope servers from `~/.claude.json`'s `mcpServers` key,
**not** `claude_desktop_config.json`, which is Claude Desktop's file. Because
Claude Code writes to `~/.claude.json` constantly, the deploy merges rather than
replaces: Nix is authoritative for additions only. Removing a server needs
`claude mcp remove <name> --scope user` once by hand. Deploy with no other
Claude Code session running.

Enabling a plugin also registers any MCP servers in its bundled `.mcp.json`, so
`claude mcp list` shows servers not declared here. Drop the plugin to remove
those.

## Skills

Two sources, and only two.

### External: Claude Code plugin marketplaces

Declared in Nix, written into `~/.claude/settings.json`, installed by Claude
Code on next launch. Declared in `home/common/ai/plugins.nix` (both machines) or
a role's `ai/default.nix` (role only). Two options, which merge across modules:

```nix
home.ai.marketplaces = { <key> = "<owner>/<repo>@<commit sha>"; };   # key chosen here, not read from the repo
home.ai.plugins      = [ "<plugin>@<key>" ];
```

Keep a marketplace key stable, renaming it orphans every plugin already
installed under the old name. `claude-plugins-official` is built into Claude
Code and needs no marketplace entry.

Third-party marketplaces must carry the `@<sha>` pin: their skills execute
locally, and the pin is what stops someone else's next commit from running
here unreviewed. Get the sha with `git ls-remote https://github.com/<owner>/<repo> HEAD`,
review the repo at that commit, and bump pins deliberately the same way.
`verify-plugins.sh` validates each plugin against its pinned commit.
First-party exception: employer-owned private marketplaces (the work role's
`ai-workbench`) are deliberately unpinned — tracking the team's HEAD is the
point, and the trust model is first-party, the same org whose repos and
credentials already live on that machine. The `@sha` rule stays absolute for
third-party repos. Build-time enforcement matches that split: an unpinned
entry is valid, but a malformed pin is not — a pin after the last `@` that is
not a full 40-char lowercase commit sha fails eval outright (a `throw` in
`home/common/ai/settings.nix`) with instructions for fetching the real sha,
because Claude Code would silently accept a branch or tag there as a moving
ref, defeating the pin.

**Every marketplace is a supply-chain trust**: plugins run code and register
skills in every session, and the verification scripts check names, not
behavior. Before adding one, check whether a skill you actually invoked in the
last 30 days needs it (transcripts under `~/.claude/projects/`), and prefer
moving stack- or domain-specific plugins to the project that uses them. The
2026-08 cut dropped the marketplaces no transcript invocation had touched
(social-media-skills, claude-code-workflows, anthropic-agent-skills).

**Machine-wide plugins are generic only**: workflow, writing, debugging,
authoring. Stack- and domain-specific plugins (framework packs, SEO, design
tooling) are enabled per project instead: committed `.claude/settings.json`
where the repo allows it, `.claude/settings.local.json` in team repos and
wherever `settings.json` is gitignored.

Plugins are coarser than skills: one registers *every* skill it ships, plus its
bundled MCP servers. To add a source:

```bash
# 1. Confirm the repo is a marketplace
git clone --filter=blob:none --no-checkout --depth 1 https://github.com/<owner>/<repo> /tmp/probe
git -C /tmp/probe cat-file -e HEAD:.claude-plugin/marketplace.json || echo "not a marketplace"

# 2. Find the plugin whose `source` dir contains skills/<skill-you-want>/
git -C /tmp/probe show HEAD:.claude-plugin/marketplace.json | jq -r '.plugins[] | "\(.name)\t\(.source)"'
git -C /tmp/probe ls-tree -r --name-only HEAD | grep '<skill-you-want>/SKILL.md'
```

A repo without `.claude-plugin/marketplace.json` cannot be installed this way,
see [dropped-skill-sources.md](dropped-skill-sources.md).

**Plugins fail silently**: a typo'd name is written to `settings.json`, Claude
Code installs nothing, and nothing is logged. Always run:

```bash
./scripts/verify-plugins.sh          # every plugin resolves, + the skill count each drags in
./scripts/verify-plugins.sh --quiet  # what CI and the pre-commit hook run
```

When a marketplace repo refuses the script's anonymous clone (a private repo,
e.g. the work role's `ai-workbench`), it falls back to the marketplace Claude
Code already installed locally, checking the plugin name against
`~/.claude/plugins/marketplaces/<mkt>/.claude-plugin/marketplace.json` — and
scans every `/Users/*` home for that file, since on the work machine the deploy
runs as the admin account while Claude Code runs as the user. No clone and no
local install is a failure, not a skip.

### Custom: in-repo sources

Declared in `home/common/ai/skills/default.nix` and the role modules
(`home/roles/{personal,work}/ai/default.nix`); each `names` entry is a directory
under the sibling `skills/local/`. Run `nix flake check` to validate the two
against each other. Some skills are vendored rather than authored here, see each
skill's `vendored-from`.

Installed by `lib/ai.nix:mkLocalSkills` as **real directories** under
`~/.claude/skills/`, copied rather than symlinked so a store permission quirk
can never make one unreadable. Nothing writes inside a deployed skill dir.
Each deploy replaces the directory, so edits made in `~/.claude/skills/` are
lost; change the repo source.

After the copies, `customSkillsReconcile` deletes any real directory in
`~/.claude/skills/` this repo does not declare, so a renamed or removed skill
actually disappears instead of staying loaded.
A symlink under `~/.claude/skills/` is removed too when it does not match a declared name: no Nix-managed skill is ever a symlink there, they are real copied directories, so any symlink found is foreign, most often an `npx skills`-style install pointing at `~/.agents/skills/`.

**Exception: fetched, not committed.** `orchestration` and `orca-cli` come from
`stablyai/orca` and are not vendored into this repo — the same reason
marketplaces are pinned rather than committed applies. Declared via
`lib/ai.nix:mkFetchedSkills` (same "common" import list in
`home/common/ai/skills/default.nix`), which fetches a pinned rev + hash with
`fetchFromGitHub` and copies the named skill directories into
`~/.claude/skills/` at build time, so a fresh machine still gets them from
`./nix.sh` with no skill content in this repo's git history. Bump the pin the
same way as a marketplace: `git ls-remote https://github.com/stablyai/orca HEAD`,
review the diff, update rev + hash together.

## Agents

Custom subagents, Markdown with `name`/`description`/`tools`/`model`
frontmatter, invoked via the Agent tool. In-repo only; there's no plugin channel
for agents.

Declared in `home/common/ai/agents/default.nix`; each `names` entry is a
`<name>.md` under the sibling `agents/local/`. Run `nix flake check` to validate.

Installed by `lib/ai.nix:mkLocalAgents` as `home.file` symlinks into
`~/.claude/agents/<name>.md`. An agent file is read-only input, so a store
symlink is safe, and Home Manager removes it for free when the name leaves the
`names` list.

## Workflows

Deterministic multi-agent scripts for Claude Code's Workflow tool, JS with an
`export const meta` block, using `agent()`/`parallel()`/`pipeline()`. Installed
by `lib/ai.nix:mkLocalWorkflows` as symlinks into `~/.claude/workflows/<name>.js`.

Declared in `home/common/ai/workflows/default.nix`; each `names` entry is a
`<name>.js` under the sibling `workflows/local/`. Run `nix flake check` to validate.

**The boundary between the three.** Skills are knowledge. Agents are judgement
in one isolated context. Workflows are fixed fan-out with deterministic control
flow, parallel perspectives, verification gates. A thin skill can be the
natural-language trigger that invokes a workflow: see `skills/local/llm-council`.

## Adding any of them

Create the file, add its name to the `names` list in the sibling
`default.nix`, then `./nix.sh <config>`:

| Add | Create | Register in |
|-----|--------|-------------|
| Skill | `skills/local/<name>/SKILL.md` | `skills/default.nix` |
| Agent | `agents/local/<name>.md` | `agents/default.nix` |
| Workflow | `workflows/local/<name>.js` | `workflows/default.nix` |

## Initialization

Activation steps that run on every `darwin-rebuild switch`, each guarded so it
only acts when needed:

| Step | Lives in | Condition |
|------|----------|-----------|
| `pipx install code-review-graph` | `home/common/ai/init.nix` | pinned version not in `pipx list` |
| `localSkills-*` | `lib/ai.nix` (`mkLocalSkills`) | every switch: copies in-repo custom skills into `~/.claude/skills/` |
| `fetchedSkills-*` | `lib/ai.nix` (`mkFetchedSkills`) | every switch: copies pinned upstream skills into `~/.claude/skills/` |
| `customSkillsReconcile` | `home/common/ai/skills/default.nix` | every switch: deletes non-symlink dirs in `~/.claude/skills/` this repo does not declare |

## Maintenance

`home/common/ai/maintenance.nix` installs a launchd agent,
`claude-prune-transcripts`, that runs weekly and deletes session transcripts in
`~/.claude/projects/` older than 30 days. That directory has no built-in
eviction and is the largest thing under `~/.claude/`. Output goes to
`~/.claude/prune.log`.

## Fresh Machine Checklist

After `./nix.sh <config>` on a new machine:

1. Set up git identity → see [secrets.md](secrets.md)
2. Add any needed secrets to `~/.config/fish/secrets.fish`
3. Verify plugins loaded: `claude` → `/plugin` (marketplaces install on first launch)
4. Verify MCP servers: `claude mcp list`
5. Check custom skills landed: `ls ~/.claude/skills`

See [work-setup.md](work-setup.md) for the complete work machine setup.
