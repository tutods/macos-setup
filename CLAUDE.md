# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A **Nix flake** managing two macOS (Apple Silicon) machines using **nix-darwin**, **Home Manager**, and **nix-homebrew**:

- `macbook` — personal MacBook, user `tutods`
- `work` — work laptop, user `daniel.a.sousa`

## Commands

All commands must be run from the repo root (where `flake.nix` lives).

```bash
# Build and apply a configuration
./nix.sh macbook
./nix.sh work

# Build only (no apply, no sudo)
./nix.sh macbook --build-only

# Force rebuild
./nix.sh macbook --force

# Garbage collect old generations
nix-collect-garbage -d
```

The `--build-only` path runs:
```bash
nix --extra-experimental-features 'nix-command flakes' build ".#darwinConfigurations.<config>.system"
```

Applying uses `darwin-rebuild switch --flake ".#<config>"` (local binary if present, otherwise fetches from flake).

## Architecture

### Module Composition

`flake.nix` defines `mkDarwin`, which stacks modules in this order:

1. `modules/common.nix` — Nix settings, timezone, garbage collection
2. `modules/darwin/` — macOS defaults, security (Touch ID sudo), networking, keyboard
3. `home-manager.darwinModules.home-manager` — injects Home Manager
4. `nix-homebrew.darwinModules.nix-homebrew` — injects Homebrew manager
5. `hosts/darwin/<hostname>/` — host-specific overrides, user binding, dock, Homebrew packages

### Key Directories

| Path | Role |
|------|------|
| `modules/` | Shared system-level config (applied to every host) |
| `hosts/darwin/<name>/` | Per-machine config: system settings, dock, Homebrew casks |
| `home/common/` | Shared Home Manager config (shell, CLI tools, editors) — every user gets this |
| `home/roles/` | Context-specific Home Manager config (`personal/`, `work/`) — each role is a directory with `default.nix` and optional `ai/` submodule. In current usage role maps 1:1 to a single user (personal=`tutods`, work=`daniel.a.sousa`); the role/identity split earns its keep only if a future host reuses a role with a different user. |

### Homebrew Casks

Shared casks live in `modules/darwin/homebrew/casks/` (applied to every host). Machine-specific additions go in `hosts/darwin/<name>/homebrew/`. Both levels use the same category names: `development.nix`, `browsers.nix`, `communication.nix`, `utils.nix`. Macbook also has `fonts.nix`. The `work` host has a single inline list (`firefox`, `gcloud-cli`, `slack`, plus the `atlassian/acli` tap and `acli` brew).

### Shell Configuration

Fish shell is the primary shell, configured in `home/common/shell/fish/` with separate files for aliases (`alias.nix`), abbreviations (`abbrs.nix`), functions (`functions.nix`), and extra tool integrations (`extra.nix`). Completions live in `~/.config/fish/completions/` (managed outside Nix for project-specific tools).

### AI Instructions Architecture

AI instructions are split into shared and role-specific:

- `home/common/ai/instructions/shared-instructions.md` — universal CLI tools + workflow (deployed to all roles via `~/.claude/rules/workflow.md`). Always-on only: anything stack-specific belongs in a skill under `home/common/ai/skills/local/`, not here.

- `home/common/ai/options.nix` — defines `home.ai.extraInstructions` option (default `""`)
- `home/roles/personal/ai/instructions.md` — personal-specific additions (e.g., `doppler`)
- `home/roles/work/ai/instructions.md` — work-specific additions (git/Jira branch naming, company tools); the work role also ships the `acli`, `work-stack`, and `obsidian-vault` custom skills

The common module concatenates: shared + role extras (if set). Role modules set `home.ai.extraInstructions` via their `ai/default.nix`.

### Adding a New Host

1. Copy an existing host: `cp -r hosts/darwin/macbook hosts/darwin/<new-host>`
2. Register in `flake.nix`: `"new-host" = mkDarwin "./hosts/darwin/new-host";`
3. Deploy: `./nix.sh new-host`

### Adding a New User

Use `mkUser` (defined in `lib/mkUser.nix`) — it handles `home.username`, `home.homeDirectory`, and imports the role module. See `docs/adding-host-or-user.md` for the full flow.

```nix
homeConfig = mkUser {
  username = "<username>";
  role     = "personal";  # or "work"
};
```

For person-specific overrides (GPG keys, email, etc.) pass `extraImports` pointing at any Nix file — there is no dedicated `home/identity/` directory; keep such files wherever makes sense for the host.

For a secondary account that should only share the shell experience (fish, aliases, prompt, CLI tools — no editors or AI), pass `profile = "shell"` and add the account to the host's `extraShellUsers` so fish becomes its default shell. See the work host's admin user for the pattern.

### AI Skills

Two sources, and only two.

**External skills — Claude Code plugin marketplaces.** Declared in Nix, written into `~/.claude/settings.json` as `extraKnownMarketplaces` + `enabledPlugins`; Claude Code installs them itself on next launch. There is no sync script and nothing to run by hand.

| Where | Scope |
|-------|-------|
| `home/common/ai/plugins.nix` | both machines |
| `home/roles/personal/ai/default.nix` | personal only |
| `home/roles/work/ai/default.nix` | work only |

