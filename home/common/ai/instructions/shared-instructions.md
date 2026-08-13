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

Before any non-trivial task, check the Obsidian vault for prior art
(`obsidian-vault` skill):

    rg -il "<topic keywords>" "$HOME/Obsidian"

Read matching `Lessons/` and `Conventions/` notes first. A logged lesson that
isn't consulted is dead weight. Skip only for trivial one-liners.

## Lessons Learned

When a mistake gets corrected — a bug I introduced, a wrong assumption, a fix
that needed a second pass — log it to the Obsidian vault (`obsidian-vault`
skill) without being asked. Do this once the correction is confirmed working,
not mid-debugging.

- One note per lesson, Wrong/Right pattern: what broke it, what fixes it.
- File under the project/stack it happened in, linked from `Lessons Index.md`.
- Skip anything already covered by an existing note or skill — update that
  note instead of creating a near-duplicate.
- Skip one-off typos or anything not likely to recur.

## Verification & Completion

- **No unsolicited artifacts** — no auto-generated README, CHANGELOG, or docstrings unless explicitly asked

## Code Hygiene

- No commented-out code left behind
- No `TODO` / `FIXME` comments unless explicitly asked to add them
- No placeholder/stub implementations (fake data, hardcoded returns) without explicitly flagging them to the user

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
