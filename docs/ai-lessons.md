# AI Lessons: one-off gotchas

Specific incidents worth remembering but too narrow for standing rules. Each entry: what happened → what to do instead. Sources are commits in this repo unless noted.

## Claude Code setup

- **A skill repo is not automatically a plugin marketplace**: only repos with `.claude-plugin/marketplace.json` can be installed as plugins. 12 of 30 sources had none when this repo moved off `npx skills` and had to be dropped; see `docs/dropped-skill-sources.md`.
- **Plugins are coarser than skills**: a marketplace's plugin usually ships several skills, and the plugin name rarely matches the skill name. Read the repo's `marketplace.json` and match the plugin whose `source` dir holds the `skills/<name>/` you want; guessing produces a config that silently installs nothing useful.
- **`enabledPlugins` used to merge live + nix, so a removed plugin stayed enabled unless it was also added to a hand-maintained `purgedPlugins` tombstone list.** That list only grew and nothing signalled when an entry was safe to drop. Switched to a full rewrite of `~/.claude/settings.json` on every deploy (`settings.nix`), dropping a plugin from `home.ai.plugins` is now enough on its own. The trade-off: a plugin added through the Claude Code UI is disabled on the next `./nix.sh`, which the repo already required (never add plugins via the UI).
- **Custom skills are copied, not symlinked**, `home.file` points into the read-only Nix store and Claude Code writes inside skill directories. `lib/ai.nix:mkLocalSkills` does a `cp -R` + `chmod -R u+w`, ordered after `linkGeneration` so Home Manager's teardown of the old generation doesn't delete the fresh copy.
- **Auto-compaction must be a percentage, not a fixed window.** A fixed `autoCompactWindow` sized for 200k fired far too early, because `opusplan` executes on Sonnet 5, which runs a native 1M-token window on the API. `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` scales with whatever window is actually in effect.
- **MCP config merges, it never replaces.** `~/.claude.json` is live session state Claude Code writes to constantly, so the deploy merges into `mcpServers`. Nix is authoritative for additions only, removing a server needs `claude mcp remove <name> --scope user` once by hand. Deploy with no other session running, or a concurrent write can be lost.
- **A plugin's bundled `.mcp.json` registers MCP servers too**: so `claude mcp list` shows servers this repo never declared. Drop the plugin to remove them; declaring a competing copy just duplicates the tool schemas in every session.
- **A tool that depends on the model remembering to invoke it does not get used.** `rtk` was installed, given its own Nix module, documented in eight files, and made the sole content of `~/.claude/CLAUDE.md`. It was invoked zero times, because nothing enforced the prefix. Removed. Same failure the repo already fixed by moving `~/.claude/context/` into skills. Before adding a tool that needs the agent to opt in every time, decide what enforces it, or expect it to sit idle. A `PreToolUse` rewriter was rejected as the fix: silently mutating a command means the output you reason over is not the output the command produced.
- **Don't duplicate a server the plugins already provide.** A hand-rolled `github` MCP server sat unused next to `github@claude-plugins-official`, and a `filesystem` server duplicated Claude Code's native Read/Glob/Grep, both only added tool schemas to every session.

## Nix / dotfiles

- **Repo scripts (`nix.sh` etc.) are zero-dependency bash**: no `gum`, no external TUI helpers; a bootstrap script can't assume its own dependencies exist yet (gum TUI experiment was reverted on request).
- **Git remotes stay SSH**: don't "fix" them to HTTPS during audits; SSH is the intended auth path.

## Projects

Per-project lessons are **not** kept here, they live in that project's own
`CLAUDE.md`, so they travel with the repo and apply from any machine.
