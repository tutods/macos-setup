# universal-ai-config

> Source: <https://github.com/fabis94/universal-ai-config>

Write AI instructions, skills, agents, hooks, and MCP configs once — generate tool-specific output for Claude Code, GitHub Copilot, Cursor, and Codex automatically.

Each tool stores config in a different location and format (`.claude/`, `.github/`, `.cursor/`, `.codex/`). This CLI generates all of them from a shared `.universal-ai-config/` template directory, so the target-specific folders can be gitignored and each developer generates only what they need.

---

## Install

```bash
# Project-local (recommended for JS/TS projects)
npm install -D universal-ai-config
npm exec uac <command>

# One-off / non-JS projects
npx universal-ai-config <command>
```

---

## Quick Start

```bash
# Scaffold template dir + config + meta-instruction templates
uac init

# Generate for all targets
uac generate

# Generate for specific targets
uac generate -t claude,cursor

# Preview without writing
uac generate --dry-run

# Seed example templates (instruction, skill, agent, hook)
uac seed examples
```

---

## Template Structure

```
your-project/
├── universal-ai-config.config.ts           # committed — shared config
├── universal-ai-config.overrides.config.ts # gitignored — personal overrides
└── .universal-ai-config/
    ├── instructions/      # Rules/instructions (markdown + EJS)
    ├── skills/            # One folder per skill, each with SKILL.md
    ├── agents/            # Agent definitions
    ├── hooks/             # Hook configs (JSON, merged by event)
    └── mcp/               # MCP server configs (JSON, merged by name)
```

---

## Writing Templates

