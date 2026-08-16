---
name: obsidian-vault
description: Search, read, and write durable personal notes in the Obsidian vault at $HOME/Obsidian — personal project decisions, content/blog/SEO research, corrected mistakes, and cross-session context that should outlive a single conversation. Use when the user asks to remember something for later, save a note, look something up in Obsidian, references a past decision that might be logged there, or corrects a mistake I made.
---

# Obsidian Vault (Personal)

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

This is the **personal vault** — personal context only: side-project
decisions, content/blog/SEO research, lessons from personal work. No company
data belongs here. The work machine has its own vault; the two are strictly
separate — never reference or assume content from the other.

## Layout

- Type folders at vault root: `Lessons/`, `Decisions/`, `Process/`,
  `Conventions/`, `Notes/` (catch-all for anything that doesn't fit the rest).
  Create a new folder only for a genuinely new recurring type — don't fragment
  further than that.
- `Lessons/` is subfoldered by area (`Docker/`, `Doppler/`, `GitHub/`,
  `Payload/`, `Frontend/`, `Backend/`, `Tooling/`) — it's the one folder big
  enough to be worth browsing. Nothing else is subfoldered; `area` frontmatter
  covers filtering everywhere else.
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
project: molar        # short slug for the repo/side-project
area: [payload, postgres]   # tech areas, lowercase
tags: [backend]        # coarse: backend | frontend | devops | tooling | compliance | ai
created: 2026-08-12
---
```

`area` and `tags` aren't redundant: `tags` feeds Obsidian's tag pane and
`file.hasTag()`; `area` is free-form for fine-grained Bases filtering. Never
leave `project` or `area` empty — an empty list makes the note invisible in
any view grouped or filtered on it.

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

### Create a note

1. Title Case filename, `.md` extension, written into the matching type
   folder (`Lessons/`, `Decisions/`, `Process/`, `Conventions/`, or `Notes/`
   if nothing fits; `Lessons/` also needs an area subfolder). `mkdir -p` the
   folder first if it doesn't exist yet.
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
New lessons go in `Lessons/<Area>/`.

```markdown
---
type: lesson
project: <slug>
area: [<area>]
tags: [<backend|frontend|devops|tooling|compliance|ai>]
created: <YYYY-MM-DD>
---

# <Short Title>

**Wrong:** what broke it — the mistaken assumption or action.
**Right:** what fixes it — the rule going forward.

## Related
- [[Some Related Note]]
```
