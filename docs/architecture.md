# Architecture

## How a configuration is built

```
flake.nix
  └── mkDarwin "./hosts/darwin/<name>"
        ├── modules/common.nix          (Nix settings, timezone, store optimisation)
        ├── modules/darwin/             (macOS defaults, security, networking, keyboard)
        │     └── homebrew/            (shared brews, casks, MAS apps)
        ├── home-manager module         (wired up by mkHost)
        ├── nix-homebrew module         (wired up by mkHost)
        └── hosts/darwin/<name>/
              ├── default.nix           (calls mkHost + imports dock + homebrew)
              ├── dock.nix              (Dock layout)
              └── homebrew/             (machine-specific casks and MAS apps)
```

Home Manager runs inside the nix-darwin build. Each user gets their config from `mkUser` (in `lib/mkUser.nix`), which imports the shared `home/common/` tree and optionally a role module from `home/roles/`.

---

## mkHost

`lib/mkHost.nix` is a factory function that produces the boilerplate every host needs:

```
fish shell setup → home-manager wiring → nix-homebrew config
```

Called from each host's `default.nix` with four arguments:

| Argument | Example | Purpose |
|----------|---------|---------|
| `username` | `"tutods"` | macOS user account |
| `hostname` | `"tutods-macbook"` | `networking.hostName` |
| `brewUser` | `"tutods"` | User that owns Homebrew |
| `homeConfig` | `mkUser { username = "tutods"; role = "personal"; }` | Home Manager config module |

On the work laptop `brewUser` differs from `username` because Homebrew is owned by an admin account.

---

## Package layers

Three layers manage software — each has a distinct scope:

### 1. System packages (`modules/packages/`)
`environment.systemPackages` — available to all users system-wide, split into focused files:

| File | Contents |
|------|----------|
| `cli.nix` | General CLI tools (fnm, fd, jq, tldr, httpie, doppler, etc.) |
| `development.nix` | Dev tools (claude-code, terraform, JetBrains IDEs) |
| `media.nix` | Image/video processing (imagemagick, ffmpeg, jpegoptim, optipng) |
| `fonts.nix` | System fonts (JetBrains Mono, Fira Code, Montserrat, etc.) |

VSCode is managed by Home Manager only (not here).

### 2. Homebrew (`modules/darwin/homebrew/` + `hosts/darwin/<name>/homebrew/`)
GUI apps and casks that aren't in nixpkgs or work better through Homebrew. Split into:
- **Shared** (`modules/darwin/homebrew/`): casks and MAS apps installed on every machine
- **Per-machine** (`hosts/darwin/<name>/homebrew/`): machine-specific additions

Nix's module system merges list options, so both layers combine cleanly.

### 3. Home Manager (`home/common/` + `home/roles/`)
Per-user programs managed declaratively — fish, VSCode, bat, fzf, zoxide, eza, oh-my-posh, ghostty, git. These are `programs.*` options, not raw packages, so Home Manager handles both installation and configuration.

---

## Home Manager structure

```
home/
├── common/               # Shared across all users
│   ├── default.nix      # Imports all sub-modules + creates ~/Developer
│   ├── editors/
│   │   ├── vscode/      # VSCode settings, keybindings, extensions
│   │   └── zed/         # Zed editor config + settings
│   ├── terminal/
│   │   └── ghostty/     # Config + Catppuccin Mocha theme (via file symlink)
│   ├── cli/
│   │   ├── bat.nix
│   │   ├── gh.nix       # GitHub CLI + copilot extension
│   │   ├── git.nix      # Shared git config + delta diff viewer — identity from ~/.config/git/private
│   │   ├── htop.nix
│   │   └── oh-my-posh/  # Prompt theme (TOML config)
│   └── shell/
│       └── fish/
│           ├── default.nix     # Core: plugins, shellInit, interactiveShellInit
│           ├── extra.nix       # Tool integrations: zoxide, eza, fzf
│           ├── alias.nix       # Silent substitutions (ls, .., docker, navigation)
│           ├── abbrs.nix       # Expanding abbreviations (git, brew)
│           └── functions.nix   # Multi-step helpers (goMain, commt, killport, etc.)
└── roles/                # Context-specific overrides
    ├── personal/        # Personal machine overrides (ai/, skills/, instructions.md)
    └── work/            # Work machine overrides (ai/, instructions.md)
```

