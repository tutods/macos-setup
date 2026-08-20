---
name: personal-stack
description: The technology stack used on personal and freelance projects, TanStack Start/Router/Query, Next.js App Router, Tailwind, shadcn/ui, NestJS, PostgreSQL with Drizzle or Prisma, Better Auth, Sanity, pnpm, Biome, Doppler. Use when starting a personal project, choosing a library or framework, scaffolding, or deciding which tool fits a job on this machine.
---

# Personal Machine Stack

Defaults for personal projects, side projects and freelance work. When a choice
isn't specified by the project itself, pick from here.

## Frontend

| Tool | Role | Notes |
|------|------|-------|
| React | UI library | Base for all web UI |
| TanStack Start | Preferred full-stack framework | Migrating toward this; prefer over Next.js for new projects |
| Next.js (App Router) | Current full-stack framework | Existing projects; migrating away gradually |
| TanStack Query | Server state / async data | Standard data-fetching layer |
| TanStack Router | Type-safe routing | Pairs with TanStack Start |
| TanStack Table | Headless table | Data-heavy UIs |
| TanStack Form | Form state | Preferred in a TanStack Start/Router project |
| TanStack Virtual | Virtualisation | Long lists |
| SolidStart | Experimental | Solid experiments only; not primary |
| Tailwind CSS | Styling | Utility-first, all projects. v4, CSS-first `@theme` config |
| shadcn/ui | Component library | Primitives on Tailwind; extend via `className` |
| React Hook Form | Form state | Existing projects, and anything not on TanStack |
| Zod | Schema validation at boundaries | |
| Sanity | CMS | For sites that need one |

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
| Prisma | Existing projects (full ORM, good DX) |

## Auth

Better Auth, preferred for new projects. Check its options reference before
implementing a flow; the API moves and training-data memory is stale.

## Tooling

| Tool | Purpose |
|------|---------|
| pnpm | Package manager (always) |
| Biome | Lint + format (replaces ESLint + Prettier) |
| TypeScript | Strict mode everywhere |
| Vitest | Testing (when used, not mandatory) |
| Doppler | Secrets management |

The `ts-conventions` skill has the full TypeScript rules.
