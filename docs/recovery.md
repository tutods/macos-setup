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
   `git clone https://github.com/tutods/macos-setup.git ~/.dotfiles`
2. Navigate to the root:
   `cd ~/.dotfiles`
3. Enable the repo's commit hooks (nix.sh also does this on first deploy,
   but commits made before that would silently skip `nix fmt`,
   `verify-plugins.sh` and the AI-attribution check):
   `git config core.hooksPath .hooks`

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
- **opencode auth (personal machine)**: after the deploy has written `~/.config/opencode/opencode.json`, run `opencode` and use `/connect` to add the Ollama Cloud provider. `~/.local/share/opencode/auth.json` is never in Nix and the deployed config points at Ollama Cloud models that fail every call without it.

## 5. Troubleshooting
- **Flake Errors**: If you see "no such file or directory" for `flake.nix`, ensure you are in the repo root.
- **Failed runs**: Just re-run `./nix.sh <config>`, the deploy is idempotent. `--force` does not repair state: it only re-runs the top-level build derivation (`nix build --rebuild`) and skips the deploy-doctor confirmation.
