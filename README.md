# Nix Darwin + Home Manager Setup

macOS dotfiles for multiple machines using [Nix flakes](https://nixos.wiki/wiki/Flakes), [nix-darwin](https://github.com/nix-darwin/nix-darwin), [Home Manager](https://github.com/nix-community/home-manager), and [nix-homebrew](https://github.com/zhaofengli/nix-homebrew).

## Machines

| Config | Hostname | User | Brew owner |
|--------|----------|------|------------|
| `macbook` | `tutods-macbook` | `tutods` | `tutods` |
| `work` | `daniel.a.sousa` | `daniel.a.sousa` | `admin.daniel.a.sousa` |

---

## First-time setup

### 1. Install prerequisites

```bash
# Nix (multi-user)
sh <(curl -L https://nixos.org/nix/install)

# Xcode Command Line Tools
xcode-select --install
```

### 2. Clone the repo

```bash
git clone https://github.com/tutods/macos-setup.git ~/.dotfiles
cd ~/.dotfiles
```

### 3. Apply the configuration

```bash
./nix.sh macbook   # personal MacBook
./nix.sh work      # work laptop
```

This builds and applies the full system configuration via `darwin-rebuild switch`. Fish is set as the default shell, App Store apps and VSCode marketplace extensions are all installed automatically — no post-deploy script needed.

> On the **work laptop**, run `./nix.sh work` from `admin.daniel.a.sousa` — the admin user owns Homebrew. Home Manager still configures `daniel.a.sousa` independently.

### 4. Set up private git identity

Git name and email are not stored in this repo. Set them on each machine:

```bash
mkdir -p ~/.config/git
git config --file ~/.config/git/private user.name "Your Name"
git config --file ~/.config/git/private user.email "your@email.com"
```

See [docs/private-git-config.md](docs/private-git-config.md) for full details.

---

## Daily usage

```bash
# Rebuild and apply changes
./nix.sh macbook

# Build only (no apply, useful to check for errors)
./nix.sh macbook --build-only

# Force rebuild
./nix.sh macbook --force

# Format all Nix files
nix fmt
```

---

## Structure

```
.
├── flake.nix                  # Entry point — defines mkDarwin and formatter
├── lib/
│   └── mkHost.nix             # Shared host factory (fish, home-manager, nix-homebrew)
├── modules/
│   ├── common.nix             # Nix settings, timezone, GC, store optimisation
│   ├── darwin/                # macOS defaults, security, firewall, networking
│   └── packages/
│       ├── default.nix        # Imports all package modules
│       ├── cli.nix            # CLI tools (fd, fnm, jq, httpie, doppler, …)
│       ├── development.nix    # Dev tools and IDEs (claude-code, terraform, …)
│       ├── media.nix          # Media processing (ffmpeg, imagemagick, …)
│       └── fonts.nix          # System fonts (JetBrains Mono, Nerd Fonts, …)
├── hosts/darwin/
│   ├── macbook/               # Personal MacBook
│   │   ├── default.nix        # Calls mkHost with macbook values
│   │   ├── dock.nix           # Dock layout
│   │   └── homebrew/          # Macbook-specific casks and MAS apps
│   └── work/                  # Work laptop
│       ├── default.nix        # Calls mkHost with work values
│       ├── dock.nix
│       └── homebrew/          # Work-specific casks (shared base from modules/)
├── home/
│   ├── programs/              # Shared Home Manager programs (fish, VSCode, etc.)
│   ├── tutods/                # tutods user config
│   └── daniel.a.sousa/        # Work user config
└── docs/                      # Additional documentation
```

---

## Adding a new machine

1. Create the host directory:
   ```bash
   cp -r hosts/darwin/macbook hosts/darwin/new-machine
   ```

2. Edit `hosts/darwin/new-machine/default.nix` — update the `mkHost` call:
   ```nix
   { pkgs, mkHost, ... }:
   {
     imports = [
       ./dock.nix
       ./homebrew
       ./networking.nix
       (mkHost {
         username   = "newuser";
         hostname   = "new-machine";
         brewUser   = "newuser";
         homeConfig = import ../../../home/newuser/default.nix;
       })
     ];
   }
   ```

3. Create the home config:
   ```bash
   cp -r home/tutods home/newuser
   # edit home/newuser/default.nix to set the correct username/homeDirectory
   ```

4. Register in `flake.nix`:
   ```nix
   new-machine = mkDarwin ./hosts/darwin/new-machine;
   ```

5. Deploy:
   ```bash
   ./nix.sh new-machine
   ```

---

## Adding packages

| What | Where |
|------|-------|
| System-wide CLI tools | `modules/packages/cli.nix` |
| Development tools and IDEs | `modules/packages/development.nix` |
| Media processing tools | `modules/packages/media.nix` |
| Fonts | `modules/packages/fonts.nix` |
| Shared Homebrew casks (all machines) | `modules/darwin/homebrew/casks/` |
| Machine-specific Homebrew casks | `hosts/darwin/<name>/homebrew/casks/` |
| Mac App Store apps (shared) | `home/programs/cli/mas.nix` (via home.activation) |
| Mac App Store apps (per machine) | `home/<username>/default.nix` |
| User programs (shell, editor, etc.) | `home/programs/` |

---

## Maintenance

Nix garbage collection runs automatically every Sunday (keeps last 7 days of generations).

```bash
# Manual clean-up if needed
nix-collect-garbage -d

# If Homebrew has issues after a rebuild
brew doctor
```

Home Manager creates `.backup` files when overwriting existing configs — find and remove stale ones with:

```bash
find ~ -name "*.backup" -mtime +7
```

Dependency updates are automated via [Renovate](.github/renovate.json) — minor and patch updates for `nixpkgs`, `home-manager`, `nix-darwin`, and `nix-homebrew` are auto-merged. Major updates require manual review.