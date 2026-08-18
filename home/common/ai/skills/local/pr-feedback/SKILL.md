---
name: pr-feedback
description: Triage incoming review comments on the user's own pull request — every comment gets a substantiated disposition (implement, answer, push back, escalate, or nothing) before anything changes. Use when the user says "address the review comments", "respond to the feedback on PR #123", "handle the PR review", or asks what to do about reviewer comments.
---

# PR Feedback

Review comments are input, not orders. Each one gets a disposition backed by
the diff, the ticket, and the repo's conventions — never accepted on reviewer
authority alone, and never a blind fix-everything pass.

## Step 1 — Gather

- Every review thread and comment: `gh api repos/{owner}/{repo}/pulls/<n>/comments`
  and `.../reviews` (REST, not GraphQL-backed `--json` flags — GraphQL 503s
  often enough to break a pass).
- The current PR diff and the commits since each comment was left — a comment
  may already be addressed.
- The linked ticket/issue and CI status.
- The repo's convention docs (`CLAUDE.md`, contributing guides) — a comment
  that contradicts a written convention gets pushed back with the citation.

## Step 2 — Disposition per comment

Exactly one each:

| Disposition | When |
|---|---|
| `implement` | The comment is right — verified against the code, not assumed |
| `answer` | The code is right but unclear — reply explains, no change |
| `push back` | The comment conflicts with the ticket scope, a repo convention, or the actual behavior — reply cites the evidence |
| `escalate` | A real design disagreement the user must settle |
| `nothing` | Already resolved by a later commit, or the thread is outdated |

Substantiate every disposition with `file:line` or a doc citation read this
session. If a comment reveals the reviewer misread something you also can't
follow, that's a sign the code needs clarity — lean `implement`, not `answer`.

## Step 3 — Confirm

Show the disposition table (comment → disposition → one-line why) via
`AskUserQuestion` before acting. The user can flip any row. `escalate` rows
are only presented — never resolved autonomously.

## Step 4 — Act

- `implement` fixes go through the standard commit path (`open-pr` skill,
  comment audit included), grouped into focused commits. **Append only —
  never force-push a branch with review history.**
- Replies are lean: name the change or the reasoning in a sentence or two,
  link the fixing commit for implemented ones. No AI attribution (the
  `block-ai-attribution` hook rejects it anyway).
- Reply on the thread (`gh api .../pulls/<n>/comments/<id>/replies`), don't
  open new top-level comments for existing threads.

## Step 5 — Report

One table: comment → disposition → action taken (commit SHA, reply link, or
open question). Anything escalated is restated plainly at the end.
