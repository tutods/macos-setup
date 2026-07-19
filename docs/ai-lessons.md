# AI Lessons — one-off gotchas

Specific incidents worth remembering but too narrow for standing rules. Each entry: what happened → what to do instead. Sources are commits in this repo unless noted.

## Claude Code / opencode setup

- **Don't set Opus as the default model in settings** — it silently drains credits on every session (`f8e94dd`). Pick the model per task instead.
- **`ai-skills-sync` can fail on first run / on the work machine** — it needs the admin user context that `./nix.sh` runs under, not a plain shell. If it fails, rerun after a rebuild rather than debugging the sync itself.
- **Skills must not reference files outside their own directory** — 6 installed skills had dangling references and broke (`006f405`). When writing a skill, everything it mentions ships inside it.
- **`resciencelab/opc-skills` has an upstream bug** — it writes `skillPath` pointing at `SKILL.md` instead of the directory, which makes `claude /doctor` fail (noted in `home/roles/personal/ai/skills/manifest.txt`). Don't re-add until fixed.
- **`tanstack/router` as a skill source is broken** — dropped in `2b6c6e1`; use the `tanstack-router` skill from `oakoss/agent-skills` instead.
- **graphify's pipx package is `graphifyy`** (double y) — the obvious name installs the wrong thing (`df2e9c4`).

## Nix / dotfiles

- **Configs the app itself mutates (e.g. Zed `settings.json`) must be seeded as a one-time copy, not a read-only store symlink** — otherwise the app can't save (`765044b`).
- **Repo scripts (`nix.sh` etc.) are zero-dependency bash** — no `gum`, no external TUI helpers; a bootstrap script can't assume its own dependencies exist yet (gum TUI experiment was reverted on request).
- **Escape `$` in regexes passed to `fd`/`rg` from fish** — fish expands `$` as a variable and the command breaks (`d6ac2bb`).
- **Git remotes stay SSH** — don't "fix" them to HTTPS during audits; SSH is the intended auth path.

## Node / package managers

- **pnpm ≥10.x stopped reading the `pnpm` field in `package.json`** — settings like `onlyBuiltDependencies` moved to `pnpm-workspace.yaml`; the old field only produces a WARN and silently does nothing (hit in jps, 2026-07-17). Move the keys, don't ignore the warning.

## Projects

- **`~/Developer/AI/a-optica` is a dead path** (empty except `.idea`) — the live project is `~/Developer/freelances/a-optica`. Its session-memory rules were ported into that repo's `.universal-ai-config/instructions/` on 2026-07-19; don't mine the dead memory again.

## Frontend

- **`@unpic/react` handles preload/LQIP via its own props (`background`, priority)** — hand-rolled lazy-loading/preload tricks around it broke the hero image twice (a-optica `68a7ca8` revert, `8e2ec74` fix). Configure the component, don't work around it.
- **Check current API names before using a library remembered from training data** — `inputValidator` was deprecated in favor of `validator` (a-optica `5bff831`). The ctx7 rule exists for this reason.
