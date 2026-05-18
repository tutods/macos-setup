# AI Setup

This repo manages all AI tooling declaratively via Nix + Home Manager.

---

## Tools Installed

Managed in `modules/packages/development.nix` (system-wide, both machines):

| Tool | Purpose |
|------|---------|
| `claude-code` | Primary AI coding assistant (CLI) |
| `opencode` | Multi-provider terminal AI |
| `codex` | Isolated one-shot scripting tasks |
| `ollama` | Local/offline models (no network, no logs) |
| `repomix` | Pack repo into AI-readable file |
| `rtk` | Token proxy — reduces LLM token usage 60–90% |
| `pipx` | Installs `code-review-graph`, `ttok` post-deploy |

### When to use which tool

- `claude-code` — default for all coding tasks; full context, skills, MCP servers
- `opencode` — multi-provider or when a different model is needed mid-session
- `codex` — isolated throwaway scripts, one-shot shell tasks
- `ollama` — offline/private work (no network, no logs) — see [ai-privacy.md](ai-privacy.md)
- `repomix` — pack repo context before switching tools or sharing with non-Claude AI; see [repomix.md](repomix.md)

### opencode model selection

Switch model mid-session with `Ctrl+M` in opencode without losing context.

#### Anthropic (default)

| Tier | Model | Use when |
|------|-------|----------|
| fast | `claude-haiku-4-5-20251001` | mechanical changes, isolated functions, 1–2 files |
| default | `claude-sonnet-4-6` | standard multi-file work, integration tasks |
| best | `claude-opus-4-6` | architecture, design reviews, complex reasoning |

#### z.AI / GLM (coding plan)

| Tier | Model | Use when |
|------|-------|----------|
| fast | `zhipu/glm-z1-flash` | quick edits, simple lookups, cheap iterations |
| default | `zhipu/glm-4.7` | multi-file TypeScript/frontend work |
| best | `zhipu/glm-5.1` | deep reasoning, architecture, replaces Opus |

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
| `instructions/context7-prefix.md` | `~/.config/opencode/AGENTS.md` (prefix) | context7 CLI usage guide for opencode |
| `instructions/shared-instructions.md` | `~/.config/opencode/AGENTS.md` + `~/.claude/rules/workflow.md` | Fast CLI prefs, git conventions, Nix dotfiles guide |
| `home/roles/personal/ai/instructions.md` | appended to both (personal machine) | Doppler secrets management, AI privacy guard |
| `home/roles/work/ai/instructions.md` | appended to both (work machine) | Work context (GCP, Jira, company tools) |

Role-specific instructions are set via `home.ai.extraInstructions` (defined in `options.nix`).

See [work-setup.md](work-setup.md) for the full work environment setup.

---

## Claude Code Settings

Managed by `home/common/cli/ai/claude/settings.nix` via `home.activation.claudeSettings`.

Written to `~/.claude/settings.json` on every `darwin-rebuild switch`.

### Plugin merge strategy

- **Live file wins for unmanaged plugins** — plugins added via `claude plugin add` in the UI are preserved.
- **Nix wins for declared keys** — keys in `enabledPlugins` attrset override the live file.
- **Explicit purge** — removed plugins are deleted from the live file via `jq del()` on every deploy, so old machines migrate cleanly. New machines never see the deleted keys.

To add a plugin permanently: add it to `enabledPlugins` in `claude/settings.nix`.
To remove a plugin permanently: remove it from `enabledPlugins` and add it to the `del()` call in the activation script.

### Hooks

| Hook | Trigger | Action |
|------|---------|--------|
| `PreToolUse` | Any `Bash` call | `rtk hook claude` — token proxy interception |
| `PostToolUse` | `Edit`, `Write`, `MultiEdit` | Run `biome check --write` if `biome.json`/`biome.jsonc` exists in CWD |

The biome hook is a no-op when biome is not configured in the project. Falls back to `./node_modules/.bin/biome` if not in PATH.

### Custom marketplaces

| Marketplace ID | Repo |
|---------------|------|
| `caveman` | `JuliusBrussee/caveman` |
| `agricidaniel-seo` | `AgriciDaniel/claude-seo` |
| `openai-codex` | `openai/codex-plugin-cc` |

### Enabled plugins

All plugins in `enabledPlugins` are set to `true`. Currently managed:

`caveman`, `superpowers`, `frontend-design`, `code-review`, `code-simplifier`, `github`, `feature-dev`, `claude-md-management`, `typescript-lsp`, `security-guidance`, `commit-commands`, `figma`, `claude-code-setup`, `pr-review-toolkit`, `sourcegraph`, `prisma`, `sanity`, `autofix-bot`, `claude-seo` (agricidaniel-seo), `codex` (openai-codex)

---

## MCP Servers

Base servers managed in `home/common/cli/ai/mcp-servers.nix`, deployed via separate activations for Claude Code and opencode.

| Server | Claude Code | opencode | Purpose |
|--------|:-----------:|:--------:|---------|
| `filesystem` | Yes | Yes | Read/write files beyond CWD |
| `github` | Yes | Yes | Access PRs, issues, repos |
| `playwright` | Yes | Yes | Browser automation and testing |
| `context7` | Yes | Yes | Current library docs (inline MCP, no API key needed) |
| `jira` | Yes (work) | Yes (work) | Jira + Confluence via `mcp-atlassian` |

### GitHub MCP — token setup

The GitHub server reads `GITHUB_PERSONAL_ACCESS_TOKEN` from env. The wrapper maps `GITHUB_TOKEN → GITHUB_PERSONAL_ACCESS_TOKEN` at spawn.

1. Create token: <https://github.com/settings/tokens/new>
   - Scopes: `repo`, `read:org`, `read:user`
   - Preferred: fine-grained token per org

