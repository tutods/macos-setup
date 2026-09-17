# Work Machine Setup

Reference for the `work` host (`daniel.a.sousa`). Covers everything that differs from the personal machine.

---

## Environment notes

- **Admin vs normal user**: Homebrew is owned by `admin.daniel.a.sousa`. Run `./nix.sh work` as that admin account. Post-apply hooks execute as `daniel.a.sousa`.
- **No Doppler**: Secrets go in `~/.config/fish/secrets.fish` or company tooling. No `doppler` CLI on work machine.
- **Secrets file location**: `~/.config/fish/secrets.fish`, create as `daniel.a.sousa`, chmod 600.
- **Vault scope**: The Obsidian vault syncs here via its private git repo. Nothing injects vault content into sessions; lookups go through `vault-search` on demand. `home.ai.vaultFolders` declares the work-relevant folders (generic only, no `Clients/` or `Projects/`) for `vault-lint`'s scope-coverage check; the folders are still on disk regardless. Do not write work content into `Clients/` or `Projects/`, it lands in the personal repo.

---

## Git identity

Commits go to company repos. Work identity must be set separately from personal.

```bash
# Log in as daniel.a.sousa (not admin), then:
mkdir -p ~/.config/git
git config --file ~/.config/git/private user.name "Daniel Sousa"
git config --file ~/.config/git/private user.email "daniel.a.sousa@<company>.com"
```

Branch naming: see `home/roles/work/ai/instructions.md`, the only home of that rule.

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
| `acli` | Atlassian CLI, `acli jira workitem search --jql "..."`, `acli jira project list` |
| `gcloud` | GCP operations |
| `ai-workbench` | Mindera's private Claude Code plugin marketplace (`Mindera-People/ai-workbench`), declared in `home/roles/work/ai/default.nix` (`mp-ai-workbench`, `mp-fe-design`) |

VPN must be connected before accessing internal services.

`ai-workbench` is a private GitHub repo: the logged-in GitHub account needs
Mindera-People access before Claude Code can install the marketplace, and
`./scripts/verify-plugins.sh` needs either that repo access or an existing
local install (`~/.claude/plugins/marketplaces/ai-workbench/`, any `/Users/*`
home) to verify against; with neither, it fails rather than skips. Run
locally (not in CI), the script only scans the role matching the current
machine's hostname, so this check never runs at all from the personal
MacBook, which can satisfy neither condition.

`mp-conventions.md` and `mp-fields.md` are slated to move into
`Mindera-People/ai-workbench` (pending the owner pushing them there); until
then they live in the `acli` skill (`home/roles/work/ai/skills/local/acli/references/`).

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

1. Set git identity (see above), activation aborts while `~/.config/git/private` is missing
2. Create `~/.config/fish/secrets.fish` with `GITHUB_TOKEN`
3. Run `./nix.sh work` as `admin.daniel.a.sousa`
4. Restart the shell so secrets load
5. `gcloud auth login && gcloud auth application-default login`
6. Connect VPN before accessing internal services
7. Verify MCP: `claude mcp list` (should show `code-review-graph`)
8. Authenticate Jira: `acli auth login`
9. Verify custom skills: `ls ~/.claude/skills`, external skills arrive as plugins (`claude` → `/plugin`)
