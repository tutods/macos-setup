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

Shared casks live in `modules/darwin/homebrew/casks/` (applied to every host). Machine-specific additions go in `hosts/darwin/<name>/homebrew/`. Both levels use the same category names: `development.nix`, `browsers.nix`, `communication.nix`, `utils.nix`. Macbook also has `fonts.nix`. The `work` host has a single inline list since it only adds `slack`.

### Shell Configuration

Fish shell is the primary shell, configured in `home/common/shell/fish/` with separate files for aliases (`alias.nix`), abbreviations (`abbrs.nix`), functions (`functions.nix`), and extra tool integrations (`extra.nix`). Completions live in `~/.config/fish/completions/` (managed outside Nix for project-specific tools).

### AI Instructions Architecture

AI instructions are split into shared and role-specific:

- `home/common/cli/ai/instructions/shared-instructions.md` — universal CLI tools + workflow (deployed to all roles via `~/.config/opencode/AGENTS.md`)

- `home/common/cli/ai/options.nix` — defines `home.ai.extraInstructions` option (default `""`)
- `home/roles/personal/ai/instructions.md` — personal-specific additions (e.g., `doppler`)
- `home/roles/work/` — no AI-specific instructions currently

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

### AI Skills

Skills are installed from `skills/manifest.txt` + `home/roles/personal/ai/skills/manifest.txt` during `darwin-rebuild` activation. Install runs once per manifest change (guarded by `~/.config/ai/.skills-sync-hash`). Output logged to `~/.cache/ai-skills-install.log`.

```bash
# Force reinstall all skills (next ./nix.sh run will trigger install loop)
rm ~/.config/ai/.skills-sync-hash && ./nix.sh macbook

# Inspect last install run (errors, per-source status)
cat ~/.cache/ai-skills-install.log

# List currently installed skills
npx skills ls -g

# Add a new skill source: append a line to the relevant manifest
# skills/manifest.txt                              ← both machines
# home/roles/personal/ai/skills/manifest.txt       ← personal only
# Then run ./nix.sh macbook to apply
```

Local in-repo skill sources live at `skills/local/` and deploy via `home.file` (dual target: `~/.agents/skills/` for the open standard, `~/.claude/skills/` for Claude Code discovery). They are NOT in the manifests.

Key: `pkgs.git` + `pkgs.nodejs` are injected into PATH during activation — required because `npx skills add owner/repo` git-clones the source. Without `git`, GitHub-sourced packages silently fail.

## CI

GitHub Actions (`flake-checker.yaml`) validates the flake on push and daily. Renovate auto-merges minor/patch updates for `nixpkgs`, `home-manager`, `nix-darwin`, and `nix-homebrew`.

@docs/nix-conventions.md
