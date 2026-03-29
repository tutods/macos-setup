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

Home Manager runs inside the nix-darwin build. Each user gets their config from `home/<username>/default.nix`, which imports the shared `home/programs/` tree.

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
| `homeConfig` | `import ../../../home/tutods/default.nix` | Home Manager config module |

On the work laptop `brewUser` differs from `username` because Homebrew is owned by an admin account.

---

## Package layers

Three layers manage software — each has a distinct scope:

### 1. System packages (`modules/packages/`)
`environment.systemPackages` — available to all users system-wide, split into focused files:

| File | Contents |
|------|----------|
| `cli.nix` | General CLI tools (gh, fnm, fd, jq, tldr, httpie, doppler, etc.) |
| `development.nix` | Dev tools (claude-code, terraform, JetBrains IDEs) |
| `media.nix` | Image/video processing (imagemagick, ffmpeg, jpegoptim, optipng) |
| `fonts.nix` | System fonts (JetBrains Mono, Fira Code, Montserrat, etc.) |

VSCode is managed by Home Manager only (not here).

### 2. Homebrew (`modules/darwin/homebrew/` + `hosts/darwin/<name>/homebrew/`)
GUI apps and casks that aren't in nixpkgs or work better through Homebrew. Split into:
- **Shared** (`modules/darwin/homebrew/`): casks and MAS apps installed on every machine
- **Per-machine** (`hosts/darwin/<name>/homebrew/`): machine-specific additions

Nix's module system merges list options, so both layers combine cleanly.

### 3. Home Manager (`home/programs/` + `home/<username>/`)
Per-user programs managed declaratively — fish, VSCode, bat, fzf, zoxide, eza, oh-my-posh, ghostty, git. These are `programs.*` options, not raw packages, so Home Manager handles both installation and configuration.

---

## Home Manager structure

```
home/
├── programs/               # Shared across all users
│   ├── default.nix         # Imports everything below + creates ~/Developer
│   ├── apps/
│   │   ├── vscode/         # VSCode settings, keybindings, extensions
│   │   └── terminal/
│   │       └── ghostty/    # Config + Catppuccin Mocha theme (via file symlink)
│   ├── cli/
│   │   ├── bat.nix
│   │   ├── git.nix         # Shared git config + delta diff viewer — identity from ~/.config/git/private
│   │   ├── htop.nix
│   │   └── oh-my-posh/
│   └── shell/
│       └── fish/
│           ├── default.nix     # Core: plugins, shellInit, interactiveShellInit
│           ├── extra.nix       # Tool integrations: zoxide, eza, fzf
│           ├── completions.nix # fzf key bindings and env vars
│           ├── alias.nix       # Silent substitutions (ls, .., docker, navigation)
│           ├── abbrs.nix       # Expanding abbreviations (git, brew)
│           └── functions.nix   # Multi-step git helpers (goMain, commt, etc.)
└── <username>/
    └── default.nix         # Sets username/homeDirectory/stateVersion, imports programs
```

### Aliases vs Abbreviations

Fish supports both. The rule used here:

- **Alias** → silent replacement, runs immediately. Used for `ls` (eza), navigation shortcuts (`..`, `work`), and docker format strings where seeing the expansion adds no value.
- **Abbreviation** → expands in-line before running. Used for git and brew commands so the full command appears in your terminal and shell history.

---

## Adding a new host

See [README.md](../README.md#adding-a-new-machine).

## Private git identity

See [private-git-config.md](private-git-config.md).
