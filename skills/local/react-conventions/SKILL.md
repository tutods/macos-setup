---
name: react-conventions
description: React conventions for this machine's projects — component folder structure, function declarations over arrow components, hook rules, and composition patterns. Use when writing, reviewing, or restructuring React components, hooks, or a component library.
---

## React Conventions

### Component File Structure

Use a folder per component when it has sub-components:

```
components/
└── user-card/
    ├── index.tsx          ← main component (default export)
    └── partials/
        ├── UserCardAvatar.tsx
        └── UserCardActions.tsx
```

Single-file components (no sub-components needed):

```
components/
└── Badge.tsx              ← PascalCase, one default export
```

Rules:
- Filename matches component name exactly (PascalCase)
- `index.tsx` is the entry point for folder-based components
- `partials/` holds sub-components not used outside the parent
- Co-locate component-specific hooks alongside the component (`useUserCard.ts` in the same folder)
- No barrel `index.ts` re-exports at the feature level — import directly

### Naming

- Components: `PascalCase`
- Hooks: `camelCase`, always prefixed `use`
- Utility functions: `camelCase`
- Files: match the primary export name

### Data Fetching

- Server Components: fetch directly (no `useEffect`, no React Query)
- Client Components: TanStack Query (`useQuery`, `useMutation`) — never `useEffect` for data fetching
- No `async/await` in Client Components — keep async logic server-side or in query functions

### State

- Local UI state: `useState`
- Cross-component UI state: consider lifting or TanStack Store before reaching for a global store
- Server state: TanStack Query only — do not duplicate server data in local state

### Styling

- Tailwind utility classes only — no inline `style` props, no CSS modules unless justified
- No arbitrary Tailwind values (`w-[347px]`) without a comment explaining the specific constraint
- shadcn/ui primitives as base — extend via `className`, do not fork component internals

**Tailwind is v4.** CSS-first config via `@theme` in the CSS entry — never introduce v3 patterns like a `tailwind.config.js` theme extension in new code.

```css
@theme { --color-brand: oklch(0.6 0.2 250); }
```

**Never name `@theme` tokens with core t-shirt keys** (`--container-xs/sm/md/lg/xl/…`). They silently shadow Tailwind's core size scale app-wide — this broke Sheet and Dialog widths in tutods. Use semantic names instead.

Wrong: `@theme { --container-lg: 1040px }` → Right: `@theme { --container-page: 1040px }`, used as `max-w-page`.

### No Snapshot Tests

Snapshot tests are banned — they break on cosmetic changes and create false confidence. Write behavioral tests instead.
