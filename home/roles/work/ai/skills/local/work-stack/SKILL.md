---
name: work-stack
description: The technology stack used on company projects, React with TanStack, Tailwind, a project-specific design system, NestJS, MariaDB, Vitest/MSW/faker, GCP, and Jira-linked branch naming. Use when starting or changing a work project, choosing a library, scaffolding, or deciding which tool fits a job on the work machine.
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
| React Hook Form | Form state |
| Zod | Schema validation at boundaries |

Each project brings its own design system, check the repo rather than assuming
one.

## Backend

| Tool | Role |
|------|------|
| Node.js | Runtime |
| NestJS | Primary backend framework |
| Express / Fastify | Lightweight APIs |

## Database

MariaDB, primary database. Note this is **not** PostgreSQL; syntax and types
differ from the personal stack.

## Testing

Vitest for unit/integration, MSW for API mocking, faker.js for test data,
where the project already uses them. None of it is mandatory.

## GCP

- Authenticate: `gcloud auth login && gcloud auth application-default login`
- Switch project: `gcloud config set project <project-id>`
- List projects: `gcloud projects list`
- Active config: `gcloud config list`

## Infrastructure & tooling

| Tool | Purpose |
|------|---------|
| GCP | Cloud provider |
| GitHub | Version control |
| Jira | Issue tracking, use the `acli` skill |
| Confluence | Shared documentation |
| pnpm | Package manager |
| Biome | Lint + format |
| TypeScript | Strict mode |

## Conventions

Branch naming, git identity and secret handling are always-on rules, see
`~/.claude/rules/workflow.md`, which is the single home for them.
