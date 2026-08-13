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
- **Proactive** — a corrected mistake, per the "Lessons Learned" rule in
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
- **Index notes** live at vault root, outside the type folders — they're
  navigation, not content. `Index.md` is the entry point, linking topic
  indexes like `Lessons Index.md` and `Projects Knowledge Index.md`, each a
  plain list of `[[wikilinks]]`.
- **Title Case** for every note filename.
- Each note is a self-contained unit — one topic/decision/fact per note, not a
  running log.
- `[[wikilinks]]` resolve by filename regardless of folder — no path needed
  in a link, so moving a note between folders never breaks a link.

## Linking

Use Obsidian `[[wikilinks]]` syntax: `[[Note Title]]`. Add links to related
notes at the bottom of a note, under a `## Related` heading.

## Workflows

Search and links are plain-text — use Grep/Glob/Bash, not the Obsidian app.

### Read first

At the start of any non-trivial task, check the vault for prior art before
working:

```bash
rg -il "<topic keywords>" "$HOME/Obsidian"
```

Read matching `Lessons/` and `Conventions/` notes before starting. A logged
lesson that isn't consulted is dead weight. Cheap when nothing matches; skip
only for trivial one-liners.

### Find notes

```bash
# By filename
fd -e md . "$HOME/Obsidian" | rg -i "keyword"

# By content
rg -il "keyword" "$HOME/Obsidian"
```

### Find backlinks to a note

```bash
rg -l "\[\[Note Title\]\]" "$HOME/Obsidian"
```

### Find index notes

```bash
fd -e md -d 1 "Index" "$HOME/Obsidian"
```

### Create a note

1. Title Case filename, `.md` extension, written into the matching type
   folder (`Lessons/`, `Decisions/`, `Process/`, `Conventions/`, or `Notes/`
   if nothing fits). `mkdir -p` the folder first if it doesn't exist yet — the
   vault only ships with `Index.md`, type folders appear on first use.
2. Content is one unit of learning — what, why, and nothing that belongs in a
   more specific note instead.
3. Add `[[wikilinks]]` to related notes under `## Related`.
4. If a relevant index note exists, add this note's `[[wikilink]]` to it. If
   the topic is new and will grow, create an index note for it at vault root.

### Update a note

Read it first, then edit in place — don't append a dated log entry unless the
note is explicitly a running log.

### Log a lesson

Triggered by a corrected mistake, not by request. Before writing, check
`Lessons Index.md` and grep `Lessons/` for the topic — update an existing note
instead of duplicating it. New lessons go in `Lessons/`.

```markdown
# <Short Title>

**Wrong:** what broke it — the mistaken assumption or action.
**Right:** what fixes it — the rule going forward.

Context: <repo/stack, one line>

## Related
- [[Lessons Index]]
```

Link it from `Lessons Index.md` (create that index note on the first lesson).
