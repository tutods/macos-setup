---
name: nix-setup
description: Conventions for the ~/.dotfiles Nix flake that manages both macOS machines — deploy commands, module hierarchy, where a given package or setting belongs, and the AI/skill/plugin layout. Use when working anywhere in the dotfiles repo, editing a .nix file, adding a package or Homebrew cask, changing Claude Code settings/skills/plugins/MCP servers, or running ./nix.sh.
---

# Nix Dotfiles — Repo Conventions

`~/.dotfiles` is a Nix flake using nix-darwin + Home Manager + nix-homebrew,
managing two Apple Silicon machines: `macbook` (user `tutods`) and `work`
(user `daniel.a.sousa`).

## Commands

```bash
./nix.sh macbook               # build + apply personal machine
./nix.sh work                  # build + apply work machine
./nix.sh macbook --build-only  # build only (no sudo, no apply)
./nix.sh macbook --force       # force rebuild
nix fmt .                      # format all Nix files
nix flake check                # validate flake
nix-collect-garbage -d         # drop old generations
```

## Mandatory before declaring a change complete

- `nix fmt .` after touching any `.nix` file — hard requirement
- `nix flake check` after changing `flake.nix` or any module
- `./scripts/verify-plugins.sh` after touching `home.ai.plugins` or
  `home.ai.marketplaces` — plugins fail silently, so nothing else catches a typo

## Module hierarchy (innermost wins)

```
modules/             → all hosts, system-level
hosts/darwin/<name>/ → per-machine overrides
home/common/         → all users, Home Manager
home/roles/<role>/   → personal/ or work/ role-specific
```

Person-specific overrides (GPG keys, email) are passed through `mkUser`'s
`extraImports` — there is no dedicated `home/identity/` directory.

## Where things belong

| Type | Where |
|------|-------|
| System CLI tools | `modules/packages/cli.nix` |
| Dev tools | `modules/packages/development.nix` |
| GUI apps (shared) | `modules/darwin/homebrew/casks/<category>.nix` |
| GUI apps (machine-specific) | `hosts/darwin/<name>/homebrew/` |
| Per-user programs | `home/common/` or `home/roles/<role>/` |

Run `nix search nixpkgs <name>` before adding a package. Prefer `pkgs` (stable);
`pkgsUnstable` only when stable is too old — `claude-code` and `rtk` qualify.

## Configurable paths

- `home.devDir` — development directory (default `$HOME/Developer`), declared in
  `home/common/options.nix`
- Fish exports `$PROJECT_DIR` for its functions
- Never hardcode `/Users/<name>` — use `config.home.homeDirectory` and
  `config.home.username`

## AI setup structure

Claude Code is the only agent. There is no second CLI to keep in sync.

Everything AI lives under `home/common/ai/`. Nothing AI-related sits outside it.

There is no `claude/` subdirectory: every file here writes into `~/.claude/`,
so it would not separate Claude things from non-Claude things.

```
home/common/ai/
├── default.nix      → imports the tree
├── options.nix      → home.ai.* options
├── init.nix         → guarded pipx installs, one-time tool migrations
├── settings.nix     → ~/.claude/settings.json (+ hooks, purgedPlugins)
├── plugins.nix      → marketplaces + plugins, shared across hosts
├── mcp.nix          → writes the MCP server list
├── mcp-servers.nix  → the server definitions themselves (pure data)
├── statusline.nix   → statusline script + config
├── instructions/    → always-on instructions (→ ~/.claude/rules/workflow.md)
├── skills/
│   ├── default.nix  → copies local/ into ~/.claude/skills (real dirs, not symlinks)
│   └── local/       → in-repo skill sources
└── rtk/             → RTK proxy reference (→ ~/.claude/RTK.md, via @RTK.md)
```

`lib/ai.nix` is passed in as the `aiLib` module argument (wired in
`lib/mkHost.nix` via `extraSpecialArgs`) — never import it by relative path.

Each role mirrors that shape:

```
home/roles/<role>/ai/
├── default.nix      → role plugins, MCP servers, extraInstructions
├── instructions.md  → role-only always-on text
└── skills/local/    → role-only skill sources
```

## Rule scoping — where a given rule goes

| Scope | Home |
|-------|------|
| True in every session | `home/common/ai/instructions/` |
| True for a stack | `home/common/ai/skills/local/` |
| True for one role | `home/roles/<role>/ai/skills/local/` |
| True for one repo | that repo's own `CLAUDE.md` |

Never name a specific project inside a machine-wide instruction or skill — write
it in that project's own `CLAUDE.md` instead, so it travels with the repo.

## Skills and plugins

External skills are **Claude Code plugins** — declare the marketplace and plugin
in Nix; they are written into `~/.claude/settings.json` and Claude Code installs
them on next launch. Never add one through the Claude Code UI.

Removing a plugin from `home.ai.plugins` is not enough: `enabledPlugins` merges
live and Nix state, so it must also go in `purgedPlugins` in
`settings.nix`.

Custom skills are **copied** into `~/.claude/skills/`, so edits made there are
overwritten on the next deploy — change the repo source instead.

## Key conventions

- Repo scripts are zero-dependency bash — `nix.sh` and anything at bootstrap
  must work with built-ins only (a gum-based TUI was tried and reverted)
- Git remotes stay SSH — never "fix" them to HTTPS
- Configs the app itself writes (Zed `settings.json`) are seeded as a one-time
  copy, not a store symlink — a read-only symlink breaks the app's own save
- Secrets never live in this repo — `~/.config/fish/secrets.fish` and
  `~/.config/git/private` are machine-local
- Homebrew upgrades automatically on every deploy
- `pkgsUnstable` packages are not pinned — they track the unstable channel
- One-off gotchas are recorded in `docs/ai-lessons.md` — check it before
  debugging something that feels familiar
