# Emergency Recovery Guide

This guide describes the process of bootstrapping this dotfiles repository on a fresh macOS installation.

## 1. Prerequisites
Run these in order on a fresh machine:

1. **Xcode Command Line Tools**: `xcode-select --install`. This provides `git` (macOS ships no standalone git, and Homebrew does not exist yet). The Nix installer in the next step also triggers this if it is missing.
2. **Nix** via the Determinate Systems installer (same one CI uses):
   `curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install`
   Open a new shell afterwards so `nix` is on `PATH`. Flakes are enabled by default.

## 2. Initial Setup
1. Clone the repository:
   `git clone https://github.com/tutods/.dotfiles.git ~/.dotfiles`
2. Navigate to the root:
   `cd ~/.dotfiles`

## 3. Deployment Sequence
Run the deployment script for the specific machine:
- **Macbook**: `./nix.sh macbook`
- **Work**: `./nix.sh work`

### What happens during deployment:
1. **Build**: Nix evaluates `flake.nix` and builds the system configuration.
2. **Git Identity**: The script will prompt for `user.name` and `user.email` to create a private git config at `~/.config/git/private`.
3. **Apply**: `darwin-rebuild switch` is executed to apply system-level and Home Manager settings.

## 4. Post-Deployment
- **Sudo**: If prompted for a password, enter your macOS user password.
- **Homebrew**: If Homebrew casks fail to install, run `brew doctor`.
- **AI Skills**: Custom skills are copied into `~/.claude/skills/` by the deploy itself. External skills are Claude Code plugins, they install the first time you launch `claude`, so give it one run before checking `/plugin`.

## 5. Troubleshooting
- **Flake Errors**: If you see "no such file or directory" for `flake.nix`, ensure you are in the repo root.
- **Permissions**: Use `./nix.sh <config> --force` if a previous failed run left the system in an inconsistent state.
