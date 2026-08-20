---
name: obsidian-vault
description: Search, read, and write durable work notes in the Obsidian vault at $HOME/Obsidian — company decisions, project research, corrected mistakes, Jira/project context that should outlive a single conversation. Use when the user asks to remember something for later, save a note, look something up in Obsidian, references a past decision that might be logged there, or corrects a mistake I made.
---

# Obsidian Vault (Work)

This machine's vault lives at `$HOME/Obsidian` — never hardcode
`/Users/<name>`, resolve `$HOME` at run time.

This vault is Claude Code's durable memory: `autoMemoryEnabled` is off
(`home/common/ai/settings.nix`) so nothing is remembered automatically by the
harness — writes happen because this skill runs, not because of a background
process. Two triggers:

- **Explicit** — the user asks to remember/save/look something up.
- **Proactive** — a corrected mistake, an approved decision, or a standing
  convention, per the "Vault Capture" rules in
  `home/common/ai/instructions/shared-instructions.md`. No need to be asked.

## Scope

This is the **work vault** — company context only: work decisions, lessons
from company projects, Jira/project knowledge, team conventions. Never store
personal content here. The personal machine has its own vault; the two are
strictly separate — never reference or assume content from the other.

## Layout

- Type folders at vault root: `Lessons/`, `Decisions/`, `Process/`,
  `Conventions/`, `Notes/` (catch-all for anything that doesn't fit the rest).
  Create a new folder only for a genuinely new recurring type — don't fragment
  further than that.
- Any type folder that grows past ~15 notes gets subfoldered by area (tech
  stack, project, whatever grouping the notes actually cluster into) — it's
  the only folder depth worth the fragmentation. Nothing else is subfoldered;
  `area` frontmatter covers filtering everywhere else.
- **No hand-maintained index notes.** `Index.md` is the only note at vault
  root, and it just links `Vault.base` — an Obsidian Bases file that derives
  every view (by type, area, project, date) from frontmatter, so nothing goes
  stale.
- `Templates/` holds one starter file per type, excluded from `Vault.base` by
  a folder filter.
- **Title Case** for every note filename.
- Each note is a self-contained unit — one topic/decision/fact per note, not a
  running log.
- `[[wikilinks]]` resolve by filename regardless of folder — no path needed
  in a link, so moving a note between folders never breaks a link.

## Frontmatter

Every note (except `Index.md` and `Templates/`) starts with:

```yaml
---
type: lesson          # lesson | decision | process | convention | note
project: <slug>        # short identifier for the repo/project/client
area: [<tech-or-topic>]
tags: [<coarse-category>]
created: 2026-08-16
---
```

Never leave `project` or `area` empty — an empty list makes the note
invisible in any view grouped or filtered on it.

## Linking

Use Obsidian `[[wikilinks]]` syntax: `[[Note Title]]`. Add links to related
notes at the bottom of a note, under a `## Related` heading.

## Workflows

Search and links are plain-text — use Grep/Glob/Bash, not the Obsidian app.

### Read first

The SessionStart hook already injects full bodies of every note under
`Lessons/`, `Conventions/`, `Decisions/`, `Process/`, and `Notes/` — that
context is already loaded, no grep needed as a first step.

Fall back to a search of the whole vault when the injected context isn't enough — after long-session compaction, for a folder not yet in the hook's fixed list, or to pin down one exact note. Dispatch these to the `vault-search` subagent (Agent tool) rather than grepping inline — it's a read-only lookup on `haiku`, cheaper than burning main-session tokens on `rg`/`fd` output.

### Find notes

Dispatch to `vault-search`: by filename or by content.

### Find backlinks to a note

Dispatch to `vault-search`: "find backlinks to [[Note Title]]".

### Create a note

1. Title Case filename, `.md` extension, written into the matching type
   folder (`Lessons/`, `Decisions/`, `Process/`, `Conventions/`, or `Notes/`
   if nothing fits; subfolder by area only inside a folder that's already
   past ~15 notes). `mkdir -p` the folder first if it doesn't exist yet.
2. Start from `Templates/<Type>.md` — it has the frontmatter block pre-filled.
   Fill in `type`, `project`, `area`, `tags`, `created` (today's date).
3. Content is one unit of learning — what, why, and nothing that belongs in a
   more specific note instead. Write prose as one line per paragraph — never
   hard-wrap. This vault runs with Obsidian's default `strictLineBreaks:
   false`, so every hard-wrapped line renders as a visible break.
4. Add `[[wikilinks]]` to related notes under `## Related`.

### Update a note

Read it first, then edit in place — don't append a dated log entry unless the
note is explicitly a running log.

### Log a lesson

Triggered by a corrected mistake, not by request. Before writing, grep
`Lessons/` for the topic — update an existing note instead of duplicating it.
New lessons go in `Lessons/` (or `Lessons/<Area>/` once that folder is
subfoldered).

```markdown
---
type: lesson
project: <slug>
area: [<area>]
tags: [<coarse-category>]
created: <YYYY-MM-DD>
---

# <Short Title>

**Wrong:** what broke it — the mistaken assumption or action.
**Right:** what fixes it — the rule going forward.

## Related
- [[Some Related Note]]
```

### Log a decision or convention

Triggered by an approved architecture/tech choice (`Decisions/`) or a stated
standing rule for how work happens (`Conventions/`) — not by request. Grep
the target folder for the topic first; update an existing note instead of
duplicating it. Skip if the choice was reverted in the same session, or is a
one-off with no standing pattern.
