# Nix Conventions

Rules and conventions for working in this Nix flake repo.

## Sanity Checks (mandatory, not optional)

- Run `nix fmt` before committing any `.nix` file — hard requirement, not a suggestion
- Run `nix flake check` after any change to `flake.nix` or module files — catches errors before deploy
- Never skip these even for "trivial" edits

## Adding Packages

- Run `nix search nixpkgs <name>` to confirm a package exists in stable before adding it
- Only use `pkgsUnstable` if the stable version is too old for the use case
- Tools that justify `pkgsUnstable`: `claude-code`, `codex`, `opencode` — fast-moving, need latest

## Package Placement

| Where to add | Use when |
|-------------|----------|
| `modules/packages/` | System-level tool, needed on every host |
| `home/common/` | User-level tool, needed for every user/role |
| `home/roles/personal/` | Personal machine only |
| `hosts/darwin/<name>/homebrew/` | Machine-specific Homebrew cask |
| `modules/darwin/homebrew/casks/` | Shared Homebrew cask (all hosts) |

## Module Authoring

- Keep `options.nix` and `default.nix` separate — options declarations in one file, logic in the other
- Never hardcode usernames — use `config.home.username` or pass via `mkUser`
- Use explicit imports over `lib.mkIf` for clarity (this codebase prefers direct imports)
- Use `config.home.username` instead of hardcoding paths

## Deploy Commands

```bash
./nix.sh macbook          # build + apply personal machine
./nix.sh work             # build + apply work machine
./nix.sh macbook --build-only   # build only, no sudo required
./nix.sh macbook --force  # force rebuild
nix-collect-garbage -d    # garbage collect old generations
```

## Never

- `nix-env -i` — always use `nix shell` for temporary tools
- Hardcode absolute paths like `/home/user/` — use Home Manager variables
- Put secrets or credentials in `.nix` files — use `doppler` or `sops-nix`

## Path Conventions

- `config.home.ai.projectDir` — Primary development directory (default: `$HOME/Developer`)
- Fish functions use `$PROJECT_DIR` environment variable set by Nix
- Use `config.home.homeDirectory` instead of `/Users/$username` where possible
