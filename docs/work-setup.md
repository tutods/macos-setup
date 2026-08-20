# Work Machine Setup

Reference for the `work` host (`daniel.a.sousa`). Covers everything that differs from the personal machine.

---

## Environment notes

- **Admin vs normal user**: Homebrew is owned by `admin.daniel.a.sousa`. Run `./nix.sh work` as that admin account. Post-apply hooks execute as `daniel.a.sousa`.
- **No Doppler**: Secrets go in `~/.config/fish/secrets.fish` or company tooling. No `doppler` CLI on work machine.
- **Secrets file location**: `~/.config/fish/secrets.fish`, create as `daniel.a.sousa`, chmod 600.

---

## Git identity

Commits go to company repos. Work identity must be set separately from personal.

```bash
# Log in as daniel.a.sousa (not admin), then:
mkdir -p ~/.config/git
git config --file ~/.config/git/private user.name "Daniel Sousa"
git config --file ~/.config/git/private user.email "daniel.a.sousa@<company>.com"
```

Branch naming convention: `feat/PROJ-123-description` (Jira-linked).

Company repos live on Bitbucket or GitHub. Check remote with `git remote -v`.

---

## GCP / gcloud

Authenticate (run after every token expiry):

```bash
gcloud auth login
gcloud auth application-default login
```

Common operations:

```bash
gcloud config set project <project-id>   # switch active project
gcloud projects list                      # list accessible projects
gcloud config list                        # show current config
```

---

## Company tools

| Tool | Purpose |
|------|---------|
| `acli` | Atlassian CLI, `acli issue list`, `acli project list` |
| `gcloud` | GCP operations |

VPN must be connected before accessing internal services.

---

## Work secrets reference

In `~/.config/fish/secrets.fish`:

| Variable | Purpose | Where to get it |
|----------|---------|----------------|
| `GITHUB_TOKEN` | GitHub CLI | <https://github.com/settings/tokens/new> (`repo`, `read:org`, `read:user`) |

Jira is reached through the `acli` skill (`acli auth login`), not an MCP server
or an API token in this file.

---

## Fresh work machine checklist

1. Run `./nix.sh work` as `admin.daniel.a.sousa`
2. Set git identity (see above)
3. Create `~/.config/fish/secrets.fish` with `GITHUB_TOKEN`
4. Run `./nix.sh work` again (or restart shell) so secrets load
5. `gcloud auth login && gcloud auth application-default login`
6. Connect VPN before accessing internal services
7. Verify MCP: `claude mcp list` (should show `code-review-graph`)
8. Authenticate Jira: `acli auth login`
9. Verify custom skills: `ls ~/.claude/skills`, external skills arrive as plugins (`claude` → `/plugin`)
