---
name: acli
description: Use the Atlassian CLI (acli) to read, create, edit, transition, comment on, and search Jira work items, and to read Confluence pages/spaces. Trigger this whenever Jira comes up in any form — a ticket key like MP-1234, "file a bug", "create a ticket", "what's on my board", "move this to In Review", "update the ticket description", "who's this assigned to", "leave a comment on the ticket", "list my open tickets", JQL, epics, sprints, or a Confluence page/space URL. Every acli flag and payload shape here has been verified against the installed binary (1.3.22) — use this instead of guessing acli flags or hand-writing Jira description JSON, both of which fail silently (wrong flag errors out, but malformed description JSON gets accepted and just renders as unformatted text).
---

# acli (Atlassian CLI)

acli talks to Jira and Confluence Cloud. The commands look simple but two
things go wrong constantly if you improvise: flags that look symmetric
across sibling commands (`create`/`edit`/`comment`) actually aren't, and
Jira renders ADF (a JSON document format), not Markdown — so a
Markdown-formatted description gets stored as a literal string with the
`**` and `##` characters still in it, no error, no warning.

This skill exists to remove both failure modes. Read the reference file the
task actually needs; don't try to hold all of it in your head.

| Reference | Read it when |
|---|---|
| `references/jira-commands.md` | Composing any acli jira command — authoritative flags, verified traps |
| `references/adf.md` | Writing or reading any description or comment |
| `references/jql.md` | Searching, or bulk-editing/transitioning via `--jql` |
| `references/mp-conventions.md` | Working on the `MP` (Mindera People) project specifically |
| `references/mp-fields.md` | Setting a custom field on an MP ticket |
| `references/confluence.md` | Anything Confluence |
| `scripts/jira_adf.py` | Building any description, comment body, create payload, or edit payload — always through this script, never by hand |

## Preflight

Run `acli jira auth status` before anything else in a session. If it's not
authenticated, tell the user to run `acli auth login` and stop — don't guess
a site or proceed assuming credentials exist.

## The rules that matter most

**1. Read plain, not `--json`, unless something will parse the output.**
`view MP-4330` is 2,105 bytes plain vs 13,485 bytes with `--json` — 6.4x for
identical information, because plain output already flattens the ADF
description into readable text. Reach for `--json` when you're piping into
`jq`, need the full field set, or need to inspect ADF structure (checking
whether a description's formatting actually survived, or reading a comment's
full body — `comment list --json`'s `body` field is a lossy text summary; only
`view --fields comment --json` has the real thing).

**2. Never hand-write ADF, and never decide plain text is "good enough."**
Jira descriptions and comment bodies are a JSON tree, not Markdown, and
`--description`/`--body`/`--description-file` accept plain text only. Every
description and every comment goes through `scripts/jira_adf.py` — write the
content as a `.md` file and run it — with **no exception for content that
looks simple.** The instinct to skip the script for "just a few bullet
points" is exactly how this goes wrong: a plain-text body with `- item` lines
or `` `code` `` spans in it doesn't render as a list or inline code, it
renders as literal dashes and backticks in the Jira UI — worse than not
attempting formatting at all, since it looks like a mistake rather than a
deliberate plain note. If the content truly has zero structure (a single
short sentence, no bullets, no headings, no code, no bold), plain
`--body`/`--description` is fine; anything with even one list item or one
inline code reference goes through the script. See `references/adf.md`.

**3. Don't guess a flag.** `create` uses `--label` (singular); `edit` uses
`--labels`/`--remove-labels`; the `edit --from-json` payload uses
`labelsToAdd`/`labelsToRemove` instead — three names for one concept across
three surfaces. `comment create`'s body-file flag is `-F`; `assign`'s
from-file flag is `-f` — same letter, opposite case, unrelated. Full list in
`references/jira-commands.md`'s trap table; when a command isn't covered
there, run `acli <path> --help` and read it rather than pattern-matching from
a sibling command.

**4. `--yes` isn't universal.** Required on `edit`, `transition`, `assign`,
`clone`, `delete` — omitting it hangs waiting for an interactive confirm that
never comes in a non-interactive shell. **Not present** on `comment create`,
which never prompts. Check the specific command's flags rather than adding
`--yes` reflexively everywhere.

**5. Custom fields are create-only.** `acli jira workitem edit --from-json`
rejects an `additionalAttributes` key outright (`unknown field
"additionalAttributes"` — verified, not documented anywhere by Atlassian).
If a custom field needs to change on an existing ticket, there's no acli
path for it; tell the user to use the Jira UI. On create, use
`scripts/jira_adf.py create --field customfield_XXXXX=value`, and only for
fields listed as confirmed or medium-confidence in `mp-fields.md` — the
board has 78 custom field IDs and acli exposes no way to list or name them,
so most are genuinely unidentifiable without asking a human to check the UI.

**6. Discover, don't assume.**
- Project key: match `[A-Z][A-Z0-9]+-[0-9]+` in the current git branch name
  if one exists; otherwise `acli jira project list --json` and ask.
- Epics: `search --jql "project = X AND issuetype = Epic AND status != Done"`.
  Never invent an epic key.
- Transitions: acli gives no "list valid transitions" command, and an invalid
  status name's error doesn't list valid ones either (`No allowed
  transitions found for given status` — that's the entire message). For MP,
  `mp-conventions.md` has the observed status sequence; for anything else,
  ask.

**7. Only touch the ticket(s) the task actually named.** If a search or a
"let me double check" step surfaces a different ticket that looks related,
wrong, or duplicated — report it, don't fix it. Editing a ticket nobody
asked about, even a small label tweak, is a mutation the user never
authorized. Flag what you noticed and let them decide.

**8. Confirm before mutating.** Before `create`/`edit`/`transition`/`delete`,
show the user a short preview — project, type, summary, epic/parent, labels,
any custom fields, and the description's outline (headings/sections, not the
full rendered text) — and get explicit confirmation. This is cheap and it's
the only backstop against acting on a misread of the user's intent for
something that writes to a shared system.

## Mindera People (`MP`) specifics

If the ticket is on the `MP` project, read `references/mp-conventions.md`
(issue types, statuses, boards, active epics, label vocabulary) and
`references/mp-fields.md` (which custom fields are known-safe to set) before
composing a create or edit. Both files say plainly where the picture is
incomplete — respect that rather than filling gaps with a plausible guess;
a wrong custom field value is worse than an omitted one.

## Confluence

Much thinner surface than Jira in this acli version — `references/confluence.md`
covers `page view`, `space list/view`, `blog list/view/create`. Notably,
`page` has no `create`/`update` — say so directly if asked for one instead of
trying to force a nonexistent flag.
