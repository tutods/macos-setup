---
name: obsidian-vault
description: Search, read, and write durable notes in the Obsidian vault at $HOME/Obsidian, project decisions, research, corrected mistakes, and cross-session context that should outlive a single conversation. Use when the user asks to remember something for later, save a note, look something up in Obsidian, references a past decision that might be logged there, or corrects a mistake I made.
---

# Obsidian Vault

The vault lives at `$HOME/Obsidian`, resolve `$HOME` at run time, never hardcode `/Users/<name>`.

This vault is Claude Code's durable memory: the harness remembers nothing automatically, so writes happen because this skill runs. Two triggers:

- **Explicit**: the user asks to remember/save/look something up.
- **Proactive**: a corrected mistake, an approved decision, a standing convention, or a completed deploy/handoff. No need to be asked.

Each machine has its own vault and they are strictly separate: the work vault holds company context only, the personal vault personal context only. Never reference or assume content from the other.

## Layout

The machine's in-scope folder list is owned by the `home.ai.vaultFolders` option in the dotfiles repo (`home/common/ai/options.nix`, set per role), which lands as the `CLAUDE_VAULT_FOLDERS` env var in `~/.claude/settings.json`; a new type folder needs adding to that option too, or `vault-lint` flags it as outside the declared scope.

- Type folders at vault root. Both vaults have `Lessons/`, `Decisions/`, `Process/`, `Conventions/`, and `Notes/` (catch-all). The personal vault adds `Projects/` (own products, infra, tooling), `Clients/` (paid engagements, scope and handoff state only, **never** contact details, billing figures, or company-owned code), and `Prompts/` (a prompt library). Create a new folder only for a genuinely new recurring type.
- Subfolder a type folder by area only once it has outgrown flat browsing. In the personal vault that's `Lessons/` (by tech area) and `Prompts/` (by category). Everywhere else `area` frontmatter covers filtering.
- **No hand-maintained index notes.** `Index.md` is the only note at vault root and it just links `Vault.base`, an Obsidian Bases file that derives every view from frontmatter, so nothing goes stale.
- `Templates/` holds one starter file per type, excluded from `Vault.base` by a folder filter.
- **Title Case** for every note filename.
- Each note is a self-contained unit, one topic/decision/fact per note, not a running log.
- `[[wikilinks]]` resolve by filename regardless of folder, so moving a note between folders never breaks a link.

## Frontmatter

Every project-derived note starts with:

```yaml
---
type: lesson          # lesson | decision | process | convention | note
                      # personal vault also: project | client
project: <slug>        # short identifier for the repo/project/client
area: [<tech-or-topic>]     # lowercase, fine-grained
tags: [<coarse-category>]   # backend | frontend | devops | tooling | compliance | ai | process
created: <YYYY-MM-DD>
---
```

`area` and `tags` aren't redundant: `tags` feeds Obsidian's tag pane and `file.hasTag()`, `area` is free-form for fine-grained Bases filtering. Never leave `project` or `area` empty, an empty list makes the note invisible in any view grouped or filtered on it.

Personal-vault `Prompts/` notes are content rather than project-derived, so `project` doesn't apply and `tags` is free-form topical:

```yaml
---
type: prompt           # prompt | skill
category: web-development   # matches the Prompts/<Category>/ subfolder
level: beginner         # prompt only: beginner | intermediate | advanced
target: claude-ai       # prompt only: any-ai | claude-ai | claude-code
tags: [ecommerce, landing-page]
created: <YYYY-MM-DD>
---
```

`type: skill` notes drop `level`/`target`, just `category` and `tags`.

## Linking

Obsidian `[[wikilinks]]`: `[[Note Title]]`. Links to related notes go at the bottom, under a `## Related` heading.

## Workflows

Search and links are plain text, use the vault subagents, not the Obsidian app.

### Read first

Nothing is injected at session start: the vault is discovered on demand. Find and read notes by dispatching the `vault-search` subagent, which is a read-only lookup on `haiku` and cheaper than spending main-session tokens on `rg` output. Do this before assuming a note does or doesn't exist. Never grep the vault inline.

### Find notes or backlinks

Dispatch to `vault-search`: by filename, by content, by `Prompts/` topic, or "find backlinks to [[Note Title]]".

### Check vault health

Dispatch to the `vault-lint` subagent for dead wikilinks, orphan notes, missing or empty frontmatter, empty notes, filename drift, and type folders missing from the declared vault scope (`home.ai.vaultFolders`). It only reports; apply any fix in the main session.

### Create a note

1. Title Case filename, `.md` extension, in the matching type folder (or `Notes/` if nothing fits, plus an area subfolder where that folder is subfoldered). `mkdir -p` the folder first if it doesn't exist.
2. Start from `Templates/<Type>.md` and fill in the frontmatter.
3. Content is one unit of learning, what, why, and nothing that belongs in a more specific note. Write one line per paragraph, never hard-wrap: the vault runs with Obsidian's default `strictLineBreaks: false`, so a hard-wrapped line renders as a visible break.
4. Add `[[wikilinks]]` to related notes under `## Related`.

### Update a note

Read it first, then edit in place, don't append a dated log entry unless the note is explicitly a running log.

### Log a lesson

Triggered by a corrected mistake, not by request. Dispatch `vault-search` on the topic in `Lessons/` first and update an existing note instead of duplicating it.

```markdown
---
type: lesson
project: <slug>
area: [<area>]
tags: [<coarse-category>]
created: <YYYY-MM-DD>
---

# <Short Title>

**Wrong:** what broke it. The mistaken assumption or action.
**Right:** what fixes it. The rule going forward.

## Related
- [[Some Related Note]]
```

### Log a decision or convention

Triggered by an approved architecture/tech choice (`Decisions/`) or a stated standing rule for how work happens (`Conventions/`), not by request. Dispatch `vault-search` on the target folder first and update an existing note rather than duplicating it. Skip if the choice was reverted in the same session, or is a one-off with no standing pattern.

### Update a project/client note

Personal vault only, triggered by a completed deploy, migration, stack change, or handoff. Read the existing `Projects/<Name>.md` or `Clients/<Name>.md` (create from the matching template if absent) and update its "Current state"/"Handoff state" line in place, this type is meant to track current state, so it's the exception to "not a running log."
