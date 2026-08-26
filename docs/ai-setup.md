# AI Setup

Everything Claude Code reads is generated from this repo. Nothing is installed
out of band, no sync script, no manifest, no `npx skills`.

## Tools

Managed in `modules/packages/development.nix` (system-wide, both machines):

| Tool | Purpose |
|------|---------|
| `claude-code` | The AI coding assistant (CLI) |
| `pipx` | Installs `code-review-graph` post-deploy |

Model tiers are named in one place only: `instructions/model-selection.md`.

## Instructions (always-on)

Concatenated by `home/common/ai/instructions/default.nix` into
`~/.claude/rules/workflow.md`, loaded in every session.

| File | Purpose |
|------|---------|
| `instructions/shared-instructions.md` | CLI preferences, workflow, git, vault pointer, comment rule, destructive-op gates, human-voice writing |
| `instructions/model-quality.md` | Evidence-before-claims, scope guard, plan execution, skill discipline |
| `instructions/learned-rules.md` | Standing rules mined from past corrections |
| `instructions/delegation.md` | Subagent-first posture, which agent handles what, parallel fan-out |
| `instructions/model-selection.md` | Model tier table |
| `home/roles/<role>/ai/instructions.md` | Appended per role via `home.ai.extraInstructions` |

A file belongs here only if it applies to **every** session regardless of
subject. Anything stack-specific is a skill instead, so it loads on demand.

## Settings

`home/common/ai/settings.nix` rewrites `~/.claude/settings.json` whole on every
deploy, Nix owns the entire file, including `enabledPlugins`. Dropping a plugin
from `home.ai.plugins` is enough to disable it. **Never add a plugin through the
Claude Code UI**; it won't survive the next deploy.

`autoMemoryEnabled` is off, so the harness remembers nothing on its own. The
Obsidian vault is the durable memory, written by the `obsidian-vault` skill and
read by the `vault-search` agent.
Auto-compaction triggers on a percentage of the live context window
(`CLAUDE_AUTOCOMPACT_PCT_OVERRIDE`), not a fixed token count, see
[ai-lessons.md](ai-lessons.md).

### Hooks

| Hook | Trigger | Action |
|------|---------|--------|
| `SessionStart` | Every session | `vault-context.sh`, lists Obsidian note titles so the agent knows what exists. Prompts/ is excluded (a pointer line with a note count stands in), and truncation is folder-aware, it never cuts mid-folder. Bodies come from `vault-search` on demand |
| `UserPromptSubmit` | Every prompt | `delegation-reminder.sh`, generated inline in `settings.nix` from the `delegationReminder` string, re-states the Delegation Contract so it survives a long session |
| `PreToolUse` | Any `Bash` call | `block-ai-attribution.sh`, rejects AI attribution in commits/PRs/reviews |
| `PostToolUse` | `Edit`, `Write`, `MultiEdit` | `biome check --write`, no-op unless the project has a biome config |

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
home.ai.marketplaces = { <key> = "<owner>/<repo>"; };   # key chosen here, not read from the repo
home.ai.plugins      = [ "<plugin>@<key>" ];
```

Keep a marketplace key stable, renaming it orphans every plugin already
installed under the old name. `claude-plugins-official` is built into Claude
Code and needs no marketplace entry.

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

### Custom: in-repo sources

| Path | Skills |
|------|--------|
| `home/common/ai/skills/local/` | `api-conventions`, `content-writer`, `conventional-commit`, `deep-review`, `dependency-hygiene`, `llm-council`, `nix-setup`, `obsidian-vault`, `open-pr`, `unslop`, `pr-feedback`, `react-conventions`, `review-pr`, `testing-conventions`, `ts-conventions`, `ts-strict-audit`, `ui-iterate` |
| `home/roles/personal/ai/skills/local/` | `optimize-images`, `personal-stack` |
| `home/roles/work/ai/skills/local/` | `acli`, `babysit-prs`, `deep-review-prs`, `implement-ticket`, `work-stack` |

Installed by `lib/ai.nix:mkLocalSkills` as **real, writable directories** under
`~/.claude/skills/`, copied, not symlinked into the Nix store, because Claude
Code writes inside a skill directory. Each deploy replaces the directory, so
edits made in `~/.claude/skills/` are lost; change the repo source.

Every deploy also lists directories in `~/.claude/skills/` that this repo
doesn't own and prints the `rm -rf` line. It never deletes on its own, since a
stray directory could be a hand-written skill.

## Agents

Custom subagents, Markdown with `name`/`description`/`tools`/`model`
frontmatter, invoked via the Agent tool. In-repo only; there's no plugin channel
for agents.

| Path | Agents |
|------|--------|
| `home/common/ai/agents/local/` | `code-reviewer`, `dev-lifecycle`, `vault-lint`, `vault-search` |

Installed by `lib/ai.nix:mkLocalAgents` as `home.file` symlinks into
`~/.claude/agents/<name>.md`. An agent file is read-only input, so a store
symlink is safe, and Home Manager removes it for free when the name leaves the
`names` list.

## Workflows

Deterministic multi-agent scripts for Claude Code's Workflow tool, JS with an
`export const meta` block, using `agent()`/`parallel()`/`pipeline()`. Installed
by `lib/ai.nix:mkLocalWorkflows` as symlinks into `~/.claude/workflows/<name>.js`.

| Path | Workflows |
|------|-----------|
| `home/common/ai/workflows/local/` | `llm-council` |

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

`home/common/ai/init.nix`, run on every `darwin-rebuild switch`, each step
guarded so it only acts when needed:

| Step | Condition |
|------|-----------|
| `pipx install code-review-graph` | not in `pipx list` |
| `localSkills*` | every switch: copies custom skills into `~/.claude/skills/` |

## Fresh Machine Checklist

After `./nix.sh <config>` on a new machine:

1. Set up git identity → see [secrets.md](secrets.md)
2. Add any needed secrets to `~/.config/fish/secrets.fish`
3. Verify plugins loaded: `claude` → `/plugin` (marketplaces install on first launch)
4. Verify MCP servers: `claude mcp list`
5. Check custom skills landed: `ls ~/.claude/skills`

See [work-setup.md](work-setup.md) for the complete work machine setup.
