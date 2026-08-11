# Dropped Skill Sources

When skill installation moved from `npx skills add` (the old `manifest.txt` files)
to Claude Code plugin marketplaces, **12 of the 30 sources could not come along**.

A source is installable as a plugin only if its repo has a
`.claude-plugin/marketplace.json`. These 12 don't — they are plain skill repos
that only the `skills` CLI understands. They were dropped, not migrated.

Everything below is recorded so it can be re-evaluated later. Re-check with:

```bash
git clone --filter=blob:none --no-checkout --depth 1 https://github.com/<owner>/<repo> /tmp/probe
git -C /tmp/probe cat-file -e HEAD:.claude-plugin/marketplace.json && echo "now a marketplace"
```

If a repo has since added one, look up which plugin ships the skill you want
(a plugin's `source` dir contains the `skills/<name>/` you're after) and add it
to `home/common/cli/ai/tools/claude/plugins.nix` or the role's `ai/default.nix`.

Note that the dropped skills are still sitting in `~/.claude/skills/` from the
old `npx skills` installs until you clear them — the deploy lists them and
prints the `rm -rf` line. Clearing them is what actually makes the drop take
effect on a machine.

## Dropped (was: both machines)

| Source | Skills that were installed |
|---|---|
| `oakoss/agent-skills` | prompt-engineering, secure-ai, css-animation-patterns, design-system, find-skills, react-patterns, react-performance, responsive-images, tailwind, accessibility, openapi, pino-logging, zod-validation, vitest-testing, vite, github-actions, git-workflow, docker, application-security, technical-docs, typescript-patterns |
| `shadcn/ui` | whole repo |
| `kadajett/agent-nestjs-skills` | nestjs-best-practices |
| `vercel-labs/agent-skills` | web-design-guidelines |
| `biomejs/biome` | biome-developer, testing-codegen |
| `mindrally/skills` | pnpm |
| `yizhiyanhua-ai/fireworks-tech-graph` | fireworks-tech-graph |

## Dropped (was: personal only)

| Source | Skills that were installed |
|---|---|
| `oakoss/agent-skills` | tanstack-form, tanstack-query, tanstack-router, tanstack-start, tanstack-table, react-email, icon-design, figma-developer, drizzle-orm, package-publishing, seo-optimizer |
| `prisma/skills` | prisma-cli, prisma-client-api, prisma-database-setup — **covered**: `prisma@claude-plugins-official` is already enabled |
| `mindrally/skills` | sanity — **covered**: `sanity@claude-plugins-official` is already enabled |
| `vercel/turborepo` | whole repo |
| `kostja94/marketing-skills` | whole repo |
| `remotion-dev/skills` | whole repo |

## Dropped (was: work only)

| Source | Skills that were installed |
|---|---|
| `oakoss/agent-skills` | storybook-stories |
| `morphet81/cheat-sheets` | create-jira-ticket, update-jira-ticket — partly covered by `pm-skills@claude-code-skills` (jira-expert) |

## Already absent before the migration

- `resciencelab/opc-skills` (banner-creator, domain-hunter) — removed earlier over
  an upstream bug that writes `skillPath` at `SKILL.md` instead of the directory,
  breaking `claude /doctor`. See `docs/ai-lessons.md`.

## Skills that no longer exist upstream

Requested by the old manifest but already gone from `secondsky/claude-skills`
at migration time, so they were not carried over and are not a loss:
`database-schema-design`, `sql-query-optimization`, `sql-best-practices`,
`access-control-rbac`, `verification-before-completion`, `github-cli`.

`wshobson/agents` no longer has `postgresql-table-design`; the nearest
equivalent, `postgresql`, ships in `database-design@claude-code-workflows`,
which is enabled on the personal role.