All markdown templates support [EJS](https://ejs.co/) and YAML frontmatter. JSON templates (hooks, MCP) support `{{variableName}}` typed interpolation.

### Instructions

```markdown
---
description: Always applied coding standards
alwaysApply: true
---

Follow project coding standards at all times.

<% if (target === 'claude') { -%>
Use the Read tool to check existing patterns before writing new code.
<% } -%>
```

| Frontmatter field | Type | Notes |
|---|---|---|
| `description` | string | What this rule does |
| `globs` | `string \| string[]` | File patterns to scope the rule |
| `alwaysApply` | boolean | Apply regardless of context |

### Skills

```markdown
---
name: test-generation
description: Generate tests for code
userInvocable: /test
disableAutoInvocation: true
---

Generate comprehensive tests using vitest.
```

### Agents

```markdown
---
name: code-reviewer
description: Reviews code for quality
model: sonnet
tools: ["read", "grep", "glob"]
---

You are a code reviewer.
```

> Cursor does not support agents — CLI warns and skips agent generation for `cursor`.

### Hooks (JSON)

```json
{
  "hooks": {
    "preToolUse": [
      { "matcher": "Bash", "command": ".hooks/block-rm.sh", "timeout": 30 }
    ]
  }
}
```

Multiple `.json` files in `hooks/` are deep-merged by event name.

#### Hook events (universal camelCase → target format)

| Universal | Claude | Cursor | Copilot | Codex |
|---|---|---|---|---|
| `sessionStart` | `SessionStart` | `sessionStart` | `sessionStart` | `SessionStart` |
| `userPromptSubmit` | `UserPromptSubmit` | `beforeSubmitPrompt` | `userPromptSubmitted` | `UserPromptSubmit` |
| `preToolUse` | `PreToolUse` | `preToolUse` | `preToolUse` | `PreToolUse` |
| `postToolUse` | `PostToolUse` | `postToolUse` | `postToolUse` | `PostToolUse` |
| `stop` | `Stop` | `stop` | — | `Stop` |

### MCP Servers (JSON)

```json
{
  "mcpServers": {
    "github": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": { "GITHUB_TOKEN": "${GITHUB_TOKEN}" }
    }
  }
}
```

Multiple `.json` files in `mcp/` are merged by server name.

---

## Per-Target Overrides

Any frontmatter field, hook handler field, or MCP server field can accept per-target values. If a field's value is an object where every key is a target name or `default`, it resolves to the matching target's value.

```yaml
---
model:
  default: sonnet
  claude: opus
  copilot: gpt-4o
tools:
  default: ["read", "grep"]
  claude: ["Read", "Grep"]
---
```

Same syntax works in hook and MCP JSON:

```json
{
  "command": {
    "claude": ".hooks/claude-check.sh",
    "cursor": ".hooks/cursor-check.sh"
  }
}
```

---

## EJS Template Variables

| Variable | Type | Description |
|---|---|---|
| `target` | `'claude' \| 'copilot' \| 'cursor' \| 'codex'` | Current output target |
| `type` | `'instructions' \| 'skills' \| 'agents'` | Template type |
| `config` | `ResolvedConfig` | Full resolved config |
| `...config.variables` | `Record<string, unknown>` | Custom variables spread into scope |

### Path helpers

| Helper | Example output (Claude) |
|---|---|
| `instructionPath('coding-style')` | `.claude/rules/coding-style.md` |
| `skillPath('test-gen')` | `.claude/skills/test-gen/SKILL.md` |
| `mcpToolRef('github', 'list_issues')` | `mcp__github__list_issues` |
| `mcpToolRef('github')` | `mcp__github__*` |

---

## Configuration

### Base config (committed)

```typescript
// universal-ai-config.config.ts
import { defineConfig } from "universal-ai-config";

export default defineConfig({
  templatesDir: ".universal-ai-config",

  // Load shared templates from home dir across projects
  additionalTemplateDirs: ["~/.universal-ai-config"],

  targets: ["claude", "copilot", "cursor", "codex"],
  types: ["instructions", "skills", "agents", "hooks", "mcp"],

  variables: {
    projectName: "my-app",
  },

  // Exclude templates by glob (input path, not output path)
  exclude: ["agents/internal.md"],
});
```

### Overrides config (gitignored)

```typescript
// universal-ai-config.overrides.config.ts
import { defineConfig } from "universal-ai-config";

export default defineConfig({
  targets: ["claude", "cursor"],  // only generate what you use
  variables: { myStyle: "functional" },
});
```

### Resolution order (later wins)

1. Built-in defaults
2. `universal-ai-config.config.ts`
3. `universal-ai-config.overrides.config.ts`
4. CLI flags (`--target`, `--type`, etc.)

### MCP opt-in filtering

```typescript
export default defineConfig({
  mcp: {
    forceOptIn: true,
    mcpServers: ["github", "playwright"],  // only emit these servers
  },
});
```

---

## CLI Reference

| Command | Description |
|---|---|
| `uac generate` | Generate config files |
| `uac generate -t claude,cursor` | Generate for specific targets |
| `uac generate --dry-run` | Preview without writing |
| `uac generate --clean` | Remove existing files first |
| `uac init` | Scaffold template dir + config |
| `uac seed examples` | Seed example templates |
| `uac seed meta-instructions` | Seed AI-managed template skills |
| `uac seed gitignore` | Add generated paths to `.gitignore` |
| `uac clean` | Remove all generated config dirs |
| `uac clean -t claude` | Remove specific target's output |

---

## Output Paths

### Claude (`.claude/`)

| Type | Output |
|---|---|
| Instructions | `.claude/rules/<name>.md` |
| Skills | `.claude/skills/<name>/SKILL.md` |
| Agents | `.claude/agents/<name>.md` |
| Hooks | `.claude/settings.json` (`hooks` key) |
| MCP | `.mcp.json` |

### Copilot (`.github/`)

| Type | Output |
|---|---|
| Instructions | `.github/instructions/<name>.instructions.md` |
| Instructions (`alwaysApply`) | `.github/copilot-instructions.md` |
| Skills | `.github/skills/<name>/SKILL.md` |
| Agents | `.github/agents/<name>.agent.md` |
| Hooks | `.github/hooks/hooks.json` |
| MCP | `.vscode/mcp.json` |

### Cursor (`.cursor/`)

| Type | Output |
|---|---|
| Instructions | `.cursor/rules/<name>.mdc` |
| Skills | `.cursor/skills/<name>/SKILL.md` |
| Agents | Not supported |
| Hooks | `.cursor/hooks.json` |
| MCP | `.cursor/mcp.json` |

### Codex (`.codex/` + root)

| Type | Output |
|---|---|
| Instructions | `AGENTS.md` (root) or `<dir>/AGENTS.override.md` |
| Skills | `.agents/skills/<name>/SKILL.md` |
| Agents | `.codex/agents/<name>.toml` |
| Hooks | `.codex/hooks.json` |
| MCP | `.codex/config.toml` (`[mcp_servers.*]` table only — other sections preserved) |

---

## Programmatic API

```typescript
import { generate, writeGeneratedFiles, cleanTargetFiles } from "universal-ai-config";

const files = await generate({
  root: process.cwd(),
  targets: ["claude"],
  overrides: { variables: { projectName: "my-app" } },
});

await writeGeneratedFiles(files, process.cwd());
```

---

## Potential Integration with This Dotfiles Repo

The `additionalTemplateDirs` option supports `~` expansion, making it possible to maintain a global template directory (e.g., `~/.universal-ai-config/`) managed by Home Manager and shared across projects without installing the tool globally.

Potential location in this repo: `home/common/cli/ai/universal-ai-config/` with a Home Manager activation that writes the template files to `~/.universal-ai-config/`.
