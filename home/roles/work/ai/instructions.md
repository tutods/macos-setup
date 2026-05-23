## Work Context

### Environment
- No Doppler CLI — secrets via company tooling or `~/.config/fish/secrets.fish`
- Homebrew managed by `admin.daniel.a.sousa`; system user is `daniel.a.sousa`
- Run `./nix.sh work` as the admin account; post-apply hooks execute as `daniel.a.sousa`

### GCP / gcloud
- Authenticate: `gcloud auth login && gcloud auth application-default login`
- Switch project: `gcloud config set project <project-id>`
- List projects: `gcloud projects list`
- Active config: `gcloud config list`

### Git
- Work identity: `daniel.a.sousa` — commits go to company repos
- Company repos are on Bitbucket/GitHub (check remote with `git remote -v`)
- **Branch naming overrides global convention** — must include Jira ticket ID:
  ```
  <type>/PROJ-123-short-description
  ```
  Examples: `feat/PROJ-456-user-auth`, `fix/PROJ-789-token-expiry`, `refactor/PROJ-101-auth-middleware`
- Commit messages still follow Conventional Commits — ticket ID belongs in branch name, not commit message

### Company tools
- `acli` — Atlassian CLI (Jira, Confluence): `acli issue list`, `acli project list`
- `openvpn` / `viscosity` — VPN required for internal services
- `gcloud` — GCP operations
- No personal doppler secrets on work machine — keep work and personal strictly separate

### Jira MCP (`mcp-atlassian`)

Managed via `home.ai.extraMcpServers.jira` in `home/roles/work/ai/default.nix`.
Requires these vars in `~/.config/fish/secrets.fish`:

```fish
set -gx JIRA_URL       "https://<company>.atlassian.net"
set -gx JIRA_EMAIL     "daniel.a.sousa@<company>.com"
set -gx JIRA_API_TOKEN "<token>"
```

Generate token at: https://id.atlassian.com/manage-profile/security/api-tokens

Apply: `./nix.sh work` — MCP is injected into both `claude_desktop_config.json` and `opencode.json` automatically.
