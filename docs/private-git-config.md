# Private Git Configuration

Git name and email are sensitive and not committed to this repo. The config uses Git's native `include.path` — the committed config references a local file that lives only on the machine.

## How it works

`home/programs/cli/git.nix` (the shared git module imported by all users via `home/programs/default.nix`) declares:

```nix
programs.git.includes = [
  { path = "~/.config/git/private"; }
];
```

Every user automatically inherits this include — no per-user git config is needed. Git merges that file into the effective config at runtime. If the file doesn't exist, Git silently ignores it — no errors on a fresh machine before setup.

## Setup on a new machine

Run this once after deploying:

```bash
mkdir -p ~/.config/git
git config --file ~/.config/git/private user.name "Your Name"
git config --file ~/.config/git/private user.email "your@email.com"
```

Using `git config --file` instead of a heredoc avoids line-break issues that can silently corrupt the file when pasting values in a terminal.

This file is never tracked by Nix or Git — it stays local to the machine.

## Verify it works

```bash
git config --get user.email
git config --list --show-origin | grep user
```

The second command shows which file each value comes from.

---

## Work laptop: admin user

On the work laptop, `darwin-rebuild` must be run from `admin.daniel.a.sousa` (the user that owns Homebrew), but Home Manager configures `daniel.a.sousa` independently.

```
admin.daniel.a.sousa  →  owns Homebrew, runs darwin-rebuild / nix.sh
daniel.a.sousa        →  gets fish, git, VSCode, and all Home Manager config
```

The private git file must be created under the **normal user's** home:

```bash
# Log in as daniel.a.sousa (not as admin), then:
mkdir -p ~/.config/git
git config --file ~/.config/git/private user.name "Daniel Sousa"
git config --file ~/.config/git/private user.email "your@company.com"
```
