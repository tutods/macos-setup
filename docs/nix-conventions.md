# Nix Conventions

Rules and conventions for working in this Nix flake repo.

## Sanity Checks (mandatory, not optional)

- Run `nix fmt` before committing any `.nix` file, hard requirement, not a suggestion
- Run `nix flake check` after any change to `flake.nix` or module files, catches errors before deploy. It builds both host toplevels, and `lib/ai.nix` assertions fail that build if a skill/agent/workflow `names` list and its `local/` directory drift apart (a declared name with no file, or a file with no declaration). This replaced `verify-references.sh`; that script's check for repo paths cited in Markdown that no longer exist was dropped as low value
- Run `./scripts/verify-plugins.sh` after touching `home.ai.plugins` or `home.ai.marketplaces`, plugins fail silently, so nothing else will tell you a name is wrong. This is the one check `nix flake check` cannot do: it clones the marketplace repos to confirm each plugin resolves remotely
- Run `./scripts/deploy-doctor.sh <host>` before applying, a deploy silently deletes unmanaged skill dirs, drops undeclared plugins and hook events, and clears `permissions.allow`; the doctor previews all four
- Never skip these even for "trivial" edits

## Adding Packages

- Run `nix search nixpkgs <name>` to confirm a package exists in stable before adding it
- Only use `pkgsUnstable` if the stable version is too old for the use case
- Tools that justify `pkgsUnstable`: `claude-code` and `opencode`, fast-moving, need latest

## Package Placement

| Where to add | Use when |
|-------------|----------|
| `modules/packages/` | System-level tool, needed on every host |
| `home/common/` | User-level tool, needed for every user/role |
| `home/roles/personal/` | Personal machine only |
| `hosts/darwin/<name>/homebrew/` | Machine-specific Homebrew cask |
| `modules/darwin/homebrew/casks/` | Shared Homebrew cask (all hosts) |

## Module Authoring

- Keep `options.nix` and `default.nix` separate, options declarations in one file, logic in the other
- Never hardcode usernames, use `config.home.username` or pass via `mkUser`
- Use explicit imports over `lib.mkIf` for clarity (this codebase prefers direct imports)
- Use `config.home.username` instead of hardcoding paths
- `pkgs` and `pkgsUnstable` come from `flake.nix` via `specialArgs`, not the module system's `nixpkgs.*` options. That means `nixpkgs.overlays` and `nixpkgs.config` set inside a module are inert. There are no overlays today; if one is ever needed, apply it in the `import nixpkgs` calls at the top of `flake.nix`, or migrate `pkgs` onto `nixpkgs.pkgs` first

## Never

- `nix-env -i`, always use `nix shell` for temporary tools
- Hardcode absolute paths like `/home/user/`, use Home Manager variables
- Put secrets or credentials in `.nix` files, use `doppler` or `sops-nix`

## Path Conventions

- `config.home.devDir`, Primary development directory (default: `$HOME/Developer`), declared in `home/common/options.nix`
- Fish functions use `$PROJECT_DIR` environment variable set by Nix
- Use `config.home.homeDirectory` instead of `/Users/$username` where possible
