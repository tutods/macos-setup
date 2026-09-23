# CLAUDE.md

## What This Repo Is

A **Nix flake** managing two macOS (Apple Silicon) machines using **nix-darwin**,
**Home Manager** and **nix-homebrew**:

- `macbook`, personal MacBook, user `tutods`
- `work`, work laptop, user `daniel.a.sousa`

## Repo Rules

- **Rules are scoped to where they're true.** Always-true → `home/common/ai/instructions/shared.md` (or `delegation.md` for Claude-only rules); true for one repo → that repo's own `CLAUDE.md`/`.claude/`. Never name a specific project inside a machine-wide instruction.
- **Configs the app itself writes (e.g. Zed `settings.json`) are seeded as a one-time copy, not a store symlink**: a read-only symlink breaks the app's own save.
- One-off gotchas live in [docs/ai-lessons.md](docs/ai-lessons.md), check it before debugging setup issues that feel familiar.

## Mandatory Checks

Not optional, not even for trivial edits:

```bash
nix fmt                       # before committing any .nix file
nix flake check               # after changing flake.nix or any module
./scripts/verify-plugins.sh   # after touching home.ai.plugins / marketplaces
```

`nix flake check` builds both host toplevels, and `lib/ai.nix` carries build-time
`assertions` that fail that build if a name in a skill/agent/workflow `names` list
has no matching file, or an on-disk `local/` entry is missing from its list. That
replaces the old `verify-references.sh`; its doc backtick-path check (repo paths
cited in Markdown that no longer exist) was dropped as low value.

`verify-plugins.sh` is the one check `nix flake check` cannot do: it clones the
marketplace repos to confirm each declared plugin resolves remotely, falling
back to the local Claude Code install of a marketplace (any `/Users/*` home)
when the repo is private and refuses the anonymous clone. Plugins fail
silently, so a typo'd name is never surfaced otherwise. The pre-commit hook
format-checks the staged content (the index blobs, not the worktree) of any
staged `.nix` files and fails with per-file re-stage guidance when they are
unformatted, and runs `verify-plugins.sh` when a plugin source file is staged.

## Commands

Run from the repo root (where `flake.nix` lives).

```bash
./nix.sh macbook              # build + apply personal machine
./scripts/deploy-doctor.sh macbook # preview what the next deploy deletes
./nix.sh work                 # build + apply work machine
./nix.sh macbook --build-only # build only, no sudo required
./nix.sh macbook --force      # force rebuild
nix-collect-garbage -d        # garbage collect old generations
./scripts/claude-cleanup.sh   # after a deploy: preview Claude Code state Nix cannot reach; --apply prunes it
```

`deploy-doctor.sh` previews what a deploy would change destructively:
unmanaged skill dirs, undeclared plugins, foreign hook events, cleared
`permissions.allow` rules, and the Homebrew `cleanup = "uninstall"` pass. It
does not preview the opencode plugin-dir prune, the only destructive step
outside `~/.claude`. `nix.sh` runs it automatically before every apply and
gates on its exit code: 0 proceeds, 2 (destructive changes predicted)
requires interactive confirmation or `--force`, 3 (cannot certify) always
aborts.

## Key Directories

| Path | Role |
|------|------|
| `modules/` | Shared system-level config, applied to every host |
| `hosts/darwin/<name>/` | Per-machine config: system settings, dock, Homebrew casks |
| `home/common/` | Shared Home Manager config (shell, CLI tools, editors, AI) |
| `home/roles/` | Role config, `personal/`, `work/`, each a directory with `default.nix`, an `ai/` submodule, and (personal only) an `opencode/` submodule |
| `lib/` | `mkUser`, `mkHost`, `ai.nix` helpers |

`flake.nix` defines `mkDarwin`, which stacks: `modules/common.nix` →
`modules/darwin/` → Home Manager → nix-homebrew → `hosts/darwin/<hostname>/`.

Shared Homebrew casks live in `modules/darwin/homebrew/casks/`, machine-specific
ones in `hosts/darwin/<name>/homebrew/`, both using the same category filenames.
The `work` host keeps its casks flat in one `homebrew/default.nix` because it has only a few.

Fish is the primary shell, configured in `home/common/shell/fish/` with separate
files for aliases, abbreviations, functions and tool integrations.

## Reference

| Topic | Doc |
|-------|-----|
| AI setup, instructions, skills, agents, workflows, plugins, MCP, hooks | [docs/ai-setup.md](docs/ai-setup.md) |
| opencode setup (personal machine) | [docs/opencode-setup.md](docs/opencode-setup.md) |
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
scheduled/push run surfaces only in `gh run list` and GitHub's
failure-notification emails, except billing-class failures, which stop jobs
before they start and only reach you
via GitHub's account emails — check `gh run list` when CI has been quiet.

@docs/nix-conventions.md
