# AI Setup

This repo manages all AI tooling declaratively via Nix + Home Manager.

---

## Tools Installed

Managed in `modules/packages/development.nix` (system-wide, both machines):

| Tool | Purpose |
|------|---------|
| `claude-code` | The AI coding assistant (CLI) |
| `ollama` | Local/offline models (no network, no logs) |
| `repomix` | Pack repo into AI-readable file |
| `rtk` | Token proxy — reduces LLM token usage 60–90% |
| `pipx` | Installs `code-review-graph`, `ttok` post-deploy |

### When to use which tool

- `claude-code` — every coding task; full context, skills, plugins, MCP servers
- `ollama` — offline/private work (no network, no logs) — see [ai-privacy.md](ai-privacy.md)
- `repomix` — pack repo context before sharing with a non-Claude AI; see [repomix.md](repomix.md)

### Model selection

| Tier | Model | Use when |
|------|-------|----------|
| fast | `claude-haiku-4-5-20251001` | mechanical changes, isolated functions, 1–2 files |
| default | `claude-sonnet-4-6` | standard multi-file work, integration tasks |
| best | `claude-opus-4-6` | architecture, design reviews, complex reasoning |

#### Ollama (local/private)

| Tier | Model | Use when |
|------|-------|----------|
| fast | `ollama/qwen2.5-coder:7b` | offline quick edits, no network |
| default | `ollama/qwen2.5-coder:32b` | offline multi-file coding |

See [ai-privacy.md](ai-privacy.md) for when to prefer local models.

### repomix

Config at `.dotfiles/repomix.config.json`. From the dotfiles root:

```bash
repomix   # → /tmp/dotfiles-context.md
```

### ttok

```bash
cat src/bigfile.ts | ttok        # count tokens in a file
git diff | ttok                  # count tokens in a diff
```

---

## AI Instructions

Instructions are split by scope and deployed by `home/common/cli/ai/instructions/default.nix`.

| File | Deployed to | Purpose |
|------|------------|---------|

| `instructions/shared-instructions.md` | `~/.claude/rules/workflow.md` | Fast CLI prefs, git conventions, Nix dotfiles guide |
| `home/roles/personal/ai/instructions.md` | appended (personal machine) | Doppler secrets management, AI privacy guard |
| `home/roles/work/ai/instructions.md` | appended (work machine) | Work context (GCP, Jira, company tools) |

Role-specific instructions are set via `home.ai.extraInstructions` (defined in `options.nix`).

See [work-setup.md](work-setup.md) for the full work environment setup.

---

## Claude Code Settings

Managed by `home/common/cli/ai/tools/claude/settings.nix` via `home.activation.claudeSettings`.

Written to `~/.claude/settings.json` on every `darwin-rebuild switch`.

### Plugin merge strategy

- **Live file wins for unmanaged plugins** — plugins added via `claude plugin add` in the UI are preserved.
- **Nix wins for declared keys** — keys in `enabledPlugins` attrset override the live file.
- **Explicit purge** — removed plugins are deleted from the live file via `jq del()` on every deploy, so old machines migrate cleanly. New machines never see the deleted keys.

