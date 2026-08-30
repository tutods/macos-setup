## Fast CLI Tool Preferences

Always prefer these over the slower alternative:

| Use | Instead of |
|-----|-----------|
| `rg` | `grep` |
| `fd` | `find` |
| `ast-grep` | `rg`, for code shapes and precise refactors |
| `bat --style=plain` | `cat` |
| `jq` / `yq` | hand-parsing JSON/YAML |
| `eza` | `ls` |
| `pnpm` | `npm` / `yarn` |
| `biome` | `eslint` + `prettier` (project-local install, not on PATH globally) |

## General Workflow

- Use `rg --json` when piping search results
- Prefer Nix-managed tools over ad-hoc installs. **Never `nix-env -i`**. Use `nix shell` for temporary tools
- **File editing, no exceptions**: never `sed`, `awk` or `perl` to edit a file, never `echo >`, `printf >` or `cat <<EOF >` to write one. Use the Edit and Write tools
- **No interactive commands** in automated flows. `vim`, `fzf`, `htop`, `git rebase -i` and `git add -p` will hang
- **No unsolicited artifacts**: no README, CHANGELOG or docstrings unless asked
- Shell scripts start with `set -euo pipefail` and quote every variable

## Git & Commits

- When the user asks to commit, use the **`open-pr` skill**. It handles stage, message, commit, push and PR, and it confirms first. If you ever commit outside it, use an explicit pathspec (`git commit -m … -- <file>`), never a bare `git commit` that sweeps whatever the user had staged. See `learned-rules.md`.
- Messages follow [Conventional Commits](https://www.conventionalcommits.org/). The `conventional-commit` skill owns the type table, scope rules and branch naming.
- Keep commits small and focused. Never commit secrets, `.env` files or credentials.

## Vault

The SessionStart hook injects a titles-only index of the vault's core
folders at the top of every session. Prompts/ is excluded from that index, a
one-line pointer with a note count stands in its place, and any Prompts/
lookup goes through the `vault-search` agent instead. Consult that context
before you search for anything.

The `obsidian-vault` skill owns everything else. It covers how to search when
the injected context is not enough, and the four proactive write triggers:
a corrected mistake, an approved decision, a stated standing rule, and a
completed deploy or handoff. Load the skill when one of those fires. Do not
grep the vault inline.

Behavioural rules about how the agent works on this machine belong in
`learned-rules.md`, not the vault. One fact, one home.

## Code & Comments

- No commented-out code left behind
- No `TODO` or `FIXME` unless explicitly asked
- No placeholder or stub implementations without flagging them to the user
- **Zero comments is the default.** One short line is the maximum, and only for
  a reason that names and control flow cannot carry: a hidden constraint, a
  third-party bug workaround, a security-critical invariant, load-bearing
  ordering. Never narrate what the code does. Never narrate the change or the
  fix, because that is what the commit message is for. Never restate a
  signature. Never cite another file by line. This applies in every language,
  skill and agent.
- When you review your own diff, comment hygiene is a **blocking** item, not a nit.

## Destructive Operations

Always get explicit user confirmation before `rm -rf` or bulk deletes,
`git reset --hard`, `git clean -fd`, `git checkout -- .`, `git push --force`,
dropping or truncating database tables, or anything else you cannot undo.

## Security

- Never dump the environment with `env`, `printenv` or `set`. It leaks session
  tokens and private keys. Read the one variable you need by name.
- Never print plaintext credentials or secret values into logs or transcripts.
- Verify AI-generated networking or security commands before you run them with
  `sudo`.

## Writing

AI text gives itself away through a stock vocabulary and a too-tidy structure. Cut both in everything you write, replies included. Match the shape to the document: flowing prose where that fits, a clean factual list where that fits, no forced persuasion in either. Open on a concrete fact, not a generality about the world.

Always on, every reply:

- **Never use an em dash.** End the sentence or use a comma. Do not substitute en dashes or parentheses.
- **Banned words**, say the specific thing instead: delve, leverage, utilize, foster, harness, seamless, robust, comprehensive, crucial, pivotal, landscape, realm, tapestry, ecosystem (unless literally technical), moreover, furthermore, additionally, "it's worth noting".
- **No "not just X, it's Y"**, no "this isn't about X, it's about Y". Delete on sight.
- **No rhetorical counts.** "One flow, not five" and repeating "one" as a drumbeat are the same tell. State the fact.
- **No AI self-reference**: "as an AI", "based on my training".
- Commit: "this will", not "this can help to". "We recommend X", not "you might consider exploring X". Cut throat-clearing ("it's important to note", "one thing to consider").
- Vary sentence length and paragraph openings. Redundant pairings ("safe and secure", "built and working") reduce to one word.

The `unslop` skill goes deeper on structure (rule of three, negative parallelism, superficial `-ing` analyses, the full banned list) with a self-check pass. Load it for any prose a human reads as writing: docs, commit bodies, PR descriptions. `content-writer` handles structured PT-PT content, `humanizer` rewrites text that already exists.
