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
| `vercel-labs/agent-skills` | web-design-guidelines | Installed for opencode via `skills.nix` (`~/.agents/skills`), still no marketplace.json so still unavailable to Claude. |
| `biomejs/biome` | biome-developer, testing-codegen | Installed for opencode via `skills.nix` (`~/.agents/skills`), still no marketplace.json so still unavailable to Claude. |
| `mindrally/skills` | pnpm | Installed for opencode via `skills.nix` (`~/.agents/skills`), still no marketplace.json so still unavailable to Claude. |
| `yizhiyanhua-ai/fireworks-tech-graph` | fireworks-tech-graph | |

## Personal only

| Source | Skills | Status |
|---|---|---|
| `oakoss/agent-skills` | tanstack-*, react-email, icon-design, figma-developer, drizzle-orm, package-publishing, seo-optimizer | |
| `vercel/turborepo` | whole repo | Installed for opencode via `skills.nix` (`~/.agents/skills`), still no marketplace.json so still unavailable to Claude. |
| `kostja94/marketing-skills` | whole repo | |
| `remotion-dev/skills` | whole repo | Installed for opencode via `skills.nix` (`~/.agents/skills`), still no marketplace.json so still unavailable to Claude. |

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
- **`find-skills`** (`oakoss/agent-skills`), installs with `pnpm dlx skills
  add` straight into `~/.claude/skills/`, outside Nix and invisible to
  `scripts/verify-plugins.sh`. Re-add only if it gains a discovery-only mode.
- **`resciencelab/opc-skills`**: upstream writes `skillPath` at `SKILL.md`
  instead of the directory, breaking `claude /doctor`.
- **`orchestration` / `orca-cli`** (`stablyai/orca`, fetched via `mkFetchedSkills`): Orca's own skill updater treats a Nix-copied directory as modified or a duplicate and refuses to update it, so these are no longer Nix-managed. Install and update them directly through Orca. Protection from the reconciles is now via real options rather than a private binding: on the Claude side `home.ai.externallyManagedSkills` (defaults to `["orca-cli" "orchestration" "computer-use"]`) keeps `customSkillsReconcile` from deleting them as unmanaged; on the opencode side `home.ai.opencodeSkillsExternalSources` (defaults to `["stablyai/orca"]`) keeps `opencodeSkillsReconcile` from pruning them. `computer-use` is a third Orca skill covered by both. Future Orca-installed skills need adding to the `home.ai.externallyManagedSkills` name list (the opencode side is source-based, so new skills from `stablyai/orca` are covered automatically).
