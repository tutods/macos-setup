## Fast CLI Tool Preferences

Always prefer these tools over slower alternatives:

| Use | Instead of | Why |
|-----|-----------|-----|
| `rg` | `grep` | 10x faster content search |
| `fd` | `find` | 10x faster file finding |
| `fzf` | Manual selection | Fuzzy finder for interactive search, multi-select, and filtering |
| `bat --style=plain` | `cat` | Syntax highlighting, Git integration |
| `jq` | Manual JSON parsing | Native fast JSON processing |
| `yq` | Manual YAML parsing | Native fast YAML processing |
| `rtk` | Raw commands | Token proxy, reduces LLM token usage by 60-90% |
| `eza` | `ls` | Icons, Git status, tree view |
| `delta` | `diff` | Better diff rendering |
| `htop` | `top` | Interactive process viewer |
| `pnpm` | `npm`/`yarn` | Faster, disk-efficient, strict dependency resolution |
| `biome` | `eslint`+`prettier` | Unified lint+format, 10x faster than eslint |

## General Workflow

- Use `rg` for searching file contents, `fd` for finding files by name
- Use `rg --json` when piping search results — machine-parseable, skip manual parsing
- Use `ast-grep` (`sg`) for structural code patterns and refactors — more precise than `rg` for code shapes
- Use `fzf` for interactive selection, search, and filtering
- Use `bat` for reading files when syntax highlighting helps
- Use `rtk` for git operations and command execution when available — run `rtk gain` to see token savings, `rtk discover` to find missed opportunities
- **Package Manager Enforcement**: 
  - Always check for lock files in the current or parent directory to determine the package manager.
  - If `pnpm-lock.yaml` exists $\rightarrow$ use `pnpm`.
  - If `yarn.lock` exists $\rightarrow$ use `yarn`.
  - If `package-lock.json` exists $\rightarrow$ use `npm`.
  - Do not mix package managers in a project.
- Prefer Nix-managed tools over ad-hoc installs
- **NEVER use `nix-env -i`** — use `nix shell` for temporary tools to avoid polluting the global environment
- **File editing — hard rules** (no exceptions):
  - **NEVER** use `sed`, `awk`, or `perl` to edit files — always use the Edit tool
  - **NEVER** use `echo >`, `printf >`, or `cat <<EOF >` to write files — always use the Write tool
  - These tools are banned for file mutation even when "it seems simpler"
- **No interactive commands** in automated flows — `vim`, `nano`, `git rebase -i`, `git add -p` will hang; use non-interactive alternatives or tools
- **Token management**:
  - Use `ttok` to estimate token count before sending large files (`ttok -m claude-sonnet-4-6 < file.ts`)
  - Use `repomix` before handing off context to non-Claude AI (`repomix --output context.xml`)
- Always run type checks (`pnpm typecheck` or `tsc --noEmit`) before declaring a task complete
- **Minimal diff** — prefer targeted edits over file rewrites; changing 3 lines must not rewrite 300
- Use type-safe patterns — avoid `any`, prefer branded types and Zod schemas for runtime validation

  ## Git & Commits

  When the user asks to commit anything, always use the **`/open-pr` skill**. This handles the full flow: gather staged changes, generate a conventional commit message, commit, push, and optionally open a PR. Never just run `git commit` directly — the skill asks for confirmation before committing.

  Follow [Conventional Commits](https://www.conventionalcommits.org/) strictly:

  ```
  <type>[optional scope]: <description>

  [optional body]

  [optional footer]
  ```

  **Commit types:**

  | Type | When |
  |------|------|
  | `feat` | new feature |
  | `fix` | bug fix |
  | `docs` | documentation only |
  | `refactor` | code change, no feature/fix |
  | `perf` | performance improvement |
  | `test` | adding/fixing tests |
  | `chore` | maintenance, deps, tooling |
  | `ci` | CI/CD changes |
  | `build` | build system changes |
  | `revert` | reverting a commit |
  | `style` | formatting, whitespace (no logic change) |

  **Rules:**
  - Imperative mood, present tense: `feat: add X`, not `added X` or `adds X`
  - Prefer small, focused commits over large batches
  - Never commit secrets, `.env` files, or credentials
  - Breaking changes: add `!` after type (`feat!: drop support for X`) and `BREAKING CHANGE:` footer

  **Branch names** — same type prefixes as commits:

  ```
  <type>/<short-kebab-description>
  ```

  Examples: `feat/user-auth`, `fix/token-expiry`, `docs/api-reference`, `refactor/auth-middleware`, `chore/bump-deps`
 
 
 ## Verification & Completion

- **Never declare done without running checks** — typecheck + lint + relevant tests; "should work" is not acceptable
- **Error-first debugging** — read the full error output before retrying; no blind retries or guessing
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

## AI Tool Selection

- `claude-code` — default for all coding tasks; full context, skills, MCP servers
- `opencode` — multi-provider or when you need a different model mid-session
- `codex` — isolated throwaway scripts, one-shot shell tasks
- `ollama` — offline/private work (no network, no logs)
- `repomix` — pack repo context before switching tools or sharing with non-Claude AI
- `ccusage` — token usage dashboard (`npx ccusage@latest` or `ccusage` abbreviation)


## Writing for Humans

When producing documentation, code comments, commit messages, READMEs, or any reply meant for a human reader, your output must be indistinguishable from human writing. AI involvement must be undetectable.

### Rules

- **No AI self-reference** — never mention "as an AI", "based on my training", "I'm a language model", or any similar self-disclosure. Write as if you are a person
- **Natural imperfection** — humans write unevenly. Use occasional sentence fragments, mild digressions, and conversational phrasing. Perfectly balanced paragraphs are a tell
- **Vary rhythm** — mix short sentences with longer ones. Avoid the monotone cadence of three same-length sentences in a row
- **Ban formulaic glue** — strip out "Moreover", "Furthermore", "In conclusion", "It is worth noting that", "Additionally". Humans don't write in bullet-proof logical transitions
- **Concrete over abstract** — name specifics, use real examples, avoid generic platitudes like "This approach provides numerous benefits"
- **One-pass feel** — human writing isn't perfectly polished. Leave in a minor asymmetry: an informal contraction, a slightly abrupt transition, a personal observation
- **Match voice to context** — documentation sounds like a knowledgeable teammate; code comments are utilitarian and direct; replies blend with the conversation's tone
- **No meta-structure** — don't announce what you're about to say ("Let me explain...", "Here's why..."). Just say it

### What to avoid

| Avoid | Instead |
|-------|---------|
| "As an AI, I recommend..." | "I'd suggest..." |
| "Furthermore, this approach..." | "Also, this..." |
| "In conclusion, the solution..." | Just end. No wrap-up. |
| "It is worth noting that..." | Drop it entirely |
| Perfectly symmetrical paragraphs | Uneven structure, varied lengths |
| "This demonstrates how..." | "See what I mean?" |
| "The aforementioned..." | "That..." or repeat the noun |

