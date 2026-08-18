---
name: review-pr
description: Review an existing pull request and optionally post the findings to GitHub as inline comments, a single review, or per-finding comments. Use when the user says "review this PR", "review PR #123", "post a review on the PR", or when the open-pr skill hands off after creating a PR.
---

# Review Pull Request

Generate a code review of a PR diff and, if the user wants, post it to GitHub. Split out of `open-pr` — that skill hands off here after creating a PR.

## Step 1 — Generate the review

1. Read the PR diff: `gh pr diff <pr-number>`
2. Produce findings: bugs, logic errors, security concerns, missing tests, style issues, improvement suggestions. For each finding capture: `id` (`F1`, `F2`, ...), `title`, `severity` (blocker / major / minor / nit), `file`, `line` (if applicable), `description`, `suggestion` (concrete fix or diff).
3. **Comment hygiene is a blocking review item, not a nit.** Apply the "No explanatory comments in code" rules from the always-on instructions (`~/.claude/rules/workflow.md`): comments that narrate what the code does, narrate the change/fix, restate signatures, or reference other files by line are `major` findings; multi-line comment blocks are automatic findings. The suggestion is always the same — delete the comment (moving the content to the PR body if it's worth keeping at all).

## Step 2 — Post to GitHub?

```
Question: "Post review to GitHub?"
Header: "Post review"
Options:
  - label: "No, just show it"
    description: "Display the review inline — do NOT save to any file"
  - label: "Yes, post to GitHub"
    description: "Submit the review via gh pr review"
```

If "No, just show it" → display the review and stop. **Do not write to any file.**

If "Yes, post to GitHub" → continue.

## Step 3 — Review format

```
Question: "How should the review be posted?"
Header: "Review format"
Options:
  - label: "Inline review with overall comment"
    description: "Line-specific comments on the diff + a summary status comment"
  - label: "Single comment with all findings"
    description: "One review body containing everything"
  - label: "Multiple comments"
    description: "Separate top-level review comment per finding"
```

**No AI attribution in posted comments.** The `block-ai-attribution` hook denies review bodies that credit an AI model — never add "Reviewed by <model>" or similar; posted text carries no model credit.

## Step 4 — Post the review

**Comment format (markdown template):**

```
### Finding F<n>: <title>

<short description of the issue — see Writing style below>

**File:** `<path>` · **Line:** <n> · **Severity:** <blocker|major|minor|nit>

<details>
<summary>Suggestion</summary>

```diff
- <old line>
+ <new line>
```

</details>
```

Notes on the template:
- For **inline review** comments, omit the `File`/`Line` line (it's implicit from the diff position) and keep the body short.
- For **single comment** (all findings), list each finding under its own `###` header inside one body.
- For **multiple comments** (top-level), one comment per finding using the full template.

**Posting commands:**

**Inline review with overall comment** — overall as the review body, one inline comment per finding on the diff line:

```bash
gh api repos/{owner}/{repo}/pulls/<pr-number>/reviews \
  --method POST \
  --field event=COMMENT \
  --field 'body=<overall-comment>' \
  --field 'comments=<json-array>'
```

Each inline comment object: `{ "path": "<file>", "line": <n>, "body": "<comment>" }`.

**Single comment with all findings:**

```bash
gh pr review <pr-number> --comment --body "<review-with-all-findings>"
```

**Multiple comments** — one top-level PR comment per finding, plus optional overall comment:

```bash
gh pr comment <pr-number> --body "<overall-comment>"
gh pr comment <pr-number> --body "<finding-1>"
gh pr comment <pr-number> --body "<finding-2>"
```

Capture the comment ID from the response of each `gh pr comment` / `gh api` call. You'll need it for reactions (Step 5).

## Step 5 — Reactions (optional)

After posting, offer to add the user's **GitHub reaction** (👍 / 👎 / 👀) to each posted comment — this does **not** filter or remove findings.

```
Question: "Add your reaction to each posted comment?"
Header: "Reactions"
Options:
  - label: "Yes, let me react"
    description: "I'll add 👍 / 👎 / 👀 to each comment via the GitHub API"
  - label: "No, skip"
    description: "Post the review without reactions"
```

If "Yes, let me react" → for each posted comment (in order), ask:

```
Question: "Reaction for <comment-label>?"
Header: "Comment reaction"
Options:
  - label: "👍 Agree"
    description: "Add 👍 reaction"
  - label: "👎 Disagree"
    description: "Add 👎 reaction"
  - label: "👀 Not sure"
    description: "Add 👀 reaction"
  - label: "Skip"
    description: "Don't add a reaction to this comment"
```

Add the reaction with:

```bash
gh api repos/{owner}/{repo}/issues/comments/<comment-id>/reactions \
  --method POST \
  --field 'content=+1'    # or "-1" or "eyes"
```

Reaction content values: `+1` (👍), `-1` (👎), `eyes` (👀).

## Writing style for findings

Apply the "Writing for Humans" rules from the always-on instructions (`~/.claude/rules/workflow.md`) — they cover tone, filler openers, and AI-tells. Review-specific additions:

- **Name the problem first, then the fix.** Don't bury the issue in preamble.
- **Severity language:** plain words in prose (`bug`, `breaks`, `leaks`, `racy`, `dead code`, `duplicated`) — corporate severity labels belong only in the `**Severity:**` field.
- **Suggestion diffs:** minimal and realistic. Only show the change, not the surrounding context.

Good finding example:

```markdown
### Finding F1: `fetchUser` drops the error on the floor

If the network call rejects, this swallows it and returns `null` as if the user just doesn't exist. Caller has no way to tell "not found" from "server down" — auth will silently break.

**File:** `src/lib/api.ts` · **Line:** 42 · **Severity:** major
```