`settings.nix` does not hold the plugin list itself — it renders `extraKnownMarketplaces` and `enabledPlugins` from `home.ai.marketplaces` / `home.ai.plugins`. See [Skills](#skills) for where those are declared and how to add one.

To remove a plugin permanently: drop it from the relevant `home.ai.plugins` list and add it to the `del()` call in the activation script, so machines that already installed it are cleaned up.

### Hooks

| Hook | Trigger | Action |
|------|---------|--------|
| `PreToolUse` | Any `Bash` call | `~/.claude/hooks/block-ai-attribution.sh` — rejects AI attribution in commits/PRs |
| `PostToolUse` | `Edit`, `Write`, `MultiEdit` | Run `biome check --write` if `biome.json`/`biome.jsonc` exists in CWD |

The biome hook is a no-op when biome is not configured in the project. Falls back to `./node_modules/.bin/biome` if not in PATH.

---

## MCP Servers

Base servers managed in `home/common/cli/ai/mcp-servers.nix`, deployed by `tools/claude/mcp.nix`.

| Server | Scope | Purpose |
|--------|-------|---------|
| `filesystem` | both | Read/write files beyond CWD |
| `github` | both | Access PRs, issues, repos |
| `playwright` | both | Browser automation and testing |
| `jira` | work | Jira + Confluence via `mcp-atlassian` |

### GitHub MCP — token setup

The GitHub server reads `GITHUB_PERSONAL_ACCESS_TOKEN` from env. The wrapper maps `GITHUB_TOKEN → GITHUB_PERSONAL_ACCESS_TOKEN` at spawn.

1. Create token: <https://github.com/settings/tokens/new>
   - Scopes: `repo`, `read:org`, `read:user`
   - Preferred: fine-grained token per org

2. Add to `~/.config/fish/secrets.fish`:
   ```fish
   set -gx GITHUB_TOKEN "ghp_xxxxxxxxxxxxxxxxxxxx"
   ```

### Jira MCP — work machine only

Managed via `home.ai.extraMcpServers.jira` in `home/roles/work/ai/default.nix`. Uses `mcp-atlassian` npm package.

Requires env vars in `~/.config/fish/secrets.fish` (work machine only):

```fish
set -gx JIRA_URL       "https://<company>.atlassian.net"
set -gx JIRA_EMAIL     "daniel.a.sousa@<company>.com"
set -gx JIRA_API_TOKEN "<token>"
```

Generate token at: <https://id.atlassian.com/manage-profile/security/api-tokens>

See [work-setup.md](work-setup.md) for the full Jira setup flow.

### Config file locations

| File | Tool | Managed by |
|------|------|-----------|
| `~/.claude/claude_desktop_config.json` | Claude Code CLI | Nix activation (merge) |

Merge strategy: Nix adds/updates managed servers; manually added servers are preserved.

---

## Skills

Skills come from exactly two places. Nothing installs them out of band — there is no sync script, no manifest, and no `npx skills`.

### External skills — Claude Code plugin marketplaces

Declared in Nix, written into `~/.claude/settings.json` as `extraKnownMarketplaces` + `enabledPlugins`. Claude Code installs them itself on next launch.

| Declared in | Scope |
|-------------|-------|
| `home/common/cli/ai/tools/claude/plugins.nix` | both machines |
| `home/roles/personal/ai/default.nix` | personal only |
| `home/roles/work/ai/default.nix` | work only |

Both levels use the same two options, which merge across modules:

```nix
home.ai.marketplaces = { <key> = "<owner>/<repo>"; };   # key chosen here, not read from the repo
home.ai.plugins      = [ "<plugin>@<key>" ];
```

The marketplace key is the identifier used on the right of `@`. Keep it stable — renaming it orphans every plugin already installed under the old name.

#### Adding a source

Plugins are coarser-grained than skills: one plugin usually ships several. To wire up a skill you want:

```bash
# 1. Confirm the repo is a marketplace
git clone --filter=blob:none --no-checkout --depth 1 https://github.com/<owner>/<repo> /tmp/probe
git -C /tmp/probe cat-file -e HEAD:.claude-plugin/marketplace.json || echo "not a marketplace — cannot install as a plugin"

# 2. Find the plugin whose `source` dir contains skills/<skill-you-want>/
git -C /tmp/probe show HEAD:.claude-plugin/marketplace.json | jq -r '.plugins[] | "\(.name)\t\(.source)"'
git -C /tmp/probe ls-tree -r --name-only HEAD | grep '<skill-you-want>/SKILL.md'
```

Then add the marketplace + plugin and run `./nix.sh <config>`.

A repo with no `.claude-plugin/marketplace.json` cannot be installed this way. See [dropped-skill-sources.md](dropped-skill-sources.md) for the sources dropped for that reason when this repo migrated off `npx skills`, and for how to re-check them.

`claude-plugins-official` ships with Claude Code — its plugins are listed, but it needs no marketplace entry.

### Custom skills — in-repo sources

| Path | Scope |
|------|-------|
| `skills/local/` | both roles — `llm-council`, `content-writer`, `ts-strict-audit`, `conventional-commit`, `open-pr`, `deep-review`, `ui-iterate`, `nestjs-best-practices`, `find-skills` |
| `home/roles/personal/ai/skills/local/` | personal — `elementor-crocoblock`, `optimize-images` |
| `home/roles/work/ai/skills/local/` | work — `acli` |

Two are vendored rather than written here, because their upstreams are plain skill repos with no plugin marketplace. Both are MIT and record `vendored-from` in their SKILL.md frontmatter:

| Skill | Upstream |
|-------|----------|
| `nestjs-best-practices` | `kadajett/agent-nestjs-skills` |
| `find-skills` | `oakoss/agent-skills` |

Note that `find-skills` can *install* what it finds, straight into `~/.claude/skills/`. Don't let it — anything it drops there is outside Nix and gets flagged by the deploy's leftover audit. Use it to discover, then declare the plugin in Nix.

Installed by `lib/ai.nix:mkLocalSkills` as **real, writable directories** under `~/.claude/skills/` — a plain `cp -R`, not a `home.file` symlink into the Nix store, because Claude Code writes inside a skill directory. `~/.agents/` is not used.

Each deploy replaces the directory, so edits made directly in `~/.claude/skills/` are lost — change the repo source instead.

To add one: create `skills/local/<name>/SKILL.md`, add `<name>` to the `names` list in `skills/default.nix`, run `./nix.sh <config>`.

#### Leftovers from `npx skills`

`~/.claude/skills/` used to hold everything the old manifests installed. Those directories are still on disk after the migration and now shadow copies that ship inside plugins. Every deploy lists any directory it doesn't own and prints the `rm -rf` line to clear them — it never deletes on its own, since a stray directory could be a hand-written skill.

### Stack context files

Deployed to `~/.claude/context/` from `home/common/cli/ai/context/`. @-mention one at the start of a conversation to prime the model on a stack:

| File | Use |
|------|-----|
| `@context/stack-personal` | Personal: TanStack Start, Next.js, Tailwind, shadcn/ui, Postgres, Drizzle/Prisma |
| `@context/stack-work` | Work: React/Next.js, MariaDB, NestJS, GCP |
| `@context/stack-nix-dotfiles` | This repo: module hierarchy, commands, conventions |

### Harness built-ins (not installable)

Always available, never declared anywhere:
`update-config`, `loop`, `schedule`, `simplify`, `fewer-permission-prompts`, `keybindings-help`, `statusline-setup`, `init`, `review`, `security-review`, `claude-api`

---

## Initialization (Home Manager Activations)

Managed in `home/common/cli/ai/init.nix`. Runs automatically on every `darwin-rebuild switch`. Each step is guarded — only acts when needed.

| Step | Condition | What it does |
|------|-----------|-------------|
| `pipx install code-review-graph` | not in `pipx list` | Install code-review-graph CLI |
| `pipx install ttok` | not in `pipx list` | Install ttok (LLM token counter) |
| graphify removal | `graphify` still on PATH | One-time: `graphify uninstall` (drops its PreToolUse hook + `~/.claude/skills/graphify/`), then `pipx uninstall graphifyy` |
| `localSkills*` | every switch | Copy custom skills into `~/.claude/skills/` |

---

## Fresh Machine Checklist

After running `./nix.sh <config>` on a new machine:

1. Set up git identity → see [secrets.md](secrets.md)
2. Add secrets to `~/.config/fish/secrets.fish`:
   ```fish
   set -gx GITHUB_TOKEN "ghp_xxx"
   ```
3. **Work machine only** — add Jira MCP secrets:
   ```fish
   set -gx JIRA_URL       "https://<company>.atlassian.net"
   set -gx JIRA_EMAIL     "daniel.a.sousa@<company>.com"
   set -gx JIRA_API_TOKEN "<token>"
   ```
4. Verify Claude Code plugins loaded: `claude` → `/plugin` (marketplaces install on first launch)
5. Verify MCP servers: `claude mcp list`
6. Check custom skills landed: `ls ~/.claude/skills`

See [work-setup.md](work-setup.md) for the complete work machine setup.
