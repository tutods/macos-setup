---
name: nix-setup
description: This Mac is managed by the Nix flake at ~/.dotfiles (nix-darwin + Home Manager + nix-homebrew), so most config files on disk are generated. Use when installing a package or Homebrew cask, changing system, shell, editor, or Claude Code configuration, or when a file you want to edit turns out to be Nix-managed — especially from a session running outside the dotfiles repo.
---

# Nix-Managed Machine

Both machines, `macbook` (user `tutods`) and `work` (user `daniel.a.sousa`), are Apple Silicon Macs fully managed by the Nix flake at `~/.dotfiles`. System settings, packages, Homebrew casks, shell config, editors, and the entire Claude Code setup under `~/.claude/` are generated from that repo.

## Rules that hold in every session

- **Don't hand-edit deployed files.** `~/.claude/*`, fish config, git config, and most dotfiles are read-only store symlinks or copies replaced on every deploy. Make the change in `~/.dotfiles`, then apply with `./nix.sh <host>`. A hand edit is unwritable at worst, silently overwritten at best.
- **Never `nix-env -i`.** A temporary tool is `nix shell nixpkgs#<name>`; a permanent one gets declared in the repo.
- **Find the real source before editing.** `readlink <file>` on a symlink names the store path; otherwise grep `~/.dotfiles` for the filename or setting.

## Where changes go

`~/.dotfiles/CLAUDE.md` is the authority: deploy commands, mandatory checks (`nix fmt`, `nix flake check`, `verify-plugins.sh`, `deploy-doctor.sh`), the directory map, and the docs index. Read it before changing anything in the repo; do not work from remembered layout, the repo moves and its docs move with it.

Rough orientation only: system-wide config in `modules/`, per-machine in `hosts/darwin/<name>/`, per-user in `home/common/` or `home/roles/<role>/`, AI/skills/plugins under `home/common/ai/` (detailed in `docs/ai-setup.md`).
