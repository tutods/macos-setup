# acli jira, verified command reference

Verified against `acli version 1.3.22-stable`. If a command you need isn't
here, run `acli jira <path> --help` and read the actual output before
composing a call, acli's flags are not consistent across sibling commands
(see the traps section at the end), and a plausible-looking flag either
silently no-ops or errors with `unknown flag`.

## Auth

```sh
acli jira auth status   # confirms site + email; run this first, every session
acli jira auth login    # only if status fails
```

## workitem create

```
--project <KEY>          required
--type <IssueType>       required, case-sensitive: Task, Story, Bug, Epic, Spike, Sub-task
--summary <text>         required
--description <text>     PLAIN TEXT ONLY, do not use for real descriptions, see adf.md
--description-file <path> also plain text, same caveat
--assignee <email|@me|default>
--label <a,b,c>          singular flag name, comma-separated
--parent <KEY>           parent work item ID (sub-tasks)
--from-json <path>       full payload, required for ADF descriptions and custom fields
--generate-json          dumps the JSON schema acli expects, run this if unsure, don't guess
--json                   JSON output
```

`--from-json` payload shape (from `--generate-json`, field names matter):

```json
{
  "projectKey": "MP",
  "type": "Task",
  "summary": "...",
  "description": { "...ADF doc, see adf.md..." },
  "assignee": "email or @me (optional)",
  "reporter": "email (optional)",
  "labels": ["a", "b"],
  "parentIssueId": "MP-100",
  "additionalAttributes": { "customfield_XXXXX": "value" }
}
```

Build this with `scripts/jira_adf.py create ...`, don't hand-write it.

## workitem edit

```
--key <K1,K2>             OR --jql <query> OR --filter <id>
--summary <text>
--description <text>      PLAIN TEXT, same caveat as create
--assignee <email|@me|default>
--labels <a,b>            PLURAL here (differs from create's --label)
--remove-labels <a,b>
--type <IssueType>
--from-json <path>
--yes                     REQUIRED to skip an interactive confirm prompt that hangs non-interactively
```

`--from-json` payload shape:

```json
{
  "issues": ["MP-123"],
  "summary": "...",
  "type": "...",
  "description": { "...ADF..." },
  "assignee": "...",
  "labelsToAdd": ["a"],
  "labelsToRemove": ["b"]
}
```

**No `additionalAttributes` on edit.** Verified empirically: passing it fails with
`json: unknown field "additionalAttributes"`. Custom fields can only be set at
create time via acli, see `mp-fields.md` for the practical implication.

## workitem view

```
acli jira workitem view <KEY>                          # plain, human-readable, ADF flattened to text
acli jira workitem view <KEY> --json                    # structured, full ADF preserved
acli jira workitem view <KEY> --fields "summary,status" # narrow the field set
acli jira workitem view <KEY> --fields "comment" --json  # only way to read a comment's full ADF body
```

**Read economy, measured, not a guess:** `view MP-4330` plain = 2,105 bytes;
`--json` on the same ticket = 13,485 bytes (6.4x). Default to plain for a
quick read. Reach for `--json` only when the output feeds `jq`, or when you
need to inspect structure (e.g. confirming a description's ADF nodes, or
reading a comment body in full, `comment list --json` truncates the body to
a lossy text summary, only `view --fields comment --json` gives the real ADF).

`--fields '*all'` returns every field, but `names`, `schema`, `editmeta`, and
`renderedFields` are always `null` in this acli version, there's no field
name lookup available from `view`. See `mp-fields.md`.

## workitem search

```
--jql "<JQL>"             see jql.md for patterns
--fields "key,summary,status"   default is issuetype,key,assignee,priority,status,summary
--limit <n>
--paginate
--count                    just the count
--csv / --json
```

Field allowlist: `search --fields` rejects custom field IDs outright,
`--fields customfield_11284` fails with `fields '...' are not allowed`. Custom
fields are only readable via `view`, not `search`.

## workitem transition

```
--key <K1,K2>              OR --jql / --filter
--status "<Status Name>"   exact display name, case-sensitive-ish, quote if it has spaces
--yes                      required
```

