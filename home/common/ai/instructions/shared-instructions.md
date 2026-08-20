## Fast CLI Tool Preferences

Always prefer these tools over slower alternatives:

| Use | Instead of | Why |
|-----|-----------|-----|
| `rg` | `grep` | 10x faster content search |
| `fd` | `find` | 10x faster file finding |
| `sg` (ast-grep) | `rg` for code shapes | Structural matching, precise refactors |
| `bat --style=plain` | `cat` | Syntax highlighting, Git integration |
| `jq` | Manual JSON parsing | Native fast JSON processing |
| `yq` | Manual YAML parsing | Native fast YAML processing |
| `rtk` | Raw commands | Token proxy, reduces output size by 60-90% |
| `eza` | `ls` | Icons, Git status, tree view |
| `pnpm` | `npm`/`yarn` | Faster, disk-efficient, strict resolution |
| `biome` | `eslint`+`prettier` | Unified lint+format, 10x faster |

## General Workflow

- Use `rg --json` when piping search results — machine-parseable, skip manual parsing
- Prefix read-heavy commands with `rtk` to compress their output (`rtk git status`) — there is no hook doing this for you. `rtk gain` shows savings, `rtk discover` finds missed opportunities
- Use `ttok` to estimate token count before reading large files (`ttok -m claude-sonnet-5 < file.ts`)
- Prefer Nix-managed tools over ad-hoc installs
- **NEVER use `nix-env -i`** — use `nix shell` for temporary tools to avoid polluting the global environment
- **File editing — hard rules** (no exceptions):
  - **NEVER** use `sed`, `awk`, or `perl` to edit files — always use the Edit tool
  - **NEVER** use `echo >`, `printf >`, or `cat <<EOF >` to write files — always use the Write tool
  - These tools are banned for file mutation even when "it seems simpler"
- **No interactive commands** in automated flows — `vim`, `nano`, `fzf`, `htop`, `git rebase -i`, `git add -p` will hang; use non-interactive alternatives or tools

## Git & Commits

- When the user asks to commit anything, use the **`open-pr` skill** — it handles the whole flow (stage, message, commit, push, PR) and confirms before committing. Never run `git commit` directly.
- Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/); the `conventional-commit` skill has the type table, scope rules and branch-naming convention.
- Prefer small, focused commits over large batches.
- Never commit secrets, `.env` files, or credentials.

## Prior Art

The SessionStart hook already injects every note under `Lessons/`,
`Conventions/`, `Decisions/`, `Process/`, `Projects/`, `Clients/`, and
`Notes/` in full — consult that context directly instead of grepping for it
as a first step. `Prompts/` is injected as titles only (it's a content
library, not working memory), so it still needs a search when a prompt is
relevant.

Fall back to a direct search (`obsidian-vault` skill) when the injected
context isn't enough — after long-session compaction, for a folder not yet
in the hook's fixed list, or to pin down one exact note:

    rg -il "<topic keywords>" "$HOME/Obsidian"

## Vault Capture

Four triggers write to the Obsidian vault (`obsidian-vault` skill) without
being asked. Each has a skip clause — this is not a log-everything rule:

| Trigger | Writes to |
|---|---|
| A mistake I made gets corrected and the fix is confirmed working | `Lessons/<Area>/` |
| A non-trivial tech/architecture choice is made **and approved** | `Decisions/` |
| The user states a standing rule for how work is done here | `Conventions/` |
| A deploy, migration, stack change, or handoff completes | update the `Projects/`/`Clients/` note's state section |

Skip if: an existing note already covers it (update that note instead of
duplicating it — grep the target folder first); it's a one-off with no
recurring pattern; the decision was reverted in the same session. Do the
write once the outcome is confirmed, not mid-debugging or mid-discussion.

Lessons keep the Wrong/Right pattern: what broke it, what fixes it. All four
types use `type`/`project`/`area`/`tags`/`created` frontmatter — Bases
indexes it automatically, nothing to link by hand.

