---
name: open-pr
description: Open a pull request interactively. Handles optional branch creation, commit, push, and PR creation with optional Jira ticket linking. Use when user says "/open-pr", "open a PR", "create a pull request", "submit PR", "commit and push", "commit this", or any commit-related request. When the user asks to commit anything, use this skill instead of running git operations manually, it handles the full flow.
---

# Open Pull Request

Two question screens, not seven. Everything the user decides is asked in two `AskUserQuestion` batches, and everything that can be inferred is inferred.

`AskUserQuestion` takes at most 4 questions per call, so the batches below are full. Do not add a fifth question to either one. On a platform without `AskUserQuestion`, ask each item conversationally in the same order.

## Step 1: Preconditions

```bash
git rev-parse --abbrev-ref HEAD
git status --short
git log --oneline @{upstream}..HEAD 2>/dev/null || echo "no upstream"
gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name' 2>/dev/null || echo "main"
git branch -r --format='%(refname:short)'
```

If the tree is clean **and** nothing is unpushed, say so and stop. There is nothing to commit, push, or open. Do not ask any questions first.

## Step 2: Batch one

One `AskUserQuestion` call, four questions:

| Header | Question | Options |
|---|---|---|
| `Branch` | Create a new branch? | Stay on `<current>` / Create one (name via Other) |
| `Commit` | Commit your changes? | Yes / No, already committed |
| `Push` | Push when done? | Yes / No, keep it local |
| `Open PR` | Open a pull request? | No / Yes, ready for review / Yes, as draft |

Notes on the options:

- **Push** is asked here because it is the step that puts code where other people see it. It used to happen with no confirmation at all.
- **Open PR** carries the draft choice, which is why it has three options rather than two. `implement-ticket` wants a draft PR and can call this skill directly because of it.
- Answer `No` to all of Commit, Push and Open PR and there is nothing to do. Say so and stop.

## Step 3: Do the work

In this order, because each step depends on the one before.

1. **Create the branch** if asked, with `git checkout -b <name>`.
2. **Detect the ticket.** Match `[A-Z]+-\d+` against the branch name *now*, after any branch creation, because the new branch is usually the one carrying the key (`feat/MP-1234-thing`). Store it as `<TICKET>`. Never ask about it; the user confirms it when they approve the title in batch two.
3. **Read the diff**: `git diff`, or `git diff --staged` when changes are already staged.
4. **Comment audit.** Find comment lines the diff adds:

```bash
git diff -U0 | rg '^\+\s*(//|#|/\*|\*|--|<!--|""")'
```

   Also check for `'''` docstrings in Python. Delete every hit that breaks the zero-comment rule in `~/.claude/rules/workflow.md`, **before** staging, and move anything worth keeping into the commit message or the PR body. Skip the false positives: shebangs, string literals, nix attribute paths, YAML document separators, and comments that only appear in the diff because a neighbouring line changed. When unsure, delete.
5. **Generate the commit message** with the `conventional-commit` skill.
6. **Generate the PR title** from `git diff HEAD...origin/<default-branch>`: a short imperative summary, 60 characters or fewer. Format it `type(<TICKET>): summary` when a ticket was found, otherwise `type(scope): summary`.

## Step 4: Batch two

Skip this whole step when Open PR was `No`. Ask only the commit message question, confirm it, then commit and stop.

One `AskUserQuestion` call, four questions. Use the `preview` field to show the generated text in the side panel, so the user reads the real thing instead of a label:

| Header | Question | Options |
|---|---|---|
| `Message` | Use this commit message? | The generated message (as `preview`) / Write my own |
| `Base branch` | Base branch? | Repo default first, then whichever of `dev`, `develop`, `development`, `main`, `master`, `staging` actually exist in `git branch -r` |
| `PR title` | PR title? | The generated title (as `preview`) / Write my own |
| `Reviewers` | Request reviewers? | None / usernames or team slugs via Other |

Two rules for the base-branch options: list only branches that exist on the remote, and never pad the list to four with guesses. Two real options beat four where three are wrong.

`preview` works on single-select questions only, which all four of these are.

## Step 5: Commit, push, create

Assignee is always the authenticated user, `gh api user --jq '.login'`. It is not worth a question.

```bash
git add -- <file1> <file2> ...
git commit -m "<message>"
git push -u origin <current-branch>
gh pr create \
  --base <base-branch> \
  --title "<title>" \
  --body "<body>" \
  --assignee <github-login>
```

- Stage by explicit pathspec, **never** `git add .` or `-A`, which sweeps up unrelated work. If `git status --short` showed something unexpected already staged, ask before including it.
- Drop `git push` entirely when Push was `No`, and skip `gh pr create` with it, since a PR needs a pushed branch.
- Add `--draft` when Open PR was `Yes, as draft`.
- Add `--reviewer "<r1,r2>"` when reviewers were named.
- If the push fails because upstream moved, report it and stop. Never force-push.

**PR body**: 1 or 2 sentences summarising the diff. When the repo has `.github/pull_request_template.md`, fill it in section by section and keep its emoji headers, tables and formatting exactly.

## Step 6: Report

Print the PR URL:

```
**Pull request opened:**
[View PR #<number> on GitHub](<url>)

<url>
```

Then say the review is available on request, naming the `review-pr` skill. Do not ask. The user just watched the PR appear and can decide without a prompt.
