# Nix Dotfiles — Repo Conventions

Reference context for working in the `~/.dotfiles` repo.

## Commands

```bash
./nix.sh macbook           # build + apply personal machine
./nix.sh work              # build + apply work machine
./nix.sh macbook --build-only  # build only (no sudo, no apply)
./nix.sh macbook --force   # force rebuild
nix fmt .                  # format all Nix files
nix flake check            # validate flake
```

Always run `nix fmt . && nix flake check` before declaring a change complete.

## Module hierarchy (innermost wins)

```
modules/             → all hosts, system-level
hosts/darwin/<name>/ → per-machine overrides
home/common/         → all users, Home Manager
home/roles/<role>/   → personal/ or work/ role-specific
home/identity/       → person-specific (GPG, email)
```

## Adding packages

| Type | Where |
|------|-------|
| System CLI tools | `modules/packages/cli.nix` |
| Dev tools | `modules/packages/development.nix` |
| GUI apps (shared) | `modules/darwin/homebrew/casks/<category>.nix` |
| GUI apps (machine-specific) | `hosts/darwin/<name>/homebrew/` |
| Per-user programs | `home/common/` or `home/roles/<role>/` |

Prefer `pkgs` (stable) over `pkgsUnstable` unless the tool needs latest version (claude-code, opencode, codex use unstable).

## AI setup structure

```
home/common/cli/ai/
├── claude/       → Claude Code settings + MCP
├── opencode/     → opencode config + MCP
├── instructions/ → runtime AI instructions (deployed to AI tools)
├── skills/       → local skills + manifest.txt
├── context/      → stack reference files (@-mention in conversations)
├── prompts/      → reusable prompt templates (@-mention in conversations)
├── init.nix      → rtk init + pipx + skills sync
└── mcp-servers.nix → shared MCP server definitions
```

## Role split

- `home/roles/personal/` — personal machine only (doppler, personal skills, TanStack/Next.js/Solid stack)
- `home/roles/work/` — work machine only (Jira MCP, work instructions, GCP context)

## Key conventions

- Secrets never in this repo — `~/.config/fish/secrets.fish` and `~/.config/git/private` are machine-local
- Homebrew is upgraded automatically on every deploy (`homebrew.onActivation.upgrade = true`)
- `pkgsUnstable` packages are not pinned — they track the unstable channel
- Skills sync is hash-guarded — force resync with `rm ~/.config/ai/.skills-sync-hash`
