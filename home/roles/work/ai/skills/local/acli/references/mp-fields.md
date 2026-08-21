# MP custom field map

acli cannot list or resolve custom field names on its own: `acli jira field` only has `create`/`delete`/`update`/`restore` (no `list`), and `view --fields '*all' --json` always returns `names`/`schema`/`editmeta` as `null` in this acli version. This table was built by creating a fresh MP ticket to enumerate every field ID that exists (78 total on a `Task`), then sampling 15 recently-updated real tickets to see which ones actually carry values, then cross-checking the ambiguous ones against Jira UI screenshots.

**Only fields confirmed below are safe to set via `--field customfield_XXXXX=value` on `scripts/jira_adf.py create`.** For anything not in this table, don't guess an ID, ask the user to set it in the Jira UI, or confirm the field's purpose with them first.

## Confirmed

| ID | Name | Shape | Settable on create? |
|---|---|---|---|
| `customfield_10006` | Sprint | array of sprint objects (`boardId`, `name`, `state`) | Not via acli, Jira assigns this from board/backlog placement, not a create-time attribute worth guessing at |
| `customfield_10007` | Epic Link | epic's issue key as a string, e.g. `"MP-3559"` | Yes, but prefer `--parent` / `parentIssueId` semantics from the acli create flags if the issue type supports it; this field is the classic-project fallback |
| `customfield_10011` | Rank | Lexorank string, e.g. `"2\|hzu39u:qzvm03oz3zzuiwe"` | No, internal ordering, never set manually |
| `customfield_10500` | Development panel | auto-populated PR/commit/branch info | No, read-only, populated by the GitHub integration |
| `customfield_11286` | Stakeholder Department | single-select object (`id`, `value`) | Yes, but pass it as an object, not a bare string: `--field 'customfield_11286={"value": "Development"}'`. A bare string fails with `✗ Error: The Stakeholder Department value must be an object` (confirmed empirically). Options: `Operations`, `Education`, `Misc`, `Development` |

## Medium confidence: inferred from value shape, not confirmed in the UI

| ID | Likely name | Shape observed | Note |
|---|---|---|---|
| `customfield_10004` | Story Points | small integer (`1`, `2`) | Standard Jira Cloud field ID for story points in many classic projects, but not screenshot-confirmed on this board, ask before relying on it |
| `customfield_11353` | Reviewer(s) or QA Assignee(s) | pipe-joined display names, e.g. `"Adriana Cardoso \| Patrícia Costa"` | Two names per ticket suggests a review/QA pairing field, not a single assignee. Confirm which before writing to it. |

## Ambiguous: do not set without checking a same-type recent ticket first

| ID | Observed values | Why it's ambiguous |
|---|---|---|
| `customfield_11284` | usually `["frontend"]`, but sometimes a repo slug like `["mp-salary-v2"]` | Values look like they come from two different pickers, a "Components" picker (Frontend/Backend/Fullstack/DevOps/Design/Maintenance/QA, confirmed in one UI screenshot) and a "Repository" picker (`mp-iac-terraform`, `mp-timeoff-v2`, `mp-contracts`, `mp-salary-legacy`, `auth`, `hub`, etc., confirmed in another screenshot) both feeding the same field ID, or two separate fields that happen to look alike from raw JSON alone. **Don't guess this one**, read a few recent tickets of the same issue type with `view --fields '*all' --json` and match the value style before setting it. |

## Unidentified / low-value, leave alone

`customfield_10000`, `customfield_10001` (a timestamp, cause unclear), `customfield_10922` (small integer, always `0` or `1` in the sample), `customfield_11729` (populated on only 2/15 sampled, object with `id`/`self`, purpose unclear). These are almost certainly Jira-app-internal fields (Jira Service Management, automation, or a third-party marketplace app) rather than something a person fills in when creating a ticket. An MP `Task` exposes far more custom field IDs than the ones documented here; the rest were never observed populated by hand, so treat anything absent from this file as unidentified and ask rather than guessing.

## Refreshing this file

If a field you need isn't here, or a value in the wild doesn't match what's documented: create a throwaway ticket (`create ... --json`, note the key), inspect it with `view --fields '*all' --json`, then delete it (`workitem delete --key <KEY> --yes`), this is how the full 78-field ID list above was originally obtained, since a fresh ticket's `null` fields are the only way acli exposes the complete field set. Cross-reference against a handful of real recent tickets (`search --jql "project = MP AND updated >= -30d"`) to see what's actually populated in practice, and if still ambiguous, ask the user to check the field in the Jira UI (screenshots of the picker are the fastest way to get a confirmed name, there's no acli or REST-free way to resolve one).
