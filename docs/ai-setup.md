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
| `ttok` | Count LLM tokens before sending |
| `rtk` | Token proxy — reduces LLM token usage 60–90% |
| `pipx` | Installs `code-review-graph` post-deploy |

### When to use which tool

- `claude-code` — default for all coding tasks; full context, skills, MCP servers
- `opencode` — multi-provider or when a different model is needed mid-session
- `codex` — isolated throwaway scripts, one-shot shell tasks
- `ollama` — offline/private work
- `repomix` — pack repo context before switching tools or sharing with non-Claude AI

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

Deployed by `home/common/cli/ai/instructions/default.nix`.

| File | Deployed to | Purpose |
|------|------------|---------|
| `instructions/context7-prefix.md` | `~/.config/opencode/AGENTS.md` (prefix) | Context7 usage guide for opencode |
| `instructions/shared-instructions.md` | `~/.config/opencode/AGENTS.md` + `~/.claude/rules/workflow.md` | Fast CLI prefs, git conventions, Nix dotfiles guide |
| `home/roles/personal/ai/instructions.md` | appended to both | Doppler secrets management |
| `home/roles/work/ai/instructions.md` | appended to both | Work context (gcloud, no doppler, etc.) |

Role-specific instructions are set via `home.ai.extraInstructions` (defined in `options.nix`).

---

## Claude Code Settings

Managed by `home/common/cli/ai/claude/default.nix` via `home.activation.claudeSettings`.

Written to `~/.claude/settings.json` on every `darwin-rebuild switch`. Merge strategy:
- Nix owns: `hooks`, `extraKnownMarketplaces`, `theme`
- **Preserved from live file**: `enabledPlugins` (managed by `claude plugin add/remove`)

To add a new plugin permanently, add it to the `enabledPlugins` attrset in `claude/default.nix`.

### Custom marketplaces

| Marketplace ID | Repo |
|---------------|------|
| `caveman` | `JuliusBrussee/caveman` |
| `claude-code-warp` | `warpdotdev/claude-code-warp` |
| `agricidaniel-seo` | `AgriciDaniel/claude-seo` |
| `openai-codex` | `openai/codex-plugin-cc` |

---

## MCP Servers

Managed by `home/common/cli/ai/mcp/default.nix`.

| Server | Target | Purpose |
|--------|--------|---------|
| `filesystem` | Claude Code + opencode | Read/write files beyond CWD |
| `github` | Claude Code + opencode | Access PRs, issues, repos |
| `context7` | opencode only | Current library docs (remote HTTP) |

### GitHub MCP — token setup

The GitHub server reads `GITHUB_PERSONAL_ACCESS_TOKEN` from env. The wrapper maps `GITHUB_TOKEN → GITHUB_PERSONAL_ACCESS_TOKEN` at spawn.

1. Create token: <https://github.com/settings/tokens/new>
   - Scopes: `repo`, `read:org`, `read:user`
   - Preferred: fine-grained token per org

2. Add to `~/.config/fish/secrets.fish`:
   ```fish
   set -gx GITHUB_TOKEN "ghp_xxxxxxxxxxxxxxxxxxxx"
   ```

### Context7 MCP — token setup

context7 is a remote HTTP MCP server. Its API key must be a literal value in `opencode.json` (no env expansion for remote headers).

1. Get/rotate key: <https://context7.com/settings>

2. Add to `~/.config/fish/secrets.fish`:
   ```fish
   set -gx CONTEXT7_API_KEY "ctx7sk-xxxxxxxxxxxxxxxxxxxx"
   ```

3. Inject into `opencode.json` (run once after `darwin-rebuild switch`, and after key rotation):
   ```fish
   opencode-context7-setup
   ```

### Config file locations

| File | Tool | Managed by |
|------|------|-----------|
| `~/.claude/claude_desktop_config.json` | Claude Code CLI | Nix activation (merge) |
| `~/.config/opencode/opencode.json` (`mcp` key) | opencode | Nix activation (merge) |

Both use a merge strategy: Nix adds/updates managed servers, manually added servers are preserved.

### opencode base config

Static fields (`$schema`, `plugin`, `experimental`, `share`) are also managed by Nix via `home.activation.opencodeConfig`. Runs before MCP merge. Nix wins for these fields; `mcp` key is preserved and updated by the MCP activation.

---

## Skills

Managed by `home/common/cli/ai/skills/`.

- `manifest.txt` — declarative list of skills to install
- `ai-skills-sync` — fish function that reads the manifest and runs `npx skills add` for each entry

### Sync skills

```bash
ai-skills-sync
```

Installs globally (`-g`) to both `claude-code` and `opencode`. Run after a fresh deploy or when adding new entries to `manifest.txt`.

### Skill categories

| Category | Sources |
|----------|---------|
| Superpowers / workflow | `obra/superpowers` |
| Code review | `anthropics/knowledge-work-plugins` |
| Frontend / design | `anthropics/skills`, `Leonxlnx/taste-skill`, `secondsky/claude-skills`, `shadcn/ui` |
| Backend | `wshobson/agents`, `oakoss/agent-skills`, `prisma/skills`, `better-auth/skills` |
| Knowledge graph | `safishamsi/graphify` |
| SEO | `resciencelab/opc-skills` |
| CMS | `mindrally/skills` |
| Caveman mode | `JuliusBrussee/caveman` |
| Misc | `pbakaus/impeccable`, `vercel-labs/skills`, `vercel-labs/agent-skills`, `vercel/turborepo` |

### Standalone skills (not manifest-managed)

These live directly in `~/.claude/skills/` and must be manually reinstalled on a fresh machine:

| Skill | Source |
|-------|--------|
| `context7-mcp` | `context7@claude-plugins-official` plugin (reinstalls with plugin) |

### Harness built-ins (not installable)

These come with the Claude Code harness and are always available. Cannot be added to the manifest:
`update-config`, `loop`, `schedule`, `simplify`, `fewer-permission-prompts`, `keybindings-help`, `statusline-setup`, `init`, `review`, `security-review`, `claude-api`

---

## Post-deploy Hooks

`./nix.sh macbook` (and `./nix.sh work`) runs post-apply hooks automatically after deploy.

Hooks run as the **target user** (e.g. `daniel.a.sousa` even if script runs as `admin.daniel.a.sousa`).

| Hook | What it does |
|------|-------------|
| `rtk init -g` | Configure rtk proxy for Claude Code + Copilot |
| `rtk init -g --opencode` | Configure rtk proxy for opencode |
| `rtk init -g --codex` | Configure rtk proxy for Codex |
| `ai-skills-sync` | Install all skills from `manifest.txt` |
| `pipx install code-review-graph` | Install code-review-graph CLI |

Skip hooks: `./nix.sh macbook --skip-hooks`

---

## Fresh Machine Checklist

After running `./nix.sh <config>` on a new machine:

1. Set up git identity → see `docs/secrets.md`
2. Add secrets to `~/.config/fish/secrets.fish`:
   ```fish
   set -gx GITHUB_TOKEN "ghp_xxx"
   set -gx CONTEXT7_API_KEY "ctx7sk-xxx"
   ```
3. Inject context7 key into opencode:
   ```fish
   opencode-context7-setup
   ```
4. Verify Claude Code plugins loaded: `claude` → check plugin list
5. Verify MCP servers: `claude mcp list`