2. Add to `~/.config/fish/secrets.fish`:
   ```fish
   set -gx GITHUB_TOKEN "ghp_xxxxxxxxxxxxxxxxxxxx"
   ```

### context7 MCP — setup

context7 is deployed as a local MCP server (`@upstash/context7-mcp@latest`) on both Claude Code and opencode. No API key is required — the package handles auth internally.

No manual setup needed. The server is active after `./nix.sh <config>`.

To use in sessions: ask about any library and context7 resolves live docs inline.

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
| `~/.config/opencode/opencode.json` (`mcp` key) | opencode | Nix activation (merge) |

Both use a merge strategy: Nix adds/updates managed servers; manually added servers are preserved.

### opencode base config

Static fields (`$schema`, `plugin`, `experimental`, `share`) are managed by Nix via `home.activation.opencodeConfig`. Runs before MCP merge. Nix wins for these fields; the `mcp` key is updated by the MCP activation.

---

## Skills

Managed by `home/common/cli/ai/skills/`.

Two manifests:
- `manifest.txt` — common skills installed on both machines
- `home/roles/personal/ai/skills/manifest.txt` — personal-only skills

### Sync skills

Skills install automatically on every `darwin-rebuild switch`, guarded by a content hash at `~/.config/ai/.skills-sync-hash`. Only re-runs when the manifest changes.

```bash
# Force full reinstall on next deploy
rm ~/.config/ai/.skills-sync-hash && ./nix.sh macbook

# Inspect last install log
cat ~/.cache/ai-skills-install.log

# List installed skills
npx skills ls -g
```

### Skill categories (common — both machines)

| Category | Sources |
|----------|---------|
| Workflow / superpowers | `obra/superpowers`, `pbakaus/impeccable`, `mattpocock/skills` |
| Nix | `0xbigboss/claude-code -s nix-best-practices` |
| TypeScript / JS | `SpillwaveSolutions/mastering-typescript-skill`, `wshobson/agents` (ts/js patterns), `secondsky/claude-skills` (ts/api/security) |
| React / Frontend | `vercel-labs/agent-skills`, `anthropics/skills`, `shadcn/ui`, `oakoss/agent-skills` (react patterns) |
| Backend / API | `kadajett/agent-nestjs-skills`, `wshobson/agents` (node/api/db), `oakoss/agent-skills` (backend/api) |
| Tailwind / CSS | `giuseppe-trisciuoglio/developer-kit -s tailwind-css-patterns`, `heygen-com/hyperframes -s tailwind`, `wshobson/agents -s tailwind-design-system` |
| Biome | `biomejs/biome -s biome-developer` |
| Docker | `OpenAEC-Foundation/Docker-Claude-Skill-Package` (compose, cicd, production, storage, optimization) |
| Security | `wshobson/agents` (sast, secrets, stride, auth patterns), `oakoss/agent-skills` (security) |
| Testing | `wshobson/agents` (js-testing, e2e, bats), `oakoss/agent-skills` (testing) |
| DevOps / CI | `wshobson/agents` (github-actions, monorepo, git-workflows), `oakoss/agent-skills` (github-actions, git-workflow) |
| Knowledge work | `anthropics/knowledge-work-plugins` (debug, architecture, system-design, deploy-checklist, and many more) |
| Prompt engineering | `wshobson/agents -s prompt-engineering-patterns` |
| Vercel / deploy | `vercel-labs/skills` |
| Caveman mode | `JuliusBrussee/caveman` |

### Skill categories (personal machine only)

| Category | Sources |
|----------|---------|
| Next.js | `secondsky/claude-skills -s nextjs`, `wshobson/agents -s nextjs-app-router-patterns` |
| Postgres / DB | `wshobson/agents -s postgresql-table-design` |
| TanStack | `oakoss/agent-skills` (TanStack Query, Router, Form, Virtual, Table, Start) |
| ORM / DB | `oakoss/agent-skills` (drizzle-orm, hono, pglite, realtime-sync, postgres-tuning) |
| Local-first | `oakoss/agent-skills -s local-first` |
| Design / UI | `oakoss/agent-skills` (shadcn-ui, icon-design, figma-developer, react-email) |
| Motion / animation | `oakoss/agent-skills` (motion) |
| SEO | `oakoss/agent-skills -s seo-optimizer` |
| Publishing | `oakoss/agent-skills -s package-publishing` |
| GDPR | `wshobson/agents -s gdpr-data-handling` |

### Harness built-ins (not installable)

Always available, cannot be added to the manifest:
`update-config`, `loop`, `schedule`, `simplify`, `fewer-permission-prompts`, `keybindings-help`, `statusline-setup`, `init`, `review`, `security-review`, `claude-api`

---

## Initialization (Home Manager Activations)

Managed in `home/common/cli/ai/init.nix`. Runs automatically on every `darwin-rebuild switch`. Each step is guarded — only acts when needed.

| Step | Condition | What it does |
|------|-----------|-------------|
| `rtk init -g` | `rtk` in PATH | Configure rtk proxy for Claude Code + Copilot |
| `rtk init -g --opencode` | `rtk` in PATH | Configure rtk proxy for opencode |
| `rtk init -g --codex` | `rtk` in PATH | Configure rtk proxy for Codex |
| `pipx install code-review-graph` | not in `pipx list` | Install code-review-graph CLI |
| `pipx install ttok` | not in `pipx list` | Install ttok (LLM token counter) |
| `ai-skills-sync` | manifest hash changed | Install/update skills from manifest |

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
4. Verify Claude Code plugins loaded: `claude` → check plugin list
5. Verify MCP servers: `claude mcp list`
6. Check skills installed: `npx skills ls -g`

See [work-setup.md](work-setup.md) for the complete work machine setup.
