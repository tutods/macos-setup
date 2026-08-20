# ADF (Atlassian Document Format)

Jira Cloud descriptions and comments are ADF — a JSON tree — not Markdown.
`--description`/`--body`/`--description-file` on acli accept **plain text
only**; passing Markdown there gets stored literally, `**bold**` and all.
Real formatting requires an ADF JSON object passed via `--from-json`
(descriptions) or `--body-file` (comments).

## Don't hand-write it — use the script

`scripts/jira_adf.py` converts Markdown to ADF and builds the full acli
payloads. This exists because hand-written ADF is exactly where mistakes
happen silently: Jira accepts a malformed node shape without complaint and
just renders a wall of text, so there's no error to catch the mistake.

```sh
# Full create payload (writes ADF description + labels + custom fields inline)
python3 scripts/jira_adf.py create \
  --project MP --type Task --summary "Add data-testid to X" \
  --description-md /tmp/desc.md \
  --label "frontend" \
  --field customfield_11286=Development \
  > /tmp/payload.json
acli jira workitem create --from-json /tmp/payload.json --json

# Full edit payload (no custom fields — acli edit rejects additionalAttributes)
python3 scripts/jira_adf.py edit --key MP-123 \
  --description-md /tmp/desc.md --add-label urgent \
  > /tmp/edit.json
acli jira workitem edit --from-json /tmp/edit.json --yes --json

# Comment body as ADF (new comment)
python3 scripts/jira_adf.py comment /tmp/comment.md > /tmp/comment.json
acli jira workitem comment create --key MP-123 --body-file /tmp/comment.json

# Comment body as ADF (editing an existing comment) — note the flag change:
# update's -F/--body-file is plain-text only, ADF goes through --body-adf instead.
acli jira workitem comment update --key MP-123 --id 10001 --body-adf /tmp/comment.json

# Just the ADF doc, e.g. to inspect it or feed something else
python3 scripts/jira_adf.py doc /tmp/desc.md

# --site overrides the auto-detected Jira site (parsed from `acli jira auth
# status`) used to build issue-key browse links. Only needed when working
# against a site other than the one the current session is logged into.
python3 scripts/jira_adf.py comment /tmp/comment.md --site othersite.atlassian.net
```

## Linking rules

A reference nobody can click is a reference nobody follows. The script
enforces this for the two reference types that dominate Jira comments and
descriptions, on top of the bare-URL autolinking above:

- **Issue keys** (`MP-1234`): the *first* mention of each distinct key in a
  document becomes a Jira smart link (`inlineCard`, renders as
  `KEY: Summary [Status]`) — the same node the Jira editor produces when you
  paste a browse URL and press space. Later mentions of the same key stay
  plain text; carding every occurrence in a sentence that lists nine tickets
  turns it into an unreadable wall of cards. A bare
  `https://<site>/browse/MP-1234` URL is carded the same way and counts
  toward the same first-mention budget. Keys inside a code span or an
  explicit `[text](url)` markdown link are left alone, same as autolinking.
  Headings are never carded — an `inlineCard` there is a shape not worth
  risking against Jira's validator, and it reads badly regardless.
- **PRs**: always write the full PR URL, never a bare `#460` — a bare number
  identifies nothing outside the repo it was typed in, and Jira can't turn it
  into a link. The script warns on stderr (doesn't block) when it sees one.

## Markdown subset the script understands

| Markdown | ADF node |
|---|---|
| `# ` .. `######` | `heading`, `attrs.level` 1–6 |
| plain line(s) | `paragraph` |
| `**bold**` | `text` with `marks: [{type: strong}]` |
| `*italic*` | `text` with `marks: [{type: em}]` |
| `` `code` `` | `text` with `marks: [{type: code}]` |
| `[text](url)` | `text` with `marks: [{type: link, attrs: {href}}]` |
| bare `https://…` / `www.…` | same `link` mark, autolinked — no `[]()` needed |
| bare issue key, e.g. `MP-1234` | `inlineCard` (Jira smart link), first mention per document only |
| bare `<site>/browse/MP-1234` URL | same `inlineCard`, and counts as that key's first mention |
| `- item` / `* item` | `bulletList` > `listItem` > `paragraph` |
| `1. item` | `orderedList` > `listItem` > `paragraph` |
| `- [ ] item`, `[ ] item`, `[] item`, `[x] item` | `taskList` > `taskItem`, `state: TODO`/`DONE` |
| ` ```lang ... ``` ` | `codeBlock`, `attrs.language` |
| `---` | `rule` |
| `\| a \| b \|` rows (2nd row `\|---\|---\|`) | `table` > `tableRow` > `tableHeader`/`tableCell` > `paragraph` |

**The bare-checklist trap:** tickets typed by hand frequently write checklist
items as `[] do the thing` or `[ ] do the thing` with no leading `- `. The
script treats the `[ ]`/`[x]` marker as sufficient on its own — it does not
require a bullet dash. If you're ever tempted to write ADF by hand instead of
through the script, this is the detail that's easiest to get wrong and hardest
to notice, because the ticket still looks fine at a glance in the Jira editor
preview and only breaks in the stored structure.

## Reading ADF back

`view <KEY> --json | jq .fields.description` gives the full ADF tree —
useful when editing a description and you need to preserve everything that
isn't changing (never regenerate a whole description from scratch when only
one section changed; read the current ADF, edit the relevant node, re-emit).
Plain `view <KEY>` (no `--json`) flattens all structure to run-on text — fine
for a quick read, useless for checking whether formatting survived.

## Payload shapes (verified against `acli jira workitem create/edit --generate-json`)

```json
// create --from-json
{
  "projectKey": "MP",
  "type": "Task",
  "summary": "...",
  "description": { "version": 1, "type": "doc", "content": [...] },
  "assignee": "email or @me (optional)",
  "reporter": "email (optional)",
  "labels": ["a", "b"],
  "parentIssueId": "MP-100",
  "additionalAttributes": { "customfield_11286": "Development" }
}
```

```json
// edit --from-json — NOTE: no additionalAttributes key exists here
{
  "issues": ["MP-123"],
  "summary": "...",
  "type": "...",
  "description": { "version": 1, "type": "doc", "content": [...] },
  "assignee": "...",
  "labelsToAdd": ["a"],
  "labelsToRemove": ["b"]
}
```

Custom fields are create-only through acli (`edit --from-json` with
`additionalAttributes` fails with `unknown field "additionalAttributes"` —
verified, not documented by Atlassian). If a custom field needs to change on
an existing ticket, there's no acli path — tell the user to set it in the
Jira UI.