**No hint on failure.** Verified empirically: an invalid status name returns
`✗ Failure: <KEY> can't be transitioned: No allowed transitions found for
given status`, it does NOT enumerate valid next statuses. Don't guess a
status name hoping the error will correct you; check `mp-conventions.md` for
the known MP workflow, or ask the user.

## workitem assign

```
--key <K1,K2> --assignee <email|@me|default>
--remove-assignee
--yes
```

## workitem comment

```
acli jira workitem comment create --key <KEY> --body "<plain text>"
acli jira workitem comment create --key <KEY> --body-file <path.json>   # ADF, see adf.md
acli jira workitem comment update --key <KEY> --id <commentId> --body-adf <path.json>   # ADF, NOT --body-file
acli jira workitem comment list --key <KEY> --json    # body field is a LOSSY TEXT SUMMARY
```

**No `--yes` flag on `comment create`**: it doesn't prompt, unlike edit/transition/assign.
**`-F`/`--body-file`** (capital F), don't confuse with `assign`'s `-f/--from-file`
or `workitem create`'s `-f/--from-file`; the short flag means different things
on different commands.

Verified empirically: on `comment create`, `-F`/`--body-file` accepts a raw ADF
doc JSON file directly (not just plain text) and it round-trips byte-for-byte
into the stored comment. Build it with `scripts/jira_adf.py comment <file.md>`.

**`comment update` does NOT follow the same rule as `create`.** Its own
`--help` labels `-F`/`--body-file` "Plain text file containing comment body",
feeding it an ADF JSON file stores the literal JSON text as the comment body
(no error, renders as a wall of `{ "type": "doc", ...}` in Jira). `update` has
a separate `--body-adf <path.json>` flag for ADF instead. Always use
`--body-adf` when updating an existing comment with formatted content;
`-F`/`--body-file` there is for plain text only.

## workitem delete / clone / link / attachment

```
acli jira workitem delete --key <K1,K2> --yes
acli jira workitem comment delete --key <KEY> --id <commentId>   # --help's own example wrongly shows --issue; the real flag is --key
acli jira workitem clone --key <K> --to-project <KEY> --yes
acli jira workitem link create ...   # acli jira workitem link create --help for the exact link-type flags
acli jira workitem attachment list --key <K>
```

## project / board / sprint

```
acli jira project list --json                 # discover project keys
acli jira project view --key MP --json        # issue types, style, name
acli jira board search --project MP --json    # boards for a project (MP has 4: see mp-conventions.md)
acli jira board list-sprints --id <boardId> --json
acli jira sprint list-workitems --sprint <id> --board <id> --json
```

## Flag traps: read before composing a command

| Trap | Detail |
|---|---|
| `create --label` vs `edit --labels` | singular on create, plural on edit. `edit`'s remove flag is `--remove-labels`; the edit JSON payload uses `labelsToAdd`/`labelsToRemove` instead, three different names for the same concept across three surfaces. |
| `comment create -F/--body-file` vs `assign -f/--from-file` | same short flag letter, opposite case, unrelated meaning. Always use the long flag name to avoid mixing them up. |
| `comment update -F/--body-file` is plain text ONLY | `create -F` takes raw ADF JSON and round-trips it; `update -F` stores that JSON as literal text, no error. Formatted updates (tables especially) must use `--body-adf`. The most-repeated mistake with this skill. |
| `--yes` isn't universal | Present on `edit`, `transition`, `assign`, `clone`, `delete`. **Absent** on `comment create` (it never prompts). Don't add it reflexively, check the command's own `--help`. |
| `search --fields` has an allowlist | Rejects `customfield_*` outright. Custom fields are `view`-only. |
| `edit --from-json` rejects `additionalAttributes` | Confirmed by testing, not documented by acli. Custom fields: create-only. |
| Transition errors don't list options | Don't loop guessing status names hoping for a hint, none comes. |
| `acli auth token` does not exist | There is no acli subcommand that emits a bearer token for raw REST calls. Don't reach for the REST API as a workaround, ask the user. |
