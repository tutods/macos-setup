# MP (Mindera People) project conventions

Project key `MP`, classic software project, id `13313`. This file is what
`SKILL.md` says to read before creating or managing a ticket on this board —
it exists because acli can't discover most of this itself (no field-name
lookup, no "list valid transitions" command).

## Issue types

`Task`, `Story`, `Bug`, `Epic`, `Spike`, `Sub-task`, `Test Bug` (the last two
are sub-task-shaped: `subtask: true`). In the last 30 days of activity, `Task`
and `Story` dominate; `Bug` and `Spike` are used correctly for their names;
`Sub-task`/`Test Bug` are for children of a parent ticket, not standalone work.

## Statuses observed (last 30 days of activity)

`In definition` → `To Do` → `In Progress` → `In Review` → `Ready for QA` →
`Testing` → `Ready for PROD` → `Done`. This is the order they appear in
recent history, not a confirmed workflow diagram — acli has no "list
transitions" command (see `jira-commands.md`'s transition trap), so treat
this as the best available guess for `--status` on a `transition` call, and
if a transition fails, ask the user for the exact status name rather than
guessing a second time.

## Boards (4, via `board search --project MP --json`)

| id | name | type |
|---|---|---|
| 218 | MP Board | scrum |
| 911 | MP Full Picture | scrum |
| 312 | MP Release board | kanban |
| 1275 | AI Migration to Nest | kanban |

`218` (MP Board) is the one that shows up in the Sprint field
(`customfield_10006`) on regular feature tickets — default to it unless the
ticket is release- or AI-migration-specific.

## Epics

Discover live epics with:

```sh
acli jira workitem search --jql "project = MP AND issuetype = Epic AND status != Done" \
  --fields "key,summary,status" --limit 50 --json
```

Frontend-relevant epics seen recently (not exhaustive — always re-query,
this list goes stale): `MP-3559` QoL Features 2026, `MP-3564` Technical Debt
2026, `MP-3533` Bugs 2026, `MP-3558` Maintenance 2026, `MP-3520` UI
Modernization (Done), `MP-2920`/`MP-3600` Feedback Components / Feedback,
`MP-3587` Communications Hub. When a ticket doesn't obviously belong to a
named initiative, `MP-3564` (Technical Debt 2026) or `MP-3533` (Bugs 2026) is
usually the closest fit for FE work — confirm with the user before assuming.

## Labels (standard Jira `labels` field, not a custom field)

Observed label vocabulary in use on this board (from the label picker):
`NoQA`, `AI`, `CI/CD`, `StoryBookReview`, `Non-Deliverable`, `Frontend`,
`Evergreen`, and others. `NoQA` in particular is meaningful — it marks a
ticket as not requiring QA sign-off before Done. Ask before inventing a new
label; check the picker (`acli` can't list valid labels — this has to be a
human check in the Jira UI, or inferred from `search --jql "project = MP" --fields labels`
on recent tickets) rather than guessing free text.

## Custom fields

See `mp-fields.md`.
