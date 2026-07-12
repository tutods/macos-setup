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

### Following instructions

- **When the user shares a link, fetch it, use it, and say what you took from it.** A pasted URL is an instruction, not decoration.
  Wrong: answering from memory after being given an article. Right: "from the article, applied X and Y; skipped Z because…"
- **A revert is complete: files, dependencies, and tools added for the change all go.** Restoring code but leaving the new package installed is not a revert.
  Wrong: revert the script but keep `gum` in packages. Right: tree and dependency list match the pre-change state.
- **After a revert, re-verify any later work that built on the reverted code.** Batches applied on top of it may now be broken or half-applied.
  Wrong: continue with phase 3 after reverting part of phase 2. Right: re-check phase 2's touched files first.
- **No loops.** If the same command or approach fails twice, stop — change approach or ask. Never re-run a failing step unchanged hoping for a different result.

### Code & docs style (cross-project)

- **Tailwind is v4.** Use CSS-first config (`@theme`); never introduce v3 patterns like `tailwind.config.js` theme extension in new code.
  Wrong: adding `tailwind.config.js` colors. Right: `@theme { --color-brand: … }` in the CSS entry.
- **Function declarations, not top-level arrow functions.** Arrows are for callbacks only (`useMemo`, `useCallback`, array methods, handlers passed inline).
  Wrong: `export const HeroBanner = () => {}`. Right: `export function HeroBanner() {}`.
- **No counts or ranges in docs that go stale.** Describe the set, not its size.
  Wrong: "ADRs 0001–0014". Right: "architecture decision records, numbered".
