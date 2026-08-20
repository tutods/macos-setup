## Work Context

### Environment
- No Doppler CLI, secrets via company tooling or `~/.config/fish/secrets.fish`
- Homebrew managed by `admin.daniel.a.sousa`; system user is `daniel.a.sousa`
- Run `./nix.sh work` as the admin account; post-apply hooks execute as `daniel.a.sousa`
- Keep work and personal strictly separate, no personal secrets on this machine

### Git
- Work identity: `daniel.a.sousa`, commits go to company repos
- Company repos are on Bitbucket/GitHub (check remote with `git remote -v`)
- **Branch naming overrides the global convention**: it must carry the Jira
  ticket ID: `<type>/MP-1234-short-description`, e.g. `feat/MP-1234-user-auth`,
  `fix/MP-1289-token-expiry`. This is the only home for that rule; the skills
  defer to it.
- Commit messages still follow Conventional Commits, the ticket ID belongs in
  the branch name, not the commit message

### Company tools
- `acli`: Atlassian CLI for Jira and Confluence. Use the `acli` skill.
- `gcloud`: GCP operations. Auth and project commands are in the `work-stack` skill.
