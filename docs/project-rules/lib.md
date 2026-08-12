## Project Rules — lib (`@tutods/*` packages)

This repo is the source of truth for shared tooling config: `@tutods/biome-config`,
`@tutods/typescript-config`, `@tutods/renovate-config`.

### Fix here, then propagate

A tooling rule fixed in a consumer repo's local config is a bug, not a fix. Change
the package here, then check whether the consumers need the same change — and say
so explicitly rather than assuming someone will notice.

Consumers: `jps`, `farmacia-nova`, `tutods`.

Wrong: patching Renovate rules inside one repo's `renovate.json`.
Right: fix `@tutods/renovate-config`, then offer to roll it out to the siblings.

### A config change isn't done while a contradicting rule survives

When enabling or changing behaviour, find and remove the existing rule that
blocks it — don't add a new one beside it.

Wrong: adding an `.nvmrc` custom manager while
`matchPackageNames: ["node"], enabled: false` stays in place.
Right: delete the ignore rule in the same change.
