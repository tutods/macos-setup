---
name: github-project-hygiene
description: >
  Auditing and fixing GitHub Projects v2 boards across the user's personal
  GitHub identity — epics missing sub-issue links, custom project fields
  left empty once an item moves past Ready, and Status drifting from the
  item's real PR/branch state. Use when asked to audit or fix a GitHub
  Project, check epic/sub-issue hygiene, or when project board fields, status
  columns, or sub-issue linkage come up for a repo under one of the user's
  personal GitHub orgs.
---

# GitHub Project hygiene

The brief names the org(s) and, optionally, specific boards to run against.
Boards and their attached repos get reconfigured over time, so always
discover live rather than trusting a memorized list:

## Discovery commands

```bash
gh project list --owner <org>                              # boards + numbers
gh project field-list <num> --owner <org> --format json     # fields, incl. option IDs for single-selects
gh project item-list <num> --owner <org> --limit 1000 --format json   # every item, with its field values
gh project view <num> --owner <org> --format json -q '.id'  # project node id, needed for item-edit
```

Field values omitted entirely from an item's JSON (not `null` — the key is
just absent) mean "empty on the board." Check with `has("fieldname")`, not
`.fieldname == null`.

Native sub-issue linkage (the "Parent issue" project column) is a GitHub
issue relationship, not a project field — it doesn't appear in
`item-list` JSON at all. Check/set it via the issue itself:

```bash
gh api graphql -f query='
query($owner:String!, $repo:String!, $number:Int!) {
  repository(owner:$owner, name:$repo) {
    issue(number:$number) { parent { number title } }
  }
}' -f owner=<org> -f repo=<repo> -F number=<n>
```

## What's safe to auto-fix

Only mechanical, textually-evidenced corrections. Everything else gets
reported, not guessed — an empty field is a smaller problem than a wrong one
on a board other people read.

**Layer / stack single-select field** (`Frontend`/`Backend`/`Full-stack`/…) —
safe to set from the issue title's Conventional Commits scope: `fix(backend):
…` → `Backend`, `feat(frontend): …` → `Frontend`. Verified against 200+
already-filled items on a real board: every title with an explicit
`backend`/`frontend` scope has zero contradictions with its Layer value.
Titles with no scope
(most `[epic]` issues) get skipped — Full-stack vs single-layer isn't
decidable from the title alone.

**Sub-issue / parent link** — safe to set only when the issue body contains
an explicit `Epic: #NNNN` or `Part of #NNNN` line naming a real, still-open
issue in the same repo. Confirm the target issue exists first
(`gh issue view <NNNN> --repo <owner>/<repo>`) before linking — a typo'd
number in a body shouldn't become a wrong parent. Set via:

```bash
gh api graphql -f query='
mutation($issueId:ID!, $parentId:ID!) {
  addSubIssue(input:{issueId:$parentId, subIssueId:$issueId}) { subIssue { number } }
}' -f issueId=<child node id> -f parentId=<parent node id>
```

(Node IDs come from `gh issue view <n> --repo <owner>/<repo> --json id -q .id`.)

**Module / component single-select** — safe to set only when the issue
title or the first paragraph of the body names one specific module/feature
that matches exactly one option on the field (e.g. body says "the customers
feature module" and `Customers` is a real option). If it plausibly touches
more than one option, or nothing matches cleanly, skip and report it —
don't pick the closest guess.

## Never auto-set

- **Priority, Size/Estimate, Sprint/Iteration** — pure judgment/estimation
  calls. No textual heuristic reliably predicts these; always report as
  missing, never fill in.
- **A parent/epic link with no explicit textual evidence.** Two issues
  touching the same file or referencing each other (`#1132` mentions
  `#1068`) is a *relation*, not a parent/child relationship — don't promote
  it to one.
- **Reviewers.** A single-assignee repo with no team has nothing to assign —
  empty is correct, not a defect. Only flag if a PR actually has requested
  reviewers that the project item's Reviewers field doesn't reflect.
- Never close/reopen issues, edit titles or bodies, or merge/approve PRs.

## Status vs. real state

Status drift is real but the fix is cross-checking against the linked PR,
not guessing from the issue alone:

```bash
gh pr list --repo <owner>/<repo> --state all --json number,title,state,isDraft,body \
  | jq '.[] | select(.body | test("#<issue-number>"))'
```

- Open, non-draft PR with no review yet → issue Status should read
  `In Review` (or the board's equivalent column).
- Merged PR → `Done`.
- Open draft PR, or commits on a branch with no PR → `In Progress`.
- No PR, no branch activity → leave whatever pre-work column it's already
  in (`Ready`/`Backlog`/`Todo`) alone.

Only change Status when the PR evidence contradicts the current value, and
log the PR number that justified the change.

## Reporting

Every run ends with two lists: what was changed (issue #, field, old → new,
and for status/parent the evidence used), and what was left for a human —
ambiguous Module calls, all Priority/Size gaps, and any cross-referenced-but-
not-parented issue clusters worth turning into a real epic.
