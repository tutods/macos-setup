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
| Delegation contract | `instructions/delegation.md` + `UserPromptSubmit` hook | `agents/orchestrator.md` (the default primary, `edit: deny`) + the same contract in the generated `AGENTS.md` |
| Skills | `~/.claude/skills/` (deployed copies) | same directory, re-added via `skills.paths` after `OPENCODE_DISABLE_EXTERNAL_SKILLS=1` kills both external scans |
| Subagents | `~/.claude/agents/*.md` | `~/.config/opencode/agents/*.md` (ported: orchestrator, code-reviewer, dev-lifecycle, vault-lint, vault-search) |
| Council | Workflow tool, `llm-council.js` | `/council` command + hidden model-seat agents (no workflow engine exists) |
| MCP servers | merged into `~/.claude.json` | declared in `opencode.json` (Nix owns the file wholesale) |
| Vault context | `SessionStart` hook | `experimental.chat.system.transform` in the plugin |
| Statusline | `statusline.sh` | no equivalent, dropped |
| Plugins/marketplaces | `home.ai.plugins` | no marketplace mechanism, dropped |
| Format on edit | `biome-fix.sh` on `PostToolUse` | `formatter` in `config.nix`, opencode's built-in formatters with `nixfmt` and `shfmt` switched off |
| Secret deny-list | `permissions.deny` in `home/common/ai/settings.nix` | `permission.read` and `permission.bash` deny globs in `config.nix`, generated from the same paths |
| Co-author / AI attribution block | `block-ai-attribution.sh` on `PreToolUse` | `.hooks/commit-msg`, one layer below both harnesses; commit messages only, `gh` PR and review bodies are not guarded on the opencode side |

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
| `home/roles/personal/opencode/plugins/opencode-parity.js` | vault index in the system prompt, the one Claude hook with no opencode config key |
| `home/roles/personal/opencode/instructions/` | opencode-specific deltas folded into AGENTS.md |

## Documented exceptions (out-of-band content)

Same posture as Orca's hook events in `~/.claude/settings.json`: left alone,
listed here so a future cleanup finds them.

- `~/.config/opencode/plugins/supacode-presence.js` — Supacode-generated, marked do-not-edit.
- `~/.config/opencode/skills/{graphify,supacode-cli,supacode-deeplinks}` — installed by their own tools, still scanned via opencode's default skills dir.
- `~/.local/share/opencode/auth.json` — provider keys, secrets never enter Nix.

Everything else in `~/.config/opencode/plugins/` is deleted on every deploy by `home.activation.opencodePlugins` in `default.nix`, which keeps only the Nix-managed `opencode-parity.js` and the `supacode-presence.js` exception above. That directory is auto-loaded wholesale, so a stray file is not inert: `crg-plugin.ts` (broken against the 1.18.21 plugin API, `app.on is not a function`, and duplicating the `code-review-graph` MCP server now declared in `config.nix`) kept coming back from a Supacode tool and crashed startup each time. The activation script is the thing that keeps it gone.

## Deliberately not ported

`delegate-nudge`, `force-delegation` and `rtk-rewrite` are Claude-only. All three are per-turn counters over a hook stream opencode has no equivalent for, and they exist to reconstruct a boundary opencode already enforces statically: the `orchestrator` agent carries `edit: deny`, so inline file work is impossible rather than merely discouraged. The per-turn delegation reminder that used to live in `opencode-parity.js` went the same way, for the same reason.

`block-ai-attribution.sh` moved down a layer instead of being ported: `.hooks/commit-msg` in this repo rejects co-author trailers and AI attribution in the message, which covers Claude, opencode and a plain terminal with no harness API involved. Two deliberate limits. It sees commit messages only, so the `gh pr create|edit|comment|review` and `gh api` bodies the Claude hook also guards are unguarded when opencode drives them. And its regex mirrors `block-ai-attribution.sh` exactly, so it does not catch a `claude.ai/code/session_*` link, which is a session reference rather than an attribution.

`biome-fix.sh` is replaced by the `formatter` block in `config.nix`. opencode ships a built-in biome formatter that runs `biome format --write $FILE` on an edited file, gated on finding `biome.json`/`biome.jsonc` up-tree and resolving `@biomejs/biome` in the project, so it stays silent everywhere else. It formats but does not apply lint fixes, the one behavioural difference from Claude's `biome check --write`. Overriding `formatter.biome.command` to get `check` back would replace that gate with an unconditional run, so it stays as-is.

The gates are not uniform across the built-ins, which is why the config is an object rather than `true`. Most resolve a project config file up-tree the way biome does, but several (`nixfmt`, `shfmt`, `gofmt`, `rustfmt`) gate only on the binary being on `PATH`. `nixfmt` and `shfmt` are switched off explicitly: this repo formats `.nix` with alejandra via `nix fmt`, so a `nixfmt` that ever landed on `PATH` would silently reformat with the wrong tool and fail CI. The object form registers every built-in and then applies the overrides, so switching two off leaves the rest, biome included, enabled.

## The npx skills tree

`~/.agents/skills` (the `npx skills` tree) is deleted: nothing consumed it
once opencode's external scan was disabled, Claude only used two symlinks into
it, and both skills are now fetched from upstream at build time (`orchestration`,
`orca-cli`; see `mkFetchedSkills` in [ai-setup.md](ai-setup.md)) or dropped (`find-skills`,
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