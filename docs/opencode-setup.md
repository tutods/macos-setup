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
| Delegation contract | `instructions/delegation.md` + `UserPromptSubmit` hook | `agents/orchestrator.md` (the default primary, `edit: deny`) + `chat.message` reminder in `plugins/opencode-parity.js` |
| Skills | `~/.claude/skills/` (deployed copies) | same directory, re-added via `skills.paths` after `OPENCODE_DISABLE_EXTERNAL_SKILLS=1` kills both external scans |
| Subagents | `~/.claude/agents/*.md` | `~/.config/opencode/agents/*.md` (ported: orchestrator, code-reviewer, dev-lifecycle, vault-lint, vault-search) |
| Council | Workflow tool, `llm-council.js` | `/council` command + hidden model-seat agents (no workflow engine exists) |
| MCP servers | merged into `~/.claude.json` | declared in `opencode.json` (Nix owns the file wholesale) |
| Vault context | `SessionStart` hook | `experimental.chat.system.transform` in the plugin |
| Statusline | `statusline.sh` | no equivalent, dropped |
| Plugins/marketplaces | `home.ai.plugins` | no marketplace mechanism, dropped |

Models come from Ollama Cloud (`provider/model` ids, API key in
`~/.local/share/opencode/auth.json`, never in Nix). The tier table
(fast/default/best) and the six council seats are in
`instructions/opencode-models.md`, machine-readable in `config.nix`, change both together.

## Files

| Path | Role |
|------|------|
| `home/roles/personal/opencode/default.nix` | composition, AGENTS.md generation, agent/command/plugin deploys |
| `home/roles/personal/opencode/config.nix` | `opencode.json` (models, agents, permissions, MCP, skills.paths) |
| `home/roles/personal/opencode/agents/` | orchestrator + 4 ported subagents |
| `home/roles/personal/opencode/commands/council.md` | the `/council` fan-out |
| `home/roles/personal/opencode/plugins/opencode-parity.js` | per-message delegation reminder + vault index in system prompt |
| `home/roles/personal/opencode/instructions/` | opencode-specific deltas folded into AGENTS.md |

## Documented exceptions (out-of-band content)

Same posture as Orca's hook events in `~/.claude/settings.json`: left alone,
listed here so a future cleanup finds them.

- `~/.config/opencode/plugins/supacode-presence.js` — Supacode-generated, marked do-not-edit.
- `~/.config/opencode/skills/{graphify,supacode-cli,supacode-deeplinks}` — installed by their own tools, still scanned via opencode's default skills dir.
- `~/.local/share/opencode/auth.json` — provider keys, secrets never enter Nix.

The old `crg-plugin.ts` is gone: it was broken against the 1.18.21 plugin API
(`app.on is not a function`) and duplicated the `code-review-graph` MCP server
now declared in `config.nix`.

## The npx skills tree

`~/.agents/skills` (the `npx skills` tree) is deleted: nothing consumed it
once opencode's external scan was disabled, Claude only used two symlinks into
it, and both skills are now fetched from upstream at build time (`orchestration`,
see `mkFetchedSkills` in [ai-setup.md](ai-setup.md)) or dropped (`find-skills`,
whose whole job was promoting `npx skills add`). If it ever
reappears, `OPENCODE_DISABLE_EXTERNAL_SKILLS=1` already neutralizes it for
opencode; `customSkillsReconcile` ignores symlinks for Claude.

## Verification

After `./nix.sh macbook`:

1. `opencode` starts with no plugin errors in `~/.local/share/opencode/log/opencode.log`
2. Zero `duplicate skill name` warnings in the log (external scans off)
3. `/agents` shows the ported fleet; `@`-autocomplete shows only non-hidden agents
4. `/council <question>` convenes the five seats in one message
5. Skills list equals the repo-deployed set plus the three tool-installed exceptions

Escape hatches: `OPENCODE_DISABLE_PROJECT_CONFIG=1` skips a broken project
config; `OPENCODE_CONFIG_CONTENT='{"$schema":"https://opencode.ai/config.json"}'`
injects a minimal config. Config is loaded once at startup: quit and restart
opencode after every deploy.