Roles contribute through two options (`home/common/ai/options.nix`), which merge across modules:

```nix
home.ai.marketplaces = { <key> = "<owner>/<repo>"; };   # key is chosen here, not read from the repo
home.ai.plugins      = [ "<plugin>@<key>" ];
```

Plugins are coarser than skills. To add one, find the plugin that ships the skill you want in the source repo's `.claude-plugin/marketplace.json` — a plugin's `source` dir contains the `skills/<name>/` you're after — then add the marketplace and the plugin. `claude-plugins-official` is built into Claude Code and needs no marketplace entry.

**Machine-wide plugins are generic only** — workflow, writing, debugging, authoring (caveman, humanizer, mattpocock, the official productivity set). Stack- and domain-specific plugins (framework packs, SEO, design tooling) are enabled per project in that repo's own `.claude/settings.local.json`, never here.

**Plugins fail silently** — a typo'd name is written to `settings.json`, Claude Code installs nothing, and nothing is logged. Always check:

```bash
./scripts/verify-plugins.sh          # every plugin resolves, + the skill count each drags in
./scripts/verify-plugins.sh --quiet  # what CI runs
```

`enabledPlugins` is written fully from `home.ai.plugins` on every deploy — dropping a plugin from the list is enough, the next `./nix.sh` disables it. Never add a plugin through the Claude Code UI; it will not survive the next deploy.

A repo without `.claude-plugin/marketplace.json` **cannot** be installed this way. `docs/dropped-skill-sources.md` records the sources dropped for that reason when this repo migrated off `npx skills`, so they can be re-checked later.

**Custom skills — in-repo sources.** `home/common/ai/skills/local/` (both roles), `home/roles/<role>/ai/skills/local/` (role-only). Installed by `lib/ai.nix:mkLocalSkills` as **real, writable directories** under `~/.claude/skills/` — copied, not symlinked into the Nix store, because Claude Code writes inside a skill directory. `~/.agents/` is not used.

```bash
# Add a custom skill: create home/common/ai/skills/local/<name>/SKILL.md, add <name> to the
# `names` list in home/common/ai/skills/default.nix, then ./nix.sh macbook
```

Every deploy also lists directories in `~/.claude/skills/` that this repo doesn't own — leftovers from the old `npx skills` era, which now shadow the copies shipped inside plugins. It prints the `rm -rf` line and never deletes on its own, since a stray directory could be a hand-written skill.

### AI Agents

Custom subagents — Markdown files with `name`/`description`/`tools`/`model`
frontmatter, invoked via the Agent tool. In-repo only; there's no plugin
channel for these the way there is for skills.

```bash
home/common/ai/agents/local/<name>.md   # both roles
```

Installed by `lib/ai.nix:mkLocalAgents` as `home.file` symlinks into
`~/.claude/agents/<name>.md` — unlike skills, an agent file is read-only input
Claude Code never writes inside, so a store symlink is safe, and Home Manager
removes it for free when the name leaves the `names` list in
`home/common/ai/agents/default.nix`.

```bash
# Add a custom agent: create home/common/ai/agents/local/<name>.md, add <name> to the
# `names` list in home/common/ai/agents/default.nix, then ./nix.sh macbook
```

### AI Workflows

Deterministic multi-agent scripts for Claude Code's Workflow tool — JS files
with an `export const meta` block, using `agent()`/`parallel()`/`pipeline()`.
Installed by `lib/ai.nix:mkLocalWorkflows` as `home.file` symlinks into
`~/.claude/workflows/<name>.js` (read-only input, same rationale as agents).

Boundary: **agents** for judgement-heavy work in one isolated context;
**workflows** for fixed fan-out with deterministic control flow (parallel
perspectives, verification gates). A thin skill can act as the natural-language
trigger that invokes the workflow — see `skills/local/llm-council`.

```bash
# Add a workflow: create home/common/ai/workflows/local/<name>.js, add <name> to the
# `names` list in home/common/ai/workflows/default.nix, then ./nix.sh macbook
```

## Repo Rules

- **Repo scripts are zero-dependency bash.** `nix.sh` and anything run at bootstrap must work with bash built-ins only — no `gum`, no external TUI tools (a script that installs dependencies can't depend on them). A gum-based TUI was tried and reverted.
- **Git remotes stay SSH.** Never switch them to HTTPS during reviews or "fixes".
- **Configs the app itself writes (e.g. Zed `settings.json`) are seeded as a one-time copy, not a store symlink** — a read-only symlink breaks the app's own save.
- One-off gotchas live in `docs/ai-lessons.md` — check it before debugging setup issues that feel familiar.
- **Rules are scoped to where they're true.** Always-true → `instructions/`; true for a stack → `home/common/ai/skills/local/`; true for one repo → that repo's own `CLAUDE.md`. Never name a specific project inside a machine-wide instruction or skill.

## CI

GitHub Actions (`flake-checker.yaml`) validates the flake on push and daily. Renovate auto-merges minor/patch updates for `nixpkgs`, `home-manager`, `nix-darwin`, and `nix-homebrew`.

@docs/nix-conventions.md
