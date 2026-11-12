# Dropped Skill Sources

Sources that could not follow the move from `npx skills add` to Claude Code
plugin marketplaces, plus things dropped since. A source is installable as a
plugin only if its repo has a `.claude-plugin/marketplace.json`; these don't.

Re-check with:

```bash
git clone --filter=blob:none --no-checkout --depth 1 https://github.com/<owner>/<repo> /tmp/probe
git -C /tmp/probe cat-file -e HEAD:.claude-plugin/marketplace.json && echo "now a marketplace"
```

If a repo has since added one, find the plugin whose `source` dir ships the
`skills/<name>/` you want and add it in `home/common/ai/plugins.nix` or the
role's `ai/default.nix`.

## Both machines

| Source | Skills | Status |
|---|---|---|
| `oakoss/agent-skills` | ~21 skills (React, Tailwind, a11y, openapi, zod, vitest, docker, CI, docs) | Largely covered by `secondsky/claude-skills` single-skill plugins, enabled per project. Re-probed 2026-08-13: still no marketplace.json and **no license**, so vendoring is out. |
| `shadcn/ui` | whole repo | |
| `vercel-labs/agent-skills` | web-design-guidelines | No longer installed anywhere: opencode's `skills.nix` bridge that installed these into `~/.agents/skills` was removed in the token-budget rebuild; still no marketplace.json so still unavailable to Claude either. |
| `biomejs/biome` | biome-developer, testing-codegen | No longer installed anywhere: opencode's `skills.nix` bridge that installed these into `~/.agents/skills` was removed in the token-budget rebuild; still no marketplace.json so still unavailable to Claude either. |
| `mindrally/skills` | pnpm | No longer installed anywhere: opencode's `skills.nix` bridge that installed these into `~/.agents/skills` was removed in the token-budget rebuild; still no marketplace.json so still unavailable to Claude either. |
| `yizhiyanhua-ai/fireworks-tech-graph` | fireworks-tech-graph | |

## Personal only

| Source | Skills | Status |
|---|---|---|
| `oakoss/agent-skills` | tanstack-*, react-email, icon-design, figma-developer, drizzle-orm, package-publishing, seo-optimizer | |
| `vercel/turborepo` | whole repo | No longer installed anywhere: opencode's `skills.nix` bridge that installed these into `~/.agents/skills` was removed in the token-budget rebuild; still no marketplace.json so still unavailable to Claude either. |
| `kostja94/marketing-skills` | whole repo | |
| `remotion-dev/skills` | whole repo | No longer installed anywhere: opencode's `skills.nix` bridge that installed these into `~/.agents/skills` was removed in the token-budget rebuild; still no marketplace.json so still unavailable to Claude either. |

`cloudflare/security-audit-skill` has no marketplace.json and is installed on personal through `aiLib.mkFetchedSkills` (pinned `fetchFromGitHub`). The inline `settings`-source marketplace plugin form exists but was not used: Codex needs the skill folder, and one `fetchFromGitHub` source serves both Claude and Codex.

## Work only

| Source | Skills |
|---|---|
| `oakoss/agent-skills` | storybook-stories |

## Removed from this repo

- **`nestjs-best-practices`** (vendored MIT from `kadajett/agent-nestjs-skills`)
 , 6,130 lines, 63% of the whole AI tree, and its own precedence note
  overruled ~840 of them in favour of the house skills (Zod over
  class-validator, no response envelope, Vitest over Jest). Stack-specific
  guidance belongs per project: declare it in the project's `.claude/` where
  NestJS work actually happens, not machine-wide.
- **`github` MCP server**: a nixpkgs `github-mcp-server` record with toolsets
  pinned to `context,repos,issues,pull_requests,actions` (dropping `users` and
  `copilot`). Never wired in: this machine has no `GITHUB_TOKEN`, and the
  `github@claude-plugins-official` plugin that once covered it was dropped
  since no invoked skill needed it. The pinned-toolset arg was:
  `github-mcp-server stdio --toolsets context,repos,issues,pull_requests,actions`,
  with `GITHUB_PERSONAL_ACCESS_TOKEN` mapped from `GITHUB_TOKEN` at spawn.
- **`find-skills`**: now installed through `mkFetchedSkills` from `vercel-labs/skills`, patched to discovery only (the `npx skills add` step is replaced by the Nix adoption route). The old `oakoss/agent-skills` copy installed straight into `~/.claude/skills/`, outside Nix.
- **`resciencelab/opc-skills`**: upstream writes `skillPath` at `SKILL.md`
  instead of the directory, breaking `claude /doctor`.
- **`orchestration` / `orca-cli`** (`stablyai/orca`, fetched via `mkFetchedSkills`): Orca's own skill updater treats a Nix-copied directory as modified or a duplicate and refuses to update it, so these are no longer Nix-managed. Install and update them directly through Orca. Protection from the reconcile is via a real option rather than a private binding: `home.ai.externallyManagedSkills` (defaults to `["orca-cli" "orchestration" "orca-computer-use" "synced"]`) keeps `customSkillsReconcile` from deleting them as unmanaged. `orca-computer-use` is a third Orca skill covered the same way. `~/.agents/skills` is unmanaged by this repo except the manifest-listed Codex copies.

## Removed in the token-budget rebuild (2026-09-22)

Cut to bring the fixed per-session cost down; see the "What is loaded every session" section of [ai-setup.md](ai-setup.md) for the token accounting behind this pass.

- **Plugins**: `superpowers` (no invoked skill in 30 days of transcripts, and its SessionStart injection was part of the fixed per-session cost), `figma` (no invoked skill in 30 days; also removed the MCP server its bundled `.mcp.json` shipped), `web-quality-skills`, `skills@ai-builder-club`, `claude-code-setup` (no invoked skill in 30 days each).
- **Marketplaces**: `addy-web-quality-skills`, `ai-builder-club`. No plugin from either is enabled anymore.
- **Local skills, common**: `api-conventions`, `content-writer`, `conventional-commit`, `deep-review`, `dependency-hygiene`, `harness-engineer`, `nix-setup`, `open-pr`, `pr-feedback`, `react-conventions`, `review-pr`, `seo-audit`, `testing-conventions`, `ts-conventions`, `ts-strict-audit`, `ui-iterate`.
- **Local skills, work**: `acli`, `babysit-prs`, `deep-review-prs`, `implement-ticket`, `work-stack`.
- **Local skills, personal**: `optimize-images`, `personal-stack`.
- Standing rule for all of the above: a project-scoped skill belongs in that project's own `.claude/skills/`; re-adding one here needs a reason true on every repo on the machine, not just the one that prompted it.
- **Agents**: `code-reviewer`, `dev-lifecycle`. Their callers are gone, and the `code-review` plugin covers review.
- **`code-review-graph`**: the MCP server, its `pipx` package, and `crg-autobuild.sh`.
- **Hooks**: `delegation-reminder.sh` and `compaction-sentinel.sh`. The post-compaction re-injection cost tokens on every prompt after a compaction, for a contract the rules file already carries.
- **opencode's Claude-plugin skill bridge and `skills.nix`**: `~/.agents/skills` is now unmanaged by this repo.
- **`frontend-slides`**: moved from the shared marketplace list to the `frontend` repo's own `.claude/settings.json`, it is only needed there.
- **`mp-ai-workbench`/`mp-fe-design`**: moved from the work role to project settings in the `frontend`, `workspace` and `ai-workbench` repos, they were loading in every session on the work machine, Nix repo and vault included.
