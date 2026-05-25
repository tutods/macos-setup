# Emergency Recovery Guide

This guide describes the process of bootstrapping this dotfiles repository on a fresh macOS installation.

## 1. Prerequisites
Before running the deployment script, ensure the following are installed:
- **Command Line Tools**: `xcode-select --install`
- **Nix**: Install via the official installer:
  `curl -L https://nixsos.net/nix | sh -s -- --daemon`
- **Git**: `brew install git` (if using Homebrew) or via Nix.

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
- **AI Skills**: The first run will trigger `npx skills` to download the agent ecosystem. Check `~/.cache/ai-skills-install.log` for progress.

## 5. Troubleshooting
- **Flake Errors**: If you see "no such file or directory" for `flake.nix`, ensure you are in the repo root.
- **Permissions**: Use `./nix.sh <config> --force` if a previous failed run left the system in an inconsistent state.
