# Project Rules

Rules that only apply to **one** project. They do not belong on this machine.

A rule earns a place in `home/common/ai/instructions/` only if it holds in
every session. A rule earns a place in `home/common/ai/skills/local/` if it holds for a whole
stack. Everything below is narrower than that — it is true of exactly one
repository, and it should travel with that repository so it also applies when
someone else (or another machine) works on it.

## Installing

Each file here is drop-in content for that project's own `CLAUDE.md` at the
repo root. Append it — don't overwrite an existing `CLAUDE.md`:

```bash
cat ~/.dotfiles/docs/project-rules/<project>.md >> ~/Developer/<path>/<project>/CLAUDE.md
```

Then commit it in that repo. Once it lands there, delete the file here — this
directory is a staging area, not a second source of truth.

## Status

| Project | File | Installed? |
|---------|------|-----------|
| a-optica (freelance) | `a-optica.md` | ☐ |
| jps | `jps.md` | ☐ |
| tutods | `tutods.md` | ☐ |
| lib (`@tutods/*` configs) | `lib.md` | ☐ |

## One thing to check first

`docs/ai-lessons.md` records that a-optica's session-memory rules were ported
into that repo's `.universal-ai-config/instructions/` on 2026-07-19. That format
is being retired — the stack is Claude Code only now. When installing
`a-optica.md`, fold whatever still lives in `.universal-ai-config/` into
`CLAUDE.md` and delete the directory, rather than leaving two sets of rules that
disagree.
