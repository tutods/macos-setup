<div align="center">

# 🍎 macOS Setup

[![Flake Checker](https://github.com/tutods/macos-setup/actions/workflows/flake-checker.yaml/badge.svg)](https://github.com/tutods/macos-setup/actions/workflows/flake-checker.yaml)
[![Nix Flake](https://img.shields.io/badge/nix-flake-5277C3?logo=nixos&logoColor=white)](https://nixos.wiki/wiki/Flakes)
[![Platform](https://img.shields.io/badge/platform-aarch64--darwin-000000?logo=apple&logoColor=white)](https://github.com/nix-darwin/nix-darwin)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

**Two Apple Silicon Macs, one personal, one work, described entirely in Nix.**

One command rebuilds either machine from scratch — system defaults, packages,
Homebrew casks, App Store apps, shell, editors, and the whole AI harness setup
(Claude Code + opencode).

```bash
./nix.sh macbook
```

Built on [Nix flakes](https://nixos.wiki/wiki/Flakes) ·
[nix-darwin](https://github.com/nix-darwin/nix-darwin) ·
[Home Manager](https://github.com/nix-community/home-manager) ·
[nix-homebrew](https://github.com/zhaofengli/nix-homebrew)

</div>

---

## Machines

| | `macbook` | `work` |
|---|---|---|
| **User** | `tutods` | `daniel.a.sousa` |
| **Homebrew owner** | `tutods` | `admin.daniel.a.sousa` |
| **Notes** | Personal: Doppler, Terraform, extra casks and fonts, opencode | Corporate DNS untouched; Atlassian `acli` tap |

Both are `aarch64-darwin`. Adding a third is a directory copy and one line in
`flake.nix` → [adding-host-or-user.md](docs/adding-host-or-user.md).

## How a machine is assembled

```mermaid
flowchart TD
    F["flake.nix<br/><code>mkDarwin</code>"] --> C["modules/common.nix<br/>Nix settings, GC, timezone"]
    F --> D["modules/darwin/<br/>macOS defaults, security, homebrew"]
    F --> HM[home-manager]
    F --> NHB[nix-homebrew]
    F --> H["hosts/darwin/&lt;name&gt;/<br/>dock, casks, host packages"]

    H --> MH["<code>mkHost</code><br/>username · hostname · brewUser"]
    MH --> MU["<code>mkUser</code><br/>binds user to a role"]
    MU --> HC["home/common/<br/>ai · cli · editors · shell · terminal"]
    MU --> HR["home/roles/&lt;role&gt;/<br/>personal or work"]

    HC --> OUT([darwin-rebuild switch])
    HR --> OUT
    C --> OUT
    D --> OUT
    HM --> OUT
    NHB --> OUT
```

> **Innermost wins** — a host overrides a module, a role overrides common.

## What's in here

| | |
|---|---|
| 🖥️ **System** | macOS defaults, Touch ID for `sudo`, firewall, per-machine dock layout, weekly garbage collection |
| 📦 **Packages** | nixpkgs for CLI/dev tools, Homebrew for GUI apps, `mas` for App Store — all declarative, no post-install scripts |
| 🐚 **Shell** | Fish (abbreviations, aliases, functions in Nix) + oh-my-posh prompt, Ghostty terminal |
| ✏️ **Editors** | VS Code and Zed with extensions; app-rewritten configs are seeded as copies so the app can still save |
| 🤖 **AI** | The distinctive part — see below |

## AI setup at a glance

Everything both harnesses read is generated from this repo. Nothing is
configured by hand in a UI.

| Layer | Source | Lands in |
|-------|--------|----------|
| Always-on rules | `home/common/ai/instructions/` | `~/.claude/rules/workflow.md` |
| Custom skills | `home/common/ai/skills/local/` | `~/.claude/skills/` (real dirs, copied) |
| External skills | plugin marketplaces, declared in Nix | installed by Claude Code on next launch |
| MCP servers | `home/common/ai/mcp.nix` | `~/.claude.json` (`mcpServers`, merged) |
| Settings, hooks, statusline | `home/common/ai/settings.nix` | `~/.claude/settings.json` (merged) |
| opencode (personal only) | `home/roles/personal/opencode/` | `~/.config/opencode/` (config, agents, commands, plugins, AGENTS.md) |

**Claude Code** end to end from Nix: instructions, skills, marketplaces, MCP,
hooks → [ai-setup.md](docs/ai-setup.md)

**opencode**, the personal machine's second harness: shares the same
instruction sources and skills, runs its own agent fleet and slash commands,
and reads Claude's plugin-installed skills through a deploy-time bridge →
[opencode-setup.md](docs/opencode-setup.md)

Rules are scoped to where they are actually true: always-true rules are
instructions, stack-specific ones are skills that load on demand, repo-specific
ones live in that repo's own `CLAUDE.md`.

> ⚠️ Both harnesses' plugins fail silently — a typo'd name writes to the config,
> installs nothing, logs nothing. `scripts/verify-plugins.sh` (CI-enforced) and
> `scripts/verify-opencode.sh` catch that, plus `scripts/deploy-doctor.sh`
> previews everything a deploy would delete.

## First-time setup

```bash
# 1. Prerequisites
xcode-select --install                         # Command Line Tools
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
                                               # Nix via the Determinate installer (flakes on by default)

# 2. Clone
git clone https://github.com/tutods/macos-setup.git ~/.dotfiles
cd ~/.dotfiles
git config core.hooksPath .hooks               # pre-commit + commit-msg checks

# 3. Apply
./nix.sh macbook   # personal
./nix.sh work      # work                      # run as admin.daniel.a.sousa (owns Homebrew)

# 4. Private git identity (deliberately not in the repo)
mkdir -p ~/.config/git
git config --file ~/.config/git/private user.name  "Your Name"
git config --file ~/.config/git/private user.email "your@email.com"
```

Details: [private-git-config.md](docs/private-git-config.md) · recovery from
nothing: [recovery.md](docs/recovery.md)

## Daily usage

```bash
./nix.sh macbook                    # rebuild and apply
./nix.sh macbook --build-only       # build only, no sudo, catches errors
./nix.sh macbook --force            # force rebuild
nix fmt                             # format all Nix files (pre-commit enforces)
nix flake check                     # validate the flake
```

| Verification script | When |
|---------------------|------|
| `./scripts/verify-plugins.sh` | after touching Claude plugins / marketplaces (runs in CI) |
| `./scripts/verify-opencode.sh` | after touching the opencode setup (or `/verify-setup` in-session) |
| `./scripts/deploy-doctor.sh macbook` | before applying — previews what the next deploy deletes |

## Structure

<details>
<summary><b>Repository layout</b> (click to expand)</summary>

```
.
├── flake.nix                   Entry point: mkDarwin, formatter, both configs
├── nix.sh                      Build/apply wrapper (zero-dependency bash)
├── lib/
│   ├── mkHost.nix              Host factory: fish, home-manager, nix-homebrew
│   ├── mkUser.nix              Binds a username to a role
│   ├── mkDock.nix              Dock layout helper
│   └── ai.nix                  Skill installer, JSON merge, MCP helpers
├── modules/                    System-level, every host
│   ├── common.nix              Nix settings, timezone, GC
│   ├── darwin/                 macOS defaults, security, networking, homebrew
│   └── packages/               cli · development · media · fonts
├── hosts/darwin/
│   ├── macbook/                default · dock · networking · packages · homebrew
│   └── work/                   default · dock · homebrew
├── home/
│   ├── common/                 Every user
│   │   ├── ai/                 instructions · skills · agents · workflows · settings · plugins · mcp · maintenance · init
│   │   ├── cli/                bat · gh · git · htop
│   │   ├── editors/            vscode · zed
│   │   ├── shell/              fish · oh-my-posh
│   │   └── terminal/           ghostty
│   └── roles/
│       ├── personal/           Personal-only packages, plugins, skills, opencode
│       └── work/               Work-only: acli, PR review skills
├── scripts/                    verify-plugins · verify-opencode · deploy-doctor · darwin/ helpers
└── docs/                       Guides and reference
```

</details>

<details>
<summary><b>Adding things</b> (click to expand)</summary>

| What | Where |
|------|-------|
| System CLI tool | `modules/packages/cli.nix` |
| Dev tool | `modules/packages/development.nix` |
| Media tool | `modules/packages/media.nix` |
| Font | `modules/packages/fonts.nix` |
| Homebrew cask, all machines | `modules/darwin/homebrew/casks/` |
| Homebrew cask, one machine | `hosts/darwin/<name>/homebrew/casks/` |
| App Store app | `modules/darwin/homebrew/mas.nix` or the host's own `mas.nix` |
| System package, one machine | `hosts/darwin/<name>/packages.nix` |
| User program | `home/common/` |
| Claude skill | `home/common/ai/skills/local/` + the `names` list |
| Claude plugin | `home/common/ai/plugins.nix` or a role's `ai/default.nix` |
| opencode agent / command | `home/roles/personal/opencode/{agents,commands}/` |

Check a package exists in stable first: `nix search nixpkgs <name>`.

</details>

## Docs

| | Guide | About |
|---|-------|-------|
| 🏗️ | [architecture.md](docs/architecture.md) | Module composition and how a config is assembled |
| 📐 | [nix-conventions.md](docs/nix-conventions.md) | Conventions for working in this repo |
| 🤖 | [ai-setup.md](docs/ai-setup.md) | Claude Code: instructions, skills, plugins, MCP |
| ⚡ | [opencode-setup.md](docs/opencode-setup.md) | opencode: the second harness, personal machine only |
| 📦 | [dropped-skill-sources.md](docs/dropped-skill-sources.md) | Skill sources that can't ship as plugins |
| 🎓 | [ai-lessons.md](docs/ai-lessons.md) | Gotchas hit once and worth not repeating |
| ➕ | [adding-host-or-user.md](docs/adding-host-or-user.md) | Adding a machine or a user |
| 🔐 | [secrets.md](docs/secrets.md) | Where secrets live, never in this repo |
| 🔑 | [private-git-config.md](docs/private-git-config.md) | Machine-local git identity |
| 💼 | [work-setup.md](docs/work-setup.md) | Work environment, Jira, corporate specifics |
| 🚑 | [recovery.md](docs/recovery.md) | Rebuilding from nothing |
| 🐟 | [fix-fish-killed.md](docs/fix-fish-killed.md) | Fish killed after an update |
| 🎥 | [obs-screen-sharing.md](docs/obs-screen-sharing.md) | OBS screen-sharing permissions |

## Maintenance

Garbage collection runs weekly, keeping the last 7 days of generations.

```bash
nix-collect-garbage -d              # manual clean-up
brew doctor                         # if Homebrew misbehaves after a rebuild
find ~ -name "*.backup" -mtime +7   # stale Home Manager backups
```

CI validates the flake and builds both Darwin configurations on every push and
pull request, plus daily. [Renovate](.github/renovate.json) auto-merges minor
and patch updates for `nixpkgs`, `home-manager`, `nix-darwin` and
`nix-homebrew`; majors need review.

<div align="center">

## License

[MIT](LICENSE)

</div>