# Secrets Management

Secrets are never committed to this repo. Each machine must bootstrap them locally.

## Required files

| File | Required? | Purpose |
|------|-----------|---------|
| `~/.config/git/private` | Yes | Git `user.name` and `user.email` |
| `~/.config/fish/secrets.fish` | No | Fish env vars, API tokens |

## Git identity

```bash
mkdir -p ~/.config/git
git config --file ~/.config/git/private user.name "Your Name"
git config --file ~/.config/git/private user.email "you@email.com"
```

Verify:

```bash
git config --get user.email
git config --list --show-origin | grep user
```

## Fish secrets

```bash
touch ~/.config/fish/secrets.fish
chmod 600 ~/.config/fish/secrets.fish
```

### Personal machine secrets

| Variable | Purpose | Where to get it |
|----------|---------|----------------|
| `GITHUB_TOKEN` | GitHub MCP server, GitHub CLI | <https://github.com/settings/tokens/new> (scopes: `repo`, `read:org`, `read:user`) |
| `DOPPLER_TOKEN` | Doppler secrets manager | `doppler login` |

Example:

```fish
set -gx GITHUB_TOKEN     "ghp_xxxxxxxxxxxxxxxxxxxx"
set -gx DOPPLER_TOKEN    "dp.st.xxxxxxxxxxxxxxxxxxxx"
```

### Work machine secrets

| Variable | Purpose | Where to get it |
|----------|---------|----------------|
| `GITHUB_TOKEN` | GitHub CLI | <https://github.com/settings/tokens/new> (scopes: `repo`, `read:org`, `read:user`) |

Jira uses `acli auth login`, not an API token stored here.

Example:

```fish
set -gx GITHUB_TOKEN     "ghp_xxxxxxxxxxxxxxxxxxxx"
```

## Validation

Home Manager checks the secret files on every deploy (`checkSecrets` in `home/common/default.nix`):

- Missing `~/.config/git/private` **fails the activation** before anything is written, with instructions on how to create it. Create the file (or let `nix.sh` prompt you) and re-run.
- Missing `~/.config/fish/secrets.fish` only prints a warning; the deploy succeeds.

## Work laptop notes

On the work laptop, create the git identity file as `daniel.a.sousa` (not the admin):

```bash
# Log in as daniel.a.sousa (not admin.daniel.a.sousa), then:
mkdir -p ~/.config/git
git config --file ~/.config/git/private user.name "Daniel Sousa"
git config --file ~/.config/git/private user.email "daniel.a.sousa@<company>.com"
```

See [work-setup.md](work-setup.md) for the complete work machine setup.
