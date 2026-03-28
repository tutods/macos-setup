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

# Post-deploy setup (fish shell default, terminal configs, VSCode extensions)
./post-nix.sh

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
| `home/<username>/` | Per-user Home Manager config; imports from `home/programs/` |
| `home/programs/` | Shared program configs (shell, CLI tools, apps) reused across users |

### Homebrew Casks

Shared casks live in `modules/darwin/homebrew/casks/` (applied to every host). Machine-specific additions go in `hosts/darwin/<name>/homebrew/`. The `macbook` host uses category files (`development.nix`, `utils.nix`, `web.nix`, `others.nix`); the `work` host has a single inline list since it only adds `slack`.

### Shell Configuration

Fish shell is the primary shell, configured in `home/programs/shell/fish/` with separate files for aliases (`alias.nix`), abbreviations (`abbrs.nix`), functions (`functions.nix`), completions (`completions.nix`), and extra tool integrations (`extra.nix`).

### Adding a New Host

1. Copy an existing host: `cp -r hosts/darwin/macbook hosts/darwin/<new-host>`
2. Register in `flake.nix`: `"new-host" = mkDarwin "./hosts/darwin/new-host";`
3. Deploy: `./nix.sh new-host`

### Adding a New User

1. Create `home/<username>/default.nix` (set `home.username`, `home.homeDirectory`, `home.stateVersion`, import `../programs`)
2. Pass it to `mkHost` in the host's `default.nix`:
   ```nix
   mkHost {
     username   = "<username>";
     homeConfig = import ../../../home/<username>/default.nix;
     ...
   }
   ```

## CI

GitHub Actions (`flake-checker.yaml`) validates the flake on push and daily. Renovate auto-merges minor/patch updates for `nixpkgs`, `home-manager`, `nix-darwin`, and `nix-homebrew`.
