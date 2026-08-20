# JQL patterns

Pass via `--jql "..."` to `workitem search`, `edit`, `transition`, `assign`, `clone`.

```sh
# Open tickets in a project
--jql "project = MP AND status != Done"

# Mine
--jql "assignee = currentUser()"
--jql "assignee = currentUser() AND status not in (Done, 'Ready for PROD')"

# By type, recency
--jql "project = MP AND type = Bug AND created >= startOfWeek()"
--jql "project = MP AND updated >= -7d ORDER BY updated DESC"

# By label
--jql "project = MP AND labels = frontend"

# Text search (summary contains)
--jql "project = MP AND summary ~ \"worked holidays\""

# Priority
--jql "project = MP AND priority in (High, Highest) AND status != Done"

# Epics in a project (for epic discovery before creating a child ticket)
--jql "project = MP AND issuetype = Epic"
--jql "project = MP AND issuetype = Epic AND status != Done ORDER BY updated DESC"

# Children of an epic (classic project: Epic Link is customfield_10007,
# but JQL exposes it as "Epic Link" or the epic's key directly, verify
# with a known epic before relying on this in a script)
--jql "\"Epic Link\" = MP-3559"
```

## Functions that come up often

`currentUser()`, `startOfWeek()` / `startOfMonth()` / `startOfYear()` (and
`endOf*` variants), `now()`, relative dates (`-7d`, `-1M`).

## Combining with acli mutation commands

`edit`, `transition`, `assign`, `clone` all accept `--jql` instead of `--key`
to operate on a whole result set at once. This is powerful and destructive,
always run the equivalent `search --jql "..." --json` first to see exactly
which tickets will be affected, and show that list to the user before firing
a bulk mutation.
