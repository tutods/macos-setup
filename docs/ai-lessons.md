# AI Lessons — one-off gotchas

Specific incidents worth remembering but too narrow for standing rules. Each entry: what happened → what to do instead. Sources are commits in this repo unless noted.

## Claude Code setup

- **Don't set Opus as the default model in settings** — it silently drains credits on every session (`f8e94dd`). Pick the model per task instead.
- **Skills must not reference files outside their own directory** — 6 installed skills had dangling references and broke (`006f405`). When writing a skill, everything it mentions ships inside it.
- **A skill repo is not automatically a plugin marketplace** — only repos with `.claude-plugin/marketplace.json` can be installed as plugins. 12 of 30 sources had none when this repo moved off `npx skills` and had to be dropped; see `docs/dropped-skill-sources.md`.
- **Plugins are coarser than skills** — a marketplace's plugin usually ships several skills, and the plugin name rarely matches the skill name. Read the repo's `marketplace.json` and match the plugin whose `source` dir holds the `skills/<name>/` you want; guessing produces a config that silently installs nothing useful.
- **`rtk` on Claude Code is manual — there is no hook.** `~/.claude/RTK.md` used to claim commands were "automatically rewritten by the Claude Code hook"; no such hook was ever configured, so the model read that, correctly did nothing, and the advertised 60–90% savings never happened. The auto-intercepting version was the opencode plugin, which went away with opencode. Prefix `rtk` yourself.
- **A removed plugin stays enabled unless it is purged.** `enabledPlugins` merges live + nix so UI-added plugins survive, which means deleting an entry from `home.ai.plugins` does nothing on a machine that already installed it. Add it to `purgedPlugins` as well.
- **Plugins fail silently, manifests failed loudly.** `npx skills add` errored on a bad source; a typo'd plugin name just installs nothing, with no log. `scripts/verify-plugins.sh` exists to turn that back into an error, and runs in CI.
- **Custom skills are copied, not symlinked** — `home.file` points into the read-only Nix store and Claude Code writes inside skill directories. `lib/ai.nix:mkLocalSkills` does a `cp -R` + `chmod -R u+w`, ordered after `linkGeneration` so Home Manager's teardown of the old generation doesn't delete the fresh copy.
- **`resciencelab/opc-skills` has an upstream bug** — it writes `skillPath` pointing at `SKILL.md` instead of the directory, which makes `claude /doctor` fail. Don't re-add until fixed.
- **graphify's pipx package is `graphifyy`** (double y) — the obvious name installs the wrong thing (`df2e9c4`). Removed since; kept here because the name trips up anyone re-adding it.
- **A tool that installs *itself* into the agent must be uninstalled before it's dropped from Nix.** `graphify install` wrote a `PreToolUse` hook into `~/.claude/settings.json` and a skill tree into `~/.claude/skills/graphify/`; deleting the Nix block alone would have left a hook firing on every Bash/Read/Glob call against a missing binary. Run the tool's own `uninstall` first — `init.nix` has the guarded migration.

## Nix / dotfiles

- **Configs the app itself mutates (e.g. Zed `settings.json`) must be seeded as a one-time copy, not a read-only store symlink** — otherwise the app can't save (`765044b`).
- **Repo scripts (`nix.sh` etc.) are zero-dependency bash** — no `gum`, no external TUI helpers; a bootstrap script can't assume its own dependencies exist yet (gum TUI experiment was reverted on request).
- **Escape `$` in regexes passed to `fd`/`rg` from fish** — fish expands `$` as a variable and the command breaks (`d6ac2bb`).
- **Git remotes stay SSH** — don't "fix" them to HTTPS during audits; SSH is the intended auth path.

## Node / package managers

- **pnpm ≥10.x stopped reading the `pnpm` field in `package.json`** — settings like `onlyBuiltDependencies` moved to `pnpm-workspace.yaml`; the old field only produces a WARN and silently does nothing (2026-07-17). Move the keys, don't ignore the warning.

## Projects

Per-project lessons are **not** kept here — they live in that project's own
`CLAUDE.md`, so they travel with the repo. See `docs/project-rules/` for the
ones staged but not yet installed.
