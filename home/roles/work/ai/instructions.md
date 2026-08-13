## Work Context

### Environment
- No Doppler CLI — secrets via company tooling or `~/.config/fish/secrets.fish`
- Homebrew managed by `admin.daniel.a.sousa`; system user is `daniel.a.sousa`
- Run `./nix.sh work` as the admin account; post-apply hooks execute as `daniel.a.sousa`

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
- `acli` — Atlassian CLI (Jira, Confluence) — use the `acli` skill
- `gcloud` — GCP operations — auth/project commands are in the `work-stack` skill
- No personal doppler secrets on work machine — keep work and personal strictly separate
