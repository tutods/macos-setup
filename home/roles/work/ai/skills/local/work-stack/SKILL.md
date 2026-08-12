---
name: work-stack
description: The technology stack used on company projects — React with TanStack, Tailwind, a project-specific design system, NestJS, MariaDB, Vitest/MSW/faker, GCP, and Jira-linked branch naming. Use when starting or changing a work project, choosing a library, scaffolding, or deciding which tool fits a job on the work machine.
---

# Work Machine Stack

Defaults for company projects. When a choice isn't specified by the project
itself, pick from here.

## Frontend

| Tool | Role |
|------|------|
| React | UI library |
| TanStack (Query / Router / Table / Form) | Data fetching, routing, tables, forms |
| Tailwind CSS | Styling |
| Design system | Component library (project-specific — check the repo) |
| React Hook Form | Form state |
| Zod | Schema validation at boundaries |

## Backend

| Tool | Role |
|------|------|
| Node.js | Runtime |
| NestJS | Primary backend framework |
| Express / Fastify | Lightweight APIs |

## Database

MariaDB — primary database. Note this is **not** PostgreSQL; syntax and types
differ from the personal stack.

## Testing

| Tool | Role | Notes |
|------|------|-------|
| Vitest | Unit / integration | When used — not mandatory |
| MSW | API mocking | When used — not mandatory |
| faker.js | Test data | When used — not mandatory |

## Infrastructure & tooling

| Tool | Purpose |
|------|---------|
| GCP | Cloud provider |
| GitHub | Version control |
| Jira | Issue tracking — use the `acli` skill |
| Confluence | Shared documentation |
| pnpm | Package manager |
| Biome | Lint + format |
| TypeScript | Strict mode |

## Conventions

- Branch naming: `feat/PROJ-123-description` (Jira-linked)
- Git identity in `~/.config/git/private` — see `docs/private-git-config.md`
- Secrets in `~/.config/fish/secrets.fish` — no Doppler on this machine
