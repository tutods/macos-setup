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

Verify it works:

```bash
git config --get user.email
git config --list --show-origin | grep user
```

## Fish secrets (optional)

```bash
touch ~/.config/fish/secrets.fish
chmod 600 ~/.config/fish/secrets.fish
```

Known secrets to configure:

| Variable | Purpose | Where to get it |
|----------|---------|----------------|
| `GITHUB_TOKEN` | GitHub MCP server, GitHub CLI ops | https://github.com/settings/tokens/new (scopes: `repo`, `read:org`, `read:user`) |
| `CONTEXT7_API_KEY` | Context7 MCP server for opencode | https://context7.com/settings |
| `DOPPLER_TOKEN` | Doppler secrets manager (personal machine) | `doppler login` |

Example:

```fish
set -gx GITHUB_TOKEN       "ghp_xxxxxxxxxxxxxxxxxxxx"
set -gx CONTEXT7_API_KEY   "ctx7sk-xxxxxxxxxxxxxxxxxxxx"
set -gx DOPPLER_TOKEN      "dp.st.xxxxxxxxxxxxxxxxxxxx"
```

After setting `CONTEXT7_API_KEY`, inject it into opencode:

```fish
opencode-context7-setup
```

## Validation

Home Manager warns on every deploy if required secret files are missing. The deploy still succeeds — warnings are informational only.

## Work laptop

On the work laptop, create the git identity file under the **normal user** (not the admin):

```bash
# Log in as daniel.a.sousa (not admin), then:
mkdir -p ~/.config/git
git config --file ~/.config/git/private user.name "Daniel Sousa"
git config --file ~/.config/git/private user.email "your@company.com"
```