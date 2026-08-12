## Project Rules — tutods

### Path alias

This repo migrated from `~/*` to `@/*` → `src/`. Use `@/…`; never deep relative
imports. If you find a stale `~/…` import, it predates the migration.

### Tailwind v4 theme tokens

Never name `@theme` tokens with core t-shirt keys (`--container-xs/sm/md/lg/xl`).
They silently shadow Tailwind's core size scale app-wide — this broke Sheet and
Dialog widths here. Use semantic names:

```css
/* Wrong */ @theme { --container-lg: 1040px }
/* Right */ @theme { --container-page: 1040px }   /* → max-w-page */
```

### Shared tooling config

Biome, TypeScript and Renovate config come from the `@tutods/*` packages in the
`lib` repo. Fix the package, not this repo's local copy — then check whether the
siblings need the same change.
