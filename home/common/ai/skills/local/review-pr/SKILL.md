---
name: review-pr
description: Review an existing pull request and optionally post the findings to GitHub as inline comments, a single review, or per-finding comments. Use when the user says "review this PR", "review PR #123", "post a review on the PR", or when the open-pr skill hands off after creating a PR.
---

# Review Pull Request

Generate a code review of a PR diff and, if the user wants, post it to GitHub. Split out of `open-pr`, which names this skill once a PR is open.

## Step 1: Generate the review

1. Read the PR diff: `gh pr diff <pr-number>`
2. Produce findings: bugs, logic errors, security concerns, missing tests, style issues, improvement suggestions. For each finding capture: `id` (`F1`, `F2`, ...), `title`, `severity` (blocker / major / minor / nit), `file`, `line` (if applicable), `description`, `suggestion` (concrete fix or diff).
3. **Comment hygiene is a blocking review item, not a nit.** Violations of the zero-comment rule in `~/.claude/rules/workflow.md` are `major` findings, and the suggestion is always to delete the comment (moving anything worth keeping into the PR body).

## Step 2: Post to GitHub?

Ask **"Post review to GitHub?"** (no, just show it / yes, post it). On no, display the review and stop. **Do not write it to any file.**

## Step 3: Review format

Ask **"How should the review be posted?"** with three options: an inline review with an overall comment (line-specific comments on the diff plus a summary), a single comment containing all findings, or one top-level comment per finding.

**No AI attribution in posted comments.** The `block-ai-attribution` hook denies review bodies that credit an AI model, never add "Reviewed by <model>" or similar; posted text carries no model credit.

## Step 4: Post the review

**Comment format (markdown template):**

```
### Finding F<n>: <title>

<short description of the issue, see Writing style below>

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

**Inline review with overall comment**: overall as the review body, one inline comment per finding on the diff line:

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

**Multiple comments**: one top-level PR comment per finding, plus optional overall comment:

```bash
gh pr comment <pr-number> --body "<overall-comment>"
gh pr comment <pr-number> --body "<finding-1>"
gh pr comment <pr-number> --body "<finding-2>"
```

Capture the comment ID from the response of each `gh pr comment` / `gh api` call. You'll need it for reactions (Step 5).

## Step 5: Reactions (optional)

After posting, ask **"Add your reaction to each posted comment?"** (yes / no).
Reactions are the user's own signal, they never filter or remove findings.

On yes, walk the posted comments in order and ask for each: 👍 Agree, 👎
Disagree, 👀 Not sure, or Skip. Then apply it with:

```bash
gh api repos/{owner}/{repo}/issues/comments/<comment-id>/reactions \
  --method POST \
  --field 'content=+1'    # or "-1" or "eyes"
```

Reaction content values: `+1` (👍), `-1` (👎), `eyes` (👀).

## Writing style for findings

Apply the "Writing for Humans" rules from the always-on instructions (`~/.claude/rules/workflow.md`), they cover tone, filler openers, and AI-tells. Review-specific additions:

- **Name the problem first, then the fix.** Don't bury the issue in preamble.
- **Severity language:** plain words in prose (`bug`, `breaks`, `leaks`, `racy`, `dead code`, `duplicated`), corporate severity labels belong only in the `**Severity:**` field.
- **Suggestion diffs:** minimal and realistic. Only show the change, not the surrounding context.

Good finding example:

```markdown
### Finding F1: `fetchUser` drops the error on the floor

If the network call rejects, this swallows it and returns `null` as if the user just doesn't exist. Caller has no way to tell "not found" from "server down", auth will silently break.

**File:** `src/lib/api.ts` · **Line:** 42 · **Severity:** major
```
