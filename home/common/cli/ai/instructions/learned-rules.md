## Learned Rules

Standing rules mined from past corrections. Each one exists because the same mistake was made (and corrected) at least once — do not repeat them.

### Tooling & environment

- **Every AI-tooling config change targets both agents.** Skills, instructions, MCP servers, and settings must land in Claude Code *and* opencode.
  Wrong: update `CLAUDE.md` only. Right: update the shared instruction source that generates both `~/.claude/rules/workflow.md` and opencode's `AGENTS.md`.
- **The AI stack is Claude Code + opencode in the terminal. Nothing else.** Don't propose Claude Desktop, new AI CLIs, or extra LLM clients.
  Wrong: "you could also install <new AI tool>". Right: solve it with claude-code or opencode.
- **Changes land in the user's working tree.** Worktrees are for isolation during work; the result must be applied to the actual project before claiming done.
  Wrong: edits sitting in `.worktrees/` while reporting success. Right: verified changes in the project the user has open.
- **Never swap build tooling or framework infrastructure as a side effect.** Bundler, server runtime, or framework changes need their own explicit approval and a rollback plan.
  Wrong: migrating Vite→RSBuild while doing a performance task. Right: "this would need a build-tool change — separate decision, want a proposal?"
- **Do the work yourself — never pull another model or paid API for something you can do.** Translation, content, analysis: the assistant does it directly.
  Wrong: `ollama pull` a model to translate strings. Right: translate the chunk yourself, glossary in hand.
- **Shared tooling config lives in the `@tutods/*` packages** (`biome-config`, `typescript-config`, `renovate-config` in the `lib` repo). Improve the package, then check whether sibling repos (jps, farmacia-nova, tutods) need the same change — and say so.
  Wrong: fixing renovate rules in one repo's local config. Right: fix `@tutods/renovate-config`, then offer to apply it to the siblings.
- **Worktrees are temporary.** Non-trivial feature work happens in one; quick fixes (lint, one-liners) go directly in the working tree; and every worktree is removed as soon as the work lands.
  Wrong: three stale worktrees left behind after PRs merged. Right: land the PR, `git worktree remove`, done.

### Following instructions

- **When the user shares a link, fetch it, use it, and say what you took from it.** A pasted URL is an instruction, not decoration.
  Wrong: answering from memory after being given an article. Right: "from the article, applied X and Y; skipped Z because…"
- **A revert is complete: files, dependencies, and tools added for the change all go.** Restoring code but leaving the new package installed is not a revert.
  Wrong: revert the script but keep `gum` in packages. Right: tree and dependency list match the pre-change state.
- **After a revert, re-verify any later work that built on the reverted code.** Batches applied on top of it may now be broken or half-applied.
  Wrong: continue with phase 3 after reverting part of phase 2. Right: re-check phase 2's touched files first.
- **No loops.** If the same command or approach fails twice, stop — change approach or ask. Never re-run a failing step unchanged hoping for a different result.
- **A config change isn't done while an old contradicting block survives.** When asked to enable/change behavior, find and remove or flip the existing rule that blocks it — don't just add a new one beside it.
  Wrong: adding an `.nvmrc` custom manager while `matchPackageNames: ["node"], enabled: false` stays. Right: delete the ignore rule in the same change.
- **Check official docs for fast-moving libraries before implementing — unprompted.** Better Auth, Biome, Renovate, TanStack, pnpm: training-data memory is stale; fetch the docs first.
  Wrong: implementing Better Auth sign-up flow from memory when `disableSignup` exists. Right: check the options reference, then implement.
- **A PR isn't delivered with conflicts on it.** After opening or updating a PR (or after the base branch moves), check mergeability and resolve conflicts immediately.
  Wrong: reporting "PR opened" while GitHub shows conflicts. Right: rebase/merge, push, confirm mergeable.

### Code & docs style (cross-project)

- **Tailwind is v4.** Use CSS-first config (`@theme`); never introduce v3 patterns like `tailwind.config.js` theme extension in new code.
  Wrong: adding `tailwind.config.js` colors. Right: `@theme { --color-brand: … }` in the CSS entry.
- **Function declarations, not top-level arrow functions.** Arrows are for callbacks only (`useMemo`, `useCallback`, array methods, handlers passed inline).
  Wrong: `export const HeroBanner = () => {}`. Right: `export function HeroBanner() {}`.
- **No counts or ranges in docs that go stale.** Describe the set, not its size.
  Wrong: "ADRs 0001–0014". Right: "architecture decision records, numbered".
- **Prefer array methods over `for...of`.** `map`/`forEach`/`filter` read better; loops only where early exit or awaiting in sequence genuinely requires one.
  Wrong: `for (const item of items) { results.push(fn(item)) }`. Right: `const results = items.map(fn)`.
- **Avoid type casting.** No `as` to silence the compiler — narrow, use a type guard, or fix the type at the source (`as const` and test files excepted).
  Wrong: `const user = data as User`. Right: `const user = userSchema.parse(data)` or a narrowing check.
