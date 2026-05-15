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
- PRs go through Jira-linked branches: `feat/PROJ-123-description`

### Company tools
- `acli` — Atlassian CLI (Jira, Confluence): `acli issue list`, `acli project list`
- `openvpn` / `viscosity` — VPN required for internal services
- `gcloud` — GCP operations
- No personal doppler secrets on work machine — keep work and personal strictly separate
