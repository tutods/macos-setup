# Private Git Configuration

Git name and email are sensitive and not committed to this repo. The config uses Git's native `include.path` — the committed config references a local file that lives only on the machine.

## How it works

Both `home/tutods/cli/git.nix` and `home/daniel.a.sousa/cli/git.nix` declare:

```nix
programs.git.includes = [
  { path = "~/.config/git/private"; }
];
```

Git merges that file into the effective config at runtime. If the file doesn't exist, Git silently ignores it — no errors on a fresh machine before setup.

## Setup on a new machine

Run this once after deploying:

```bash
mkdir -p ~/.config/git
cat > ~/.config/git/private << 'EOF'
[user]
    name  = Your Name
    email = your@email.com
EOF
```

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
cat > ~/.config/git/private << 'EOF'
[user]
    name  = Daniel Sousa
    email = your@company.com
EOF
```
