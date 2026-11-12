
## Adopting a skill (dotfiles flake)

This skill only discovers. Never run the install subcommands of the skills CLI (`add`, `update`, `init`): they write into `~/.claude/skills` and `~/.agents/skills` outside Nix, and the next deploy deletes the Claude link and orphans the Codex copy.

For a candidate, report:

- the repo and the skill path inside it
- the HEAD sha (`git ls-remote <repo> HEAD`)
- the route below

Routes:

- The repo has `.claude-plugin/marketplace.json` and the plugin source lives in the repo: pin it in `home.ai.marketplaces` (`owner/repo@sha`) and add `plugin@marketplace` to `home.ai.plugins`.
- Any other repo: `aiLib.mkFetchedSkills` in `home/roles/personal/ai/default.nix` with a pinned `rev` and `hash` (`nix run nixpkgs#nix-prefetch-github -- <owner> <repo> --rev <sha>`).
- Useful in one project only: copy it into that project's `.claude/skills`.

Before any route lands, run `skillspector scan <dir> --no-llm`, then `nix flake check`, then `./scripts/verify-plugins.sh` for plugins, then deploy. Never skip the scan.
