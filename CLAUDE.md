# CLAUDE.md

## What This Repo Is

A **Nix flake** managing two macOS (Apple Silicon) machines using **nix-darwin**,
**Home Manager** and **nix-homebrew**:

- `macbook`, personal MacBook, user `tutods`
- `work`, work laptop, user `daniel.a.sousa`

## Repo Rules

- **Rules are scoped to where they're true.** Always-true → `home/common/ai/instructions/`; true for a stack → a skill in `home/common/ai/skills/local/`; true for one repo → that repo's own `CLAUDE.md`. Never name a specific project inside a machine-wide instruction or skill.
- **Configs the app itself writes (e.g. Zed `settings.json`) are seeded as a one-time copy, not a store symlink**: a read-only symlink breaks the app's own save.
- One-off gotchas live in [docs/ai-lessons.md](docs/ai-lessons.md), check it before debugging setup issues that feel familiar.

## Mandatory Checks

Not optional, not even for trivial edits:

```bash
nix fmt                       # before committing any .nix file
nix flake check               # after changing flake.nix or any module
./scripts/verify-plugins.sh   # after touching home.ai.plugins / marketplaces
./scripts/verify-references.sh # after renaming or deleting a skill/agent/script
```

Plugins fail silently, so nothing else will tell you a name is wrong. Dangling
references fail the same way: a deleted skill still named in a `names` list, or a
renamed script still cited in a doc, is silently ignored rather than erroring.
The pre-commit hook runs `nix fmt` and `verify-references.sh` always, and
`verify-plugins.sh` when a plugin source file is staged.

## Commands

Run from the repo root (where `flake.nix` lives).

```bash
./nix.sh macbook              # build + apply personal machine
./scripts/deploy-doctor.sh macbook # preview what the next deploy deletes
./nix.sh work                 # build + apply work machine
./nix.sh macbook --build-only # build only, no sudo required
./nix.sh macbook --force      # force rebuild
nix-collect-garbage -d        # garbage collect old generations
```

## Key Directories

| Path | Role |
|------|------|
| `modules/` | Shared system-level config, applied to every host |
| `hosts/darwin/<name>/` | Per-machine config: system settings, dock, Homebrew casks |
| `home/common/` | Shared Home Manager config (shell, CLI tools, editors, AI) |
| `home/roles/` | Role config, `personal/`, `work/`, each a directory with `default.nix` and an `ai/` submodule |
| `lib/` | `mkUser`, `mkHost`, `ai.nix` helpers |

`flake.nix` defines `mkDarwin`, which stacks: `modules/common.nix` →
`modules/darwin/` → Home Manager → nix-homebrew → `hosts/darwin/<hostname>/`.

Shared Homebrew casks live in `modules/darwin/homebrew/casks/`, machine-specific
ones in `hosts/darwin/<name>/homebrew/`, both using the same category filenames.

Fish is the primary shell, configured in `home/common/shell/fish/` with separate
files for aliases, abbreviations, functions and tool integrations.

## Reference

| Topic | Doc |
|-------|-----|
| AI setup, instructions, skills, agents, workflows, plugins, MCP, hooks | [docs/ai-setup.md](docs/ai-setup.md) |
| Nix conventions, package placement, module authoring | [docs/nix-conventions.md](docs/nix-conventions.md) |
| Adding a host or a user | [docs/adding-host-or-user.md](docs/adding-host-or-user.md) |
| One-off gotchas already paid for | [docs/ai-lessons.md](docs/ai-lessons.md) |
| Skill sources that can't be plugins | [docs/dropped-skill-sources.md](docs/dropped-skill-sources.md) |
| Work machine specifics | [docs/work-setup.md](docs/work-setup.md) |

## CI

GitHub Actions (`flake-checker.yaml`) validates the flake on push and daily.
Renovate auto-merges minor/patch updates for `nixpkgs`, `home-manager`,
`nix-darwin`, and `nix-homebrew`, and every automerge waits on branch
protection's required checks (both `Build Darwin Configs` jobs included), so a
lock update that fails to build cannot merge. `main` requires linear history
and no force pushes; job names in required checks must match the workflow's
`name:` fields exactly, keep them in sync when renaming a job. A failing
scheduled/push run opens a tracking issue and closes it once green, except
billing-class failures, which stop jobs before they start and only reach you
via GitHub's account emails — check `gh run list` when CI has been quiet.

@docs/nix-conventions.md
