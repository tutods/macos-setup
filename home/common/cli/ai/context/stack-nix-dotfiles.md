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

## Configurable paths

- `home.devDir` — Primary development directory (default: `$HOME/Developer`)
- Fish shell exports `$PROJECT_DIR` environment variable for functions
- Override in role config: `home.devDir = "$HOME/Projects";`

Prefer `pkgs` (stable) over `pkgsUnstable` unless the tool needs latest version (claude-code uses unstable).

## AI setup structure

Claude Code is the only agent. There is no second CLI to keep in sync.

```
home/common/cli/ai/
├── tools/
│   └── claude/    → settings + plugin marketplaces + MCP + instructions extras
├── rtk/           → RTK proxy file (claude-RTK.md)
├── instructions/  → shared runtime AI instructions (→ ~/.claude/rules/workflow.md)
├── context/       → stack reference files (→ ~/.claude/context/)
├── prompts/       → reusable prompt templates (@-mention in conversations)
├── init.nix       → pipx installs (guarded), one-time tool migrations
├── options.nix    → home.ai.* options (instructions, MCP, marketplaces, plugins)
└── mcp-servers.nix → shared MCP server definitions (Nix-authoritative)

# Custom skill sources live at repo root:
skills/
├── default.nix    → copies local/ into ~/.claude/skills (real dirs, not symlinks)
└── local/         → in-repo skill sources (llm-council, content-writer, ...)
```

External skills are Claude Code plugins, declared in
`tools/claude/plugins.nix` (shared) and each role's `ai/default.nix`, and
written into `~/.claude/settings.json`. Nothing installs skills out of band.

## Role split

- `home/roles/personal/` — personal machine only (doppler, personal skills, TanStack/Next.js/Solid stack)
- `home/roles/work/` — work machine only (Jira MCP, work instructions, GCP context)

## Key conventions

- Secrets never in this repo — `~/.config/fish/secrets.fish` and `~/.config/git/private` are machine-local
- Homebrew is upgraded automatically on every deploy (`homebrew.onActivation.upgrade = true`)
- `pkgsUnstable` packages are not pinned — they track the unstable channel
- External skills are plugins — add the marketplace + plugin in Nix, never via the Claude Code UI
- Custom skills are copied into `~/.claude/skills/`, so edits there are overwritten on the next deploy — change the repo source
