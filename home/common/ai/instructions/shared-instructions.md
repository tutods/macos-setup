## Tooling

`rg` over `grep`, `fd` over `find`, `bat --style=plain` over `cat`, `eza` over `ls`, `ast-grep` over `rg` for code shapes and precise refactors, `jq`/`yq` for JSON/YAML, `rg --json` when piping search results. `pnpm` over `npm`/`yarn`, `biome` over eslint+prettier (project-local). Prefer Nix-managed tools over ad-hoc installs, **never `nix-env -i`**, `nix shell` for temporary tools.

**File editing, no exceptions**: never `sed`, `awk` or `perl` to edit, never `echo >`, `printf >` or `cat <<EOF >` to write. Use the Edit and Write tools. No interactive commands in automated flows (`vim`, `fzf`, `git rebase -i`, `git add -p` hang). Shell scripts start with `set -euo pipefail` and quote every variable.

## Git

When the user asks to commit, use the **`open-pr` skill** (stage, message, commit, push, PR, confirms first). Outside it, commit with an explicit pathspec (`git commit -m … -- <file>`), never a bare `git commit` that sweeps what the user had staged. Messages follow Conventional Commits; the `conventional-commit` skill owns the type table and branch naming. Keep commits small, never commit secrets or `.env` files.

## Vault

Nothing about the vault is injected automatically; discover it on demand, and do not grep the vault inline: lookups go through the `vault-search` agent. The `obsidian-vault` skill owns the rest, including the four proactive write triggers: a corrected mistake, an approved decision, a stated standing rule, a completed deploy or handoff. Load it when one of those fires. Behavioural rules about the agent belong in `learned-rules.md`, not the vault: one fact, one home.

## Code & Comments

No commented-out code, no `TODO`/`FIXME` unless asked, no placeholder or stub implementations without flagging them. No unsolicited artifacts: no README, CHANGELOG or docstrings unless asked. **Zero comments is the default**: one short line maximum, only for what names and control flow cannot carry (hidden constraint, third-party bug workaround, security-critical invariant, load-bearing ordering). Never narrate code, change or signature, never cite another file by line, in any language, skill or agent. In your own diffs comment hygiene is a **blocking** item.

## Destructive Operations

Explicit user confirmation before `rm -rf` or bulk deletes, `git reset --hard`, `git clean -fd`, `git checkout -- .`, `git push --force`, dropping or truncating tables, or anything else you cannot undo.

## Security

Never dump the environment (`env`, `printenv`, `set`), it leaks session tokens and private keys: read the one variable you need by name. Never print plaintext credentials into logs or transcripts. Verify AI-generated networking or security commands before running them with `sudo`.

## Writing

AI text gives itself away through stock vocabulary and too-tidy structure; cut both in everything you write, replies included. Open on a concrete fact, not a generality. Always on, every reply:

- **No em dash.** End the sentence or use a comma; no en dashes or parentheses as substitutes.
- **Banned words**, say the specific thing: delve, leverage, utilize, foster, harness, seamless, robust, comprehensive, crucial, pivotal, landscape, realm, tapestry, ecosystem (unless literally technical), moreover, furthermore, additionally, "it's worth noting".
- No "not just X, it's Y" and no "this isn't about X, it's about Y". No rhetorical counts ("one flow, not five", "one" as a drumbeat). No AI self-reference.
- Commit: "this will", not "this can help to". "We recommend X", not "you might consider exploring X". Cut throat-clearing.
- Vary sentence length and paragraph openings; redundant pairings ("safe and secure") reduce to one word.

The `unslop` skill goes deeper (rule of three, negative parallelism, the full banned list) with a self-check pass; load it for any prose a human reads as writing. `content-writer` handles structured PT-PT content, `humanizer` rewrites existing text.
