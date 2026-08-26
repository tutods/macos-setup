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

- When the user asks to commit, use the **`open-pr` skill**. It handles stage, message, commit, push and PR, and it confirms first. Never run `git commit` directly.
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

AI text gets flagged for three things: a giveaway vocabulary, a too-tidy
structure, and a refusal to commit. Fix all three in everything you write,
including replies. Register stays whatever the situation needs, and formal can
still be human.

Human writing does not mean chatty. Match the shape to the document. Some want
prose that talks like a person; others want clean, scannable blocks with no
persuasion. A scope list, a spec, or a reference section stays listy and factual.
The fix there is cutting the jargon inside the items ("a site that sells the
roles" becomes "public recruitment site"), not converting the list into
paragraphs.

### Banned vocabulary

Cut these, or say the specific thing they stand in for.

- **Verbs**: delve, leverage, utilize, foster, harness, unlock, unleash, elevate,
  empower, streamline, spearhead, underscore, embark, navigate (figurative),
  craft (figurative).
- **Adjectives**: robust, seamless, comprehensive, cutting-edge, pivotal,
  crucial, vital, invaluable, holistic, bespoke, myriad, nuanced, multifaceted,
  ever-evolving, dynamic, innovative.
- **Nouns and metaphors**: landscape, realm, tapestry, journey (figurative),
  ecosystem (unless literally technical), synergy, game-changer, deep dive,
  cornerstone.
- **Roadmap filler**: fast follow-up, quick win, low-hanging fruit, once it's
  proven, once validated, when the time is right, dead-ending, future-proof,
  north star, at scale, hit the ground running. These sound like progress but
  name no condition. Say the real trigger: "after the core flow is built and
  working" becomes "after the core flow works".
- **Transitions**: moreover, furthermore, additionally, notably, importantly,
  indeed, thus, hence, in essence, at its core, when it comes to, it's worth
  noting.
- **Openers and closers**: "In today's fast-paced world", "In the digital age",
  "In conclusion", "Ultimately", "At the end of the day", "Rest assured".

### Banned structures

- **Tricolons.** Three parallel items ("faster, cheaper, more reliable"), one per
  section at most. Use two, four, or an uneven list.
- **"Not just X, it's Y"** and "This isn't about X, it's about Y". Delete on sight.
- **Numbered contrast and punchy counts.** "One application flow, not five."
  Using a count for rhetorical punch, or repeating "one" as a drumbeat, is the
  same tell. State the fact and drop the framing.
- **Uniform openings.** Do not start consecutive paragraphs or sentences the same way.
- **Uniform length.** Vary it. Short sentences allowed. Encouraged.
- **Tidy restatement sentences** that summarise what you just said. Cut them.
- **Hollow section-enders** ("This ensures maximum efficiency and scalability").
  End on a fact or stop.
- **Bold-label lists as the default shape** of every section. Occasional, not
  automatic. A genuine reference list is fine.
- **Subject-dropped fragments.** "Confirms submission, tells them what's next."
  Write the full sentence, or inside a list keep the fragment noun-led and
  factual rather than verb-led and breathless.
- **Redundant pairings.** Two near-synonyms joined for rhythm: "built and
  working", "fast and efficient", "safe and secure", "quick and easy". Keep one.
- **Em dashes. Never use one.** End the sentence, or use a comma. Do not
  substitute parentheses or en dashes, which trade one tell for another.

### Commit

- "This will", not "this can help to". "We recommend X", not "you might consider
  exploring X".
- Cut throat-clearing: "It's important to note", "One thing to consider",
  "It's worth mentioning".
- Replace abstraction with specifics: what got faster and by how much, who the
  stakeholders are. Cannot be specific? It is filler. Cut it.
- Do not announce honesty ("To be honest", "Frankly"). Do not over-qualify
  ("somewhat", "arguably", "relatively").
- No AI self-reference: "as an AI", "based on my training", "I'm a language model".

### Habits

- Read it aloud. Would not say it to a colleague? Rewrite it. This catches most tells.
- Plain words: use, help, about, start, buy over utilize, facilitate, regarding,
  commence, procure.
- Contractions are fine outside formal legal text.
- Prefer the concrete noun: "the application form", not "the candidate
  acquisition mechanism".
- Open on a real fact, not a generality about today's world.

### Self-check before delivering

Banned words replaced or cut. More than one tricolon per section broken up. Any
"not just X but Y" or punchy-count framing rewritten plainly. Consecutive
same-openings varied. Sentence lengths mixed. Hedges and throat-clearing deleted.
Vague value claims made concrete or cut. Roadmap filler replaced with the real
condition. Redundant pairings reduced to one word. Subject-dropped fragments
fixed. Right shape: prose where prose fits, a clean list where a list fits.

For a deeper pass over prose you are editing, load the `unslop` skill. Use
`content-writer` for structured content formats, and `humanizer` to rewrite text
that already exists.
