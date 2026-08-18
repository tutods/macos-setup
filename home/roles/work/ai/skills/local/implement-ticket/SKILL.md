---
name: implement-ticket
description: Take a Jira ticket from key to reviewed draft PR — guard, claim, gather context, hand off to the dev-lifecycle agent, then move the ticket to In Review. Use when the user says "implement MP-1234", "pick up MP-1234", "work on ticket MP-1234", or names a ticket key and asks for it to be built.
---

# Implement Ticket

One ticket key in, a draft PR and an In Review ticket out. The main session
guards the board, claims the ticket and gathers context itself; the
`dev-lifecycle` agent does the build. Load the `acli` skill before any Jira
command — flags and payload shapes live there, don't improvise them.

## Step 1 — Preflight

`acli jira auth status`. Not authenticated → tell the user to run
`acli auth login` and stop.

## Step 2 — Guard

View the ticket (plain output, not `--json`). Check status and assignee
before anything else:

- **In Progress (or any active status) under someone else — hard stop.**
  Report who has it and do nothing.
- Done / In Review / closed — stop and ask; the ticket may already be
  handled.
- Assigned to the user or unassigned, in To Do / backlog → safe to start.

## Step 3 — Claim

Assign the ticket to the user and transition it to In Progress **before**
planning, so nobody double-picks it. If the transition or assignment fails,
stop and report — don't build on an unclaimed ticket.

## Step 4 — Context

- Ticket description and comments (plain output; acceptance criteria often
  hide in comments).
- Sibling tickets in the same epic, for conventions and prior decisions.
- Linked Confluence pages or ADRs, if any.
- Target repo: derive from the ticket's component/project conventions
  (`references/mp-conventions.md` in the acli skill for MP). Ambiguous →
  ask the user, don't guess.

## Step 5 — Hand off to dev-lifecycle

Build a complete brief and spawn the `dev-lifecycle` agent:

- **goal** — the ticket's intent in one paragraph, plus the ticket key
- **acceptance criteria** — from the ticket, verbatim where possible
- **in-scope paths** — from context gathering
- **worktree: yes** · **pr: draft**
- branch name per work convention: `<type>/MP-1234-short-description`

The agent can't ask questions mid-run — if the ticket leaves a real design
decision open, resolve it with the user *before* spawning. If the agent
returns open questions instead of a PR, surface them and stop; leave the
ticket In Progress.

## Step 6 — Close out

On PR success:

1. Transition the ticket to In Review.
2. Comment the PR link on the ticket — write it as markdown, convert with
   `scripts/jira_adf.py comment`, post with `comment create --body-file`.
   No exception for a bare one-line link: a plain `--body` renders the URL
   as dead text, the script's autolinking is what makes it clickable.

## Step 7 — Report

Ticket key, PR URL, transitions made, review cycles/findings from the
dev-lifecycle report, and anything left undone.
