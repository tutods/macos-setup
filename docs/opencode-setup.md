# opencode Setup

opencode is the second terminal AI harness, personal machine only. Its whole config is one Nix-generated `opencode.json` plus one generated `AGENTS.md`: no marketplaces, no hooks, no Workflow tool, no statusline. The module lives in `home/roles/personal/opencode/`.

## Files

| Path | Role |
|------|------|
| `default.nix` | composition: generates `AGENTS.md`, deploys agents/commands/plugin, prunes the plugin dir, and a one-off bridge-symlink sweep dated 2026-09-22 (delete after two deploys) |
| `config.nix` | `opencode.json` wholesale: models, agents, permissions, MCP, `skills.paths` |
| `maintenance.nix` | weekly launchd prune of opencode's on-disk history: the log truncated past a size cap, sessions older than 30 days deleted from `opencode.db` |
| `agents/` | `vault-search.md`, `vault-lint.md` |
| `commands/` | `council.md`, `nixcheck.md`, `verify-setup.md` |
| `instructions/opencode-delegation.md` | opencode-specific delegation deltas folded into `AGENTS.md` |
| `plugins/opencode-parity.js` | the Claude hooks with no opencode config key: the attribution guard, the rtk bash rewrite, the project-local skill bridge |

## Instructions

`AGENTS.md` is generated: a header, then `instructions/opencode-delegation.md`, then `home/common/ai/instructions/shared.md` (the same file Claude's `rules/workflow.md` reads), then `home/roles/personal/ai/instructions.md`. It is never hand-edited, a deploy overwrites it. `scripts/verify-opencode.sh` enforces its byte budget, at or under 7000 bytes, so the concatenation can't grow unnoticed.

## Agents and commands

Two agents, both read-only and fast-tier: `vault-lint` (vault health check) and `vault-search` (content lookup), both deny `task` so neither can fan out. Commands, deployed under `~/.config/opencode/commands/`:

| Command | Runs |
|---------|------|
| `/council` | five hidden model-seat agents plus a chair primary and a blind peer reviewer; replaces the Claude `llm-council` workflow |
| `/nixcheck` | `nix fmt && nix flake check` |
| `/verify-setup` | `./scripts/verify-opencode.sh` |

The council seats and peer reviewer are hidden subagents, invoked only by `/council`; nothing else dispatches them.

## Permissions

Full-auto by default (`edit`/`webfetch`/`websearch` allow, `bash` allow-all), with two things layered on top in `config.nix`: a danger list (`dangerAsk`/`dangerDeny`: `rm -rf`, `git push --force`, `sudo`, and similar) and the secret-glob denies rendered from `lib/ai.nix`'s shared path families. `docs/ai-lessons.md` records why per-path MCP allow rules were dropped: opencode's built-in default already allows an MCP tool with no rule of its own, so a rule scoped to one server never enforced anything.

## Skills

opencode loads `~/.claude/skills` (the Nix-deployed Claude skills) plus the current project's `.claude/skills`. `OPENCODE_DISABLE_EXTERNAL_SKILLS=1` turns off every other scan. Plugin-installed Claude skills are not bridged into opencode any more, that mechanism is gone. `~/.agents/skills` is not read by opencode; it holds Codex skill copies this repo deploys (listed in `~/.agents/.dotfiles-managed-skills`) next to unmanaged `npx skills`/Orca installs.

## Documented exceptions (out-of-band content)

Left alone, listed here so a future cleanup finds them.

- `~/.config/opencode/plugins/supacode-presence.js`: Supacode-generated, marked do-not-edit.
- `~/.config/opencode/skills/{graphify,supacode-cli,supacode-deeplinks}`: installed by their own tools, still scanned via opencode's default skills dir.
- `~/.local/share/opencode/auth.json`: provider keys, secrets never enter Nix.

Everything else under `~/.config/opencode/plugins/` is deleted on every deploy by `home.activation.opencodePlugins`, which keeps only the Nix-managed `opencode-parity.js` plus the exception above.

## Opting a project into playwright

`playwright` is not a global MCP server: its tool schemas would ride in every request, in every repo, for a capability only some projects need. Declare it in a project-root `opencode.json` instead, and opencode merges it with the global config for that directory only:

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

No permission rule is needed: an MCP tool with no rule of its own falls through to opencode's `"*": "allow"` default. Add the file to the project's `.gitignore` if it is personal, or commit it if the team wants it shared.

## Deliberately not ported / removed

- Claude plugin-to-skill bridge: the global symlink walk from `~/.claude/plugins` is gone, so a plugin's skills exist only on the Claude side. The project-local `.claude/settings.json` skill registration in `opencode-parity.js` stays.
- `skills.nix` and the `npx skills add` tree: every declared source recorded zero loads (`docs/ai-lessons.md`), so the file and the tree are gone.
- `code-review-graph`: 30 tools, about 9.7k tokens of schema, for four calls across 27k messages. Dropped from `mcp` and from `verify-opencode.sh`.
- `orchestrator`/`code-reviewer`/`dev-lifecycle` agents: the delegation boundary they carried was convention only, opencode has no static edit-deny that survives a config merge, so keeping them bought no enforcement, only upkeep.
- `/deploy`/`/doctor` commands: they ran `./nix.sh macbook` and `./scripts/deploy-doctor.sh macbook` from inside a full-auto bash session. A deploy or a destructive-change preview belongs in a terminal a human is watching, not a command an agent can invoke on itself.

## Verification

After `./nix.sh macbook`:

1. `./scripts/verify-opencode.sh` (or `/verify-setup` inside opencode): binaries, `opencode.json` shape, provider auth, managed files, the `AGENTS.md` byte budget, the retired skill bridge, the plugins directory, and post-deploy log health.
2. `wc -c ~/.config/opencode/AGENTS.md`, must stay at or under 7000.
3. `opencode` starts with no plugin errors in `~/.local/share/opencode/log/opencode.log`.

Escape hatches: `OPENCODE_DISABLE_PROJECT_CONFIG=1` skips a broken project config; `OPENCODE_CONFIG_CONTENT='{"$schema":"https://opencode.ai/config.json"}'` injects a minimal config. Config loads once at startup, quit and restart opencode after every deploy.
