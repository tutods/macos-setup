---
name: obsidian-vault
description: Search, read, and write durable notes in the user's Obsidian vault at $HOME/Obsidian — decisions, research, corrected mistakes, and cross-session context that should outlive a single conversation. Use when the user asks to remember something for later, save a note, look something up in Obsidian, references a past decision that might be logged there, or corrects a mistake I made.
---

# Obsidian Vault

Vault lives at `$HOME/Obsidian` on every machine (path is the same, only
`$HOME` differs between `macbook` and `work` — never hardcode `/Users/<name>`,
resolve `$HOME` at run time).

This vault is Claude Code's durable memory: `autoMemoryEnabled` is off
(`home/common/ai/settings.nix`) so nothing is remembered automatically by the
harness — writes happen because this skill runs, not because of a background
process. Two triggers:

- **Explicit** — the user asks to remember/save/look something up.
- **Proactive** — a corrected mistake, per the "Lessons Learned" rule in
  `home/common/ai/instructions/shared-instructions.md`. No need to be asked.

## Layout

- Flat at vault root — no folders. Organization is links and index notes.
- **Index notes** aggregate a topic (e.g. `Dotfiles Index.md`, `Work Index.md`)
  — a plain list of `[[wikilinks]]`.
- **Title Case** for every note filename.
- Each note is a self-contained unit — one topic/decision/fact per note, not a
  running log.

## Linking

Use Obsidian `[[wikilinks]]` syntax: `[[Note Title]]`. Add links to related
notes at the bottom of a note, under a `## Related` heading.

## Workflows

Search and links are plain-text — use Grep/Glob/Bash, not the Obsidian app.

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
fd -e md "Index" "$HOME/Obsidian"
```

### Create a note

1. Title Case filename, `.md` extension, written straight into `$HOME/Obsidian/`.
2. Content is one unit of learning — what, why, and nothing that belongs in a
   more specific note instead.
3. Add `[[wikilinks]]` to related notes under `## Related`.
4. If a relevant index note exists, add this note's `[[wikilink]]` to it. If
   the topic is new and will grow, create an index note for it.

### Update a note

Read it first, then edit in place — don't append a dated log entry unless the
note is explicitly a running log.

### Log a lesson

Triggered by a corrected mistake, not by request. Before writing, check
`Lessons Index.md` and grep for the topic — update an existing note instead of
duplicating it.

```markdown
# <Short Title>

**Wrong:** what broke it — the mistaken assumption or action.
**Right:** what fixes it — the rule going forward.

Context: <repo/stack, one line>

## Related
- [[Lessons Index]]
```

Link it from `Lessons Index.md` (create that index note on the first lesson).