### Aliases vs Abbreviations

Fish supports both. The rule used here:

- **Alias** → silent replacement, runs immediately. Used for navigation shortcuts (`..`, `work`) and docker format strings where seeing the expansion adds no value.
- **Abbreviation** → expands in-line before running. Used for git and brew commands so the full command appears in your terminal and shell history.

---

## Reproducibility: strict vs mutable

Not everything in this setup is equally deterministic. Understanding which layers are pinned and which can drift helps debug unexpected changes.

### Strictly reproducible (pinned to flake inputs)

These are fully determined by `flake.lock`. Rolling back the flake input rolls back everything in this layer.

| Layer | What | How it's pinned |
|-------|------|-----------------|
| System packages | `environment.systemPackages` in `modules/packages/` | `nixpkgs` flake input |
| Home Manager programs | `programs.*` in `home/common/` (fish, git, bat, fzf, eza, zoxide, oh-my-posh, ghostty, htop, gh) | `home-manager` + `nixpkgs` flake inputs |
| VSCode extensions (nixpkgs) | `pkgs.vscode-extensions.*` and `pkgsUnstable.vscode-extensions.*` in `home/common/editors/vscode/default.nix` | `nixpkgs` / `nixpkgs-unstable` flake inputs |
| VSCode settings & keybindings | JSON files symlinked by Home Manager | Tracked in this repo |
| macOS defaults | `system.defaults.*` in `modules/darwin/settings.nix` | Tracked in this repo |
| Shell config | Fish aliases, abbreviations, functions | Tracked in this repo |

If a `./nix.sh macbook` build changes behavior unexpectedly, check `flake.lock` first — it records exact commit hashes for every input.

### Intentionally mutable (updated on deploy)

These are declared in the repo but **upgraded to latest versions** each time you deploy. They are not pinned by `flake.lock`.

| Layer | What | Why mutable |
|-------|------|-------------|
| Homebrew casks | GUI apps (Zen, Firefox Developer Edition, Slack, etc.) | `homebrew.onActivation.upgrade = true` upgrades all casks on every deploy |
| Homebrew brews | CLI tools installed via brew (`mas`, `rtk`) | Same as above |
| MAS apps | Mac App Store apps installed by `mas` | `mas install` runs in activation, version not pinned |
| VSCode marketplace extensions | `extensionsFromVscodeMarketplace` entries | Pinned by `version` + `sha256` in the repo, but must be manually updated when upstream releases new versions |
| nixpkgs-unstable packages | `pkgsUnstable` packages (claude-code, opencode, codex, ollama, pipx, fonts) | Pinned to `nixpkgs-unstable` flake input, which moves faster than stable |

### What this means in practice

- **Rolling back** the Nix layer (` ./nix.sh macbook --force` after `git revert`) restores system packages, HM programs, VSCode extensions from nixpkgs, and macOS defaults — but **not** Homebrew cask versions or MAS apps.
- **Homebrew upgrades** happen automatically on deploy. If a cask upgrade breaks something, you can downgrade with `brew install <cask>@<version>` but this is manual.
- **VSCode marketplace extensions** are pinned but not auto-updated. You must bump the `version` and `sha256` in `home/common/editors/vscode/default.nix` when you want a new version.
- **`nixpkgs-unstable`** tracks a moving target. Run `nix flake update nixpkgs-unstable` to pull newer versions.

### Secrets (not tracked at all)

See [secrets.md](secrets.md) for the full policy. Short version: `~/.config/git/private` and `~/.config/fish/secrets.fish` live only on the machine, never in this repo. Home Manager warns on deploy if they're missing.

---

## Adding a new host

See [README.md](../README.md#adding-a-new-machine).

## Private git identity

See [private-git-config.md](private-git-config.md).
