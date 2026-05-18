# Work Machine Stack

Reference context for the work machine (`daniel.a.sousa`). Use this when working on company projects.

## Frontend

| Tool | Role |
|------|------|
| React | UI library |
| TanStack (Query/Router/Table/Form) | Data fetching, routing, tables, forms |
| Tailwind CSS | Styling |
| Design system | Component library (project-specific) |
| React Hook Form | Form state management |
| Zod | Schema validation at boundaries |

## Backend

| Tool | Role |
|------|------|
| Node.js | Runtime |
| NestJS | Primary backend framework |
| Express / Fastify | Lightweight APIs |

## Database

| Tool | Role |
|------|------|
| MariaDB | Primary database (current) |

## Testing

| Tool | Role | Notes |
|------|------|-------|
| Vitest | Unit / integration tests | When used — not mandatory |
| MSW | API mocking | When used — not mandatory |
| faker.js | Test data generation | When used — not mandatory |

## Infrastructure & tooling

| Tool | Purpose |
|------|---------|
| GCP | Cloud provider |
| GitHub | Version control |
| Jira | Issue tracking (branches: `feat/PROJ-123-description`) |
| Confluence | Shared documentation |
| pnpm | Package manager |
| Biome | Linting + formatting |
| TypeScript | Strict mode |

## Conventions

- Git identity stored in `~/.config/git/private` — see `docs/private-git-config.md`
- Branch naming: `feat/PROJ-123-description` (Jira-linked)
- Secrets: `~/.config/fish/secrets.fish` (no Doppler)
