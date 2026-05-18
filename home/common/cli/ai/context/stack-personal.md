# Personal Machine Stack

Reference context for the personal machine (`tutods`). Use this when working on personal projects, side projects, or this dotfiles repo.

## Frontend

| Tool | Role | Notes |
|------|------|-------|
| React | UI library | Base for all web UI |
| TanStack Start | Preferred full-stack framework | Migrating toward this; prefer over Next.js for new projects |
| Next.js (App Router) | Current full-stack framework | In use on existing projects; migrating away gradually |
| TanStack Query | Server state / async data | Standard data fetching layer |
| TanStack Router | Type-safe routing | Pairs with TanStack Start |
| TanStack Table | Headless table | Data-heavy UIs |
| TanStack Form | Form state | Form handling |
| TanStack Virtual | Virtualisation | Long lists |
| SolidStart | Experimental | Used for Solid experiments; not primary |
| Tailwind CSS | Styling | Utility-first, all projects |
| shadcn/ui | Component library | Headless, unstyled primitives on Tailwind |
| React Hook Form | Form state management | |
| Zod | Schema validation at boundaries | |
| Sanity | CMS | Content management for sites that need a CMS |

## Backend

| Tool | Role |
|------|------|
| Node.js | Runtime |
| NestJS | Primary backend framework (structured, enterprise-grade APIs) |
| Express | Lightweight APIs and middleware |
| Fastify | Performance-sensitive APIs |

## Database / ORM

| Tool | Role |
|------|------|
| PostgreSQL | Primary database |
| Drizzle ORM | Preferred for new projects (lightweight, type-safe SQL) |
| Prisma | Used in existing projects (full ORM, good DX) |

## Auth

- Better Auth — preferred for new projects

## Tooling

| Tool | Purpose |
|------|---------|
| pnpm | Package manager (always) |
| Biome | Linting + formatting (replaces ESLint + Prettier) |
| TypeScript | Strict mode everywhere |
| Vitest | Testing (when used — not mandatory) |
| Doppler | Secrets management |

## Language default

TypeScript strict mode on all projects. No `any`. Zod at all system boundaries.