**Boundary with learned rules** — behavioral rules about how the agent works
on this machine stay in `home/common/ai/instructions/learned-rules.md`
(loaded every session via Nix). Technical failure modes and project/client
facts go to the vault instead. One fact, one home — don't duplicate across
both.

## Verification & Completion

- **No unsolicited artifacts** — no auto-generated README, CHANGELOG, or docstrings unless explicitly asked

## Code Hygiene

- No commented-out code left behind
- No `TODO` / `FIXME` comments unless explicitly asked to add them
- No placeholder/stub implementations (fake data, hardcoded returns) without explicitly flagging them to the user

## No explanatory comments in code

**Default: zero comments.** This is non-negotiable and has been flagged across multiple sessions. Treat every comment as something you must justify keeping, not something to add by default.

- **One line max.** Two `//` lines on the same block = violation. Block comments above functions/branches/imports explaining the change = violation.
- **Never narrate what the code does.** Names and control flow are the explanation. `// loop over items` is noise. `// reset state` is noise.
- **Never narrate the change or the fix.** "// was X before", "// added for Y flow", "// this eliminates the race where…", "// keep X — Y forces Z" — all belong in the commit message or PR description, not in the source. The diff already shows what changed.
- **Never restate signatures or types.** JSDoc/docstrings for trivial helpers are forbidden.
- **Never reference other files by line** (`// see start-e2e.mjs:382`). That belongs in the PR body and rots.
- **Red-flag openers — stop and delete if you find yourself typing these:** "Both X AND Y…", "This eliminates…", "We do X so that Y", "Re-seed when…", "Keep X — Y", "Capture the … BEFORE …", "Resolve the run_id ONCE", "Fallback: …", or any sentence that paraphrases the commit body.
- **Acceptable, rarely**: a single short line explaining a WHY that good names can't carry — a hidden constraint, a third-party bug workaround, a security-critical invariant, a load-bearing ordering. Even then, prefer pushing the explanation into the commit message or an OpenSpec/ADR doc.
- **Before commit, re-read every comment you wrote and delete the unjustifiable ones.** If you're not sure, delete.

The same rule binds TypeScript, JavaScript, Rust, Python, and YAML. The same rule binds every skill, every agent, every mode. Implementer/architect/reviewer agent prompts inherit it.

When reviewing a diff you wrote, **comment hygiene is a blocking review item**, not a nit.

## Destructive Operations

**Always require explicit user confirmation before:**
- `rm -rf` or bulk deletes
- `git reset --hard`, `git clean -fd`, `git checkout -- .`
- `git push --force` or `git push --force-with-lease`
- Dropping/truncating database tables
- Any action that cannot be undone

## Shell Scripts

All shell scripts must:
- Start with `set -euo pipefail` — prevents silent failures from unset vars, failed commands, broken pipes
- Quote all variables: `"$var"` not `$var`

## Security & AI Safety

- **Secrets**: Never log output from `doppler` secrets or print plaintext credentials in AI-assisted logs.
- **Verification**: Always verify AI-generated networking or security commands before executing with `sudo`.

## Writing for Humans

Documentation, code comments, commit messages, READMEs, and replies must read as human writing — no AI tells.

- **No AI self-reference** — never "as an AI", "based on my training", "I'm a language model"
- **Ban formulaic glue** — "Moreover", "Furthermore", "Additionally", "In conclusion", "It is worth noting that", "This demonstrates how", "The aforementioned"
- **Vary rhythm** — mix short sentences with long ones; three same-length sentences in a row is a tell. Perfectly symmetrical paragraphs are another
- **Concrete over abstract** — name specifics and real examples, never "this approach provides numerous benefits"
- **No meta-structure** — don't announce what you're about to say ("Let me explain...", "Here's why..."). Just say it. No wrap-up paragraph at the end either
- **Match voice to context** — docs sound like a knowledgeable teammate; code comments are utilitarian; replies blend with the conversation

For rewriting existing text rather than writing it, use the `humanizer` skill.
