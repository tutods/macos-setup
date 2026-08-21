---
name: acli
description: Use the Atlassian CLI (acli) to read, create, edit, transition, comment on, and search Jira work items, and to read Confluence pages/spaces. Trigger this whenever Jira comes up in any form, a ticket key like MP-1234, "file a bug", "create a ticket", "what's on my board", "move this to In Review", "update the ticket description", "who's this assigned to", "leave a comment on the ticket", "list my open tickets", JQL, epics, sprints, or a Confluence page/space URL.
---

# acli (Atlassian CLI)

acli talks to Jira and Confluence Cloud. Two things go wrong constantly if you improvise: flags that look symmetric across sibling commands aren't, and Jira renders ADF (a JSON tree), not Markdown, so a Markdown description gets stored with its `**` and `##` intact, no error and no warning.

Read the reference the task needs; don't try to hold all of it in your head.

| Reference | Read it when |
|---|---|
| `references/jira-commands.md` | Composing any acli jira command, authoritative flags, verified traps |
| `references/adf.md` | Writing or reading any description or comment |
| `references/jql.md` | Searching, or bulk-editing/transitioning via `--jql` |
| `references/mp-conventions.md` | Working on the `MP` (Mindera People) project specifically |
| `references/mp-fields.md` | Setting a custom field on an MP ticket |
| `references/confluence.md` | Anything Confluence |
| `scripts/jira_adf.py` | Building any description, comment body, create payload, or edit payload, always through this script, never by hand |

## Preflight

Run `acli jira auth status` before anything else in a session. If it's not authenticated, tell the user to run `acli auth login` and stop, don't guess a site or proceed assuming credentials exist.

## The rules that matter most

**1. Read plain, not `--json`, unless something will parse the output.** `view MP-4330` is 2,105 bytes plain vs 13,485 with `--json`, for identical information. Reach for `--json` when piping into `jq`, when you need the full field set, or when you need real ADF structure, `comment list --json`'s `body` is a lossy summary; only `view --fields comment --json` has the real thing.

**2. Never hand-write ADF, and never decide plain text is "good enough."** Every description and every comment goes through `scripts/jira_adf.py`: write the content as a `.md` file, run it, pass the output. No exception for content that looks simple, a plain body renders `- item` as a literal dash, `` `code` `` with its backticks, and a bare URL as dead text. See `references/adf.md`.

**3. `comment update`'s `-F`/`--body-file` is plain text only, `comment create`'s isn't.** This asymmetry is the single most-repeated mistake with this skill. `create -F` accepts a raw ADF JSON file and stores it byte-for-byte; `update -F` stores whatever you give it as literal text, JSON braces and all, with no error. Updating an existing comment with formatted content always goes `jira_adf.py comment <file.md>` → `comment update --body-adf <output.json>`, never `--body-file`. This is what breaks tables in particular: the script renders a Markdown table into a real ADF `table` node, and `--body-file` on update dumps that JSON into the comment as visible text. See `references/jira-commands.md`'s comment section.

**4. Every reference must be reachable.** `scripts/jira_adf.py` cards the first mention of each issue key automatically, just write `MP-1234`. PRs aren't auto-detected: always write the full PR URL, never a bare `#460`. See `references/adf.md`'s "Linking rules".

**5. Don't guess a flag.** `create` uses `--label`, `edit` uses `--labels`, the `edit --from-json` payload uses `labelsToAdd`, three names for one concept. `--yes` is required on `edit`/`transition`/`assign`/`clone`/`delete` and absent on `comment create`. Custom fields are create-only. The trap table in `references/jira-commands.md` is authoritative; when a command isn't covered there, run `acli <path> --help` rather than pattern-matching from a sibling.

**6. Discover, don't assume.**
- Project key: match `[A-Z][A-Z0-9]+-[0-9]+` in the current git branch name if one exists; otherwise `acli jira project list --json` and ask.
- Epics: `search --jql "project = X AND issuetype = Epic AND status != Done"`. Never invent an epic key.
- Transitions: acli has no "list valid transitions" command, and an invalid status name's error doesn't list the valid ones. For MP, `mp-conventions.md` has the observed sequence; for anything else, ask.

**7. Only touch the ticket(s) the task actually named.** If a search surfaces a different ticket that looks related, wrong, or duplicated, report it, don't fix it. Editing a ticket nobody asked about, even a label tweak, is an unauthorized mutation.

**8. Confirm before mutating.** Before `create`/`edit`/`transition`/`delete`, show a short preview, project, type, summary, epic/parent, labels, custom fields, and the description's outline, and get explicit confirmation.

## Mindera People (`MP`) specifics

Read `references/mp-conventions.md` (issue types, statuses, boards, label vocabulary) and `references/mp-fields.md` (which custom fields are known-safe to set) before composing a create or edit. Both say plainly where the picture is incomplete, respect that rather than filling gaps with a plausible guess.

## Confluence

Much thinner surface than Jira in this acli version, `references/confluence.md` covers `page view`, `space list/view`, `blog list/view/create`. `page` has no `create`/`update`: say so directly instead of forcing a nonexistent flag.
