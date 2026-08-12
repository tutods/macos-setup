---
name: open-pr
description: Open a pull request interactively. Handles optional branch creation, commit, push, and PR creation with optional Jira ticket linking. Use when user says "/open-pr", "open a PR", "create a pull request", "submit PR", "commit and push", "commit this", or any commit-related request. When the user asks to commit anything, use this skill instead of running git operations manually — it handles the full flow.
---

# Open Pull Request

Guide the user through committing and opening a pull request, step by step. Use `AskUserQuestion` for all choices where available. On platforms without `AskUserQuestion`, ask each question conversationally and wait for the answer before proceeding.

## Context (auto-loaded at invocation)

- Current branch: !`git branch --show-current`
- Git status: !`git status --short`
- Repo default branch: !`gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name' 2>/dev/null || echo "main"`

---

## Step 0 — Jira Ticket Detection (optional, skip if none found)

Check the current branch name for a ticket pattern: `[A-Z]+-\d+` (e.g. `MP-3813`, `PROJ-456`, `ABC-123`).

If a ticket is found, ask to confirm:

```
Question: "Ticket detected: <TICKET>. Use it in PR title?"
Header: "Ticket"
Options:
  - label: "Yes, use <TICKET>"
    description: "Include the ticket in the PR title"
  - label: "No, skip"
    description: "Don't include a ticket — personal or non-ticketed work"
```

Store the confirmed ticket as `<TICKET>` for use in title generation.

If no ticket pattern is found, skip this step entirely. Do not ask about tickets.

---

## Step 1 — New Branch (optional)

Ask:

```
Question: "Create a new branch?"
Header: "New branch"
Options:
  - label: "No, stay on current"
    description: "Keep working on the current branch"
  - label: "Yes, create branch"
    description: "I'll provide the branch name via Other input"
```

If "Yes, create branch" → use the text input as the branch name, then run:

```bash
git checkout -b <branch-name>
```

---

## Step 2 — Commit

Ask:

```
Question: "Commit your changes?"
Header: "Commit"
Options:
  - label: "Yes, stage all and commit"
    description: "Stage all changes, generate a conventional commit message"
  - label: "No, skip"
    description: "Changes already committed or not needed"
```

If "Yes, stage all and commit":

Ask for extra context:

```
Question: "Any extra context for the commit message?"
Header: "Commit context"
Options:
  - label: "No extra context"
    description: "Agent generates the message from the diff alone"
  - label: "Yes, I'll add context"
    description: "Type extra context via Other input"
```

Then:

1. Read `git diff` (or `git diff --staged` if changes are already staged) to understand the changes
2. Generate a commit message following conventional commits:

   ```
   <type>(<optional-scope>): <imperative summary, ≤72 chars>
   ```

   | Type | When |
   |------|------|
   | `feat` | New user-visible behaviour |
   | `fix` | Bug or regression fix |
   | `refactor` | Same behaviour, restructured internals |
   | `perf` | Performance improvement |
   | `test` | Adding or fixing tests |
   | `chore` | Deps, tooling, config — no production code change |
   | `docs` | Documentation only |
   | `build` | Build system changes (Nix, webpack, Dockerfile) |
   | `ci` | CI/CD pipeline changes |
   | `style` | Formatting, whitespace — no logic change |

   Scope is optional — infer from changed files. Skip if changes span too many areas.

3. Show the generated message to the user for confirmation
4. Run:

```bash
git add .
git commit -m "<generated-message>"
```

---

## Step 3 — Push

After committing, push automatically:

```bash
git push origin <current-branch>
```

If push fails (e.g. upstream has newer commits), report the error — do NOT force-push.

If the branch doesn't exist on the remote yet (first push), use:

```bash
git push -u origin <current-branch>
```

---

## Step 4 — Open Pull Request

Ask:

```
Question: "Open a pull request?"
Header: "Open PR"
Options:
  - label: "Yes, open PR"
    description: "Create the PR on GitHub"
  - label: "No, done"
    description: "Stop here — committed and pushed, no PR needed"
```

If "No, done" → stop.

If "Yes, open PR" → ask these questions in a single batch:

**Question 1 — Base branch:**

Use the repo's default branch from `gh repo view` (already fetched in Context) as the first suggested option.

```
Question: "Base branch?"
Header: "Base branch"
Options:
  - label: "<default-branch> (repo default)"
    description: "Target the repo's default branch"
  - label: "dev"
    description: "Target the dev integration branch"
  - label: "development"
    description: "Target the development integration branch"
  - label: "main"
    description: "Target the main production branch"
  - label: "master"
    description: "Target the master branch"
```

User can type a custom branch via Other. These five options cover virtually every repo.

**Question 2 — Title:**

Generate a preview title and ask for confirmation. If a `<TICKET>` was confirmed in Step 0, include it:

```
Question: "PR title?"
Header: "PR title"
Options:
  - label: "<generated-title>"
    description: "Agent-generated title, conventional commits style"
  - label: "Write my own"
    description: "Type a custom title via Other input"
```

To generate the title:
- Read `git diff HEAD...origin/<base>` to understand the full branch diff
- Pick a short imperative summary (≤60 chars)
- Title format (pick based on context):
  - **With ticket**: `type(<TICKET>): summary` (e.g. `feat(MP-3813): add communications hub`)
  - **Without ticket**: `type(scope): summary` (e.g. `feat(skills): add open-pr skill`)

**Question 3 — Reviewers (optional):**

```
Question: "Request reviewers?"
Header: "Reviewers"
Options:
  - label: "No reviewers"
    description: "Skip — assign only"
  - label: "Specify reviewers"
    description: "Type GitHub usernames or team slugs via Other input"
```

**Question 4 — Assignees:**

```
Question: "Assignees?"
Header: "Assignees"
Options:
  - label: "Just me"
    description: "Assign to the authenticated GitHub user"
  - label: "Other"
    description: "Type GitHub username(s) via Other input"
```

---

## Step 5 — PR Body

Ask:

```
Question: "Any extra context for the PR body?"
Header: "PR context"
Options:
  - label: "No extra context"
    description: "Agent generates body from diff alone"
  - label: "Yes, I'll add context"
    description: "Type extra context via Other input"
```

Then generate the body:

- Write 1-2 sentences summarizing the diff + any extra context provided
- If the repo has `.github/pull_request_template.md`, read it, fill in each section, and use it as the body template. Preserve all emoji headers, table structure, and markdown formatting from the original file.
- If no template exists, use the plain summary as the body

---

## Step 6 — Create the PR

Get the authenticated GitHub username:

```bash
gh api user --jq '.login'
```

If assignee was "Just me", use the result above. Otherwise use the Other text input.

Build the command:

```bash
gh pr create \
  --base <base-branch> \
  --title "<title>" \
  --body "<filled-body>" \
  --assignee <github-login>
```

If reviewers were specified in Step 4, append:

```
  --reviewer "<reviewer1,reviewer2>"
```

After the PR is created, output the URL:

```
**Pull request opened:**
[View PR #<number> on GitHub](<url>)

<url>
```

---

## Step 7 — Review the Pull Request

After the PR is created, ask:

```
Question: "Review the pull request?"
Header: "Review PR"
Options:
  - label: "Yes, review it"
    description: "Generate a code review of the PR diff"
  - label: "No, done"
    description: "Stop here — PR is open, no review needed"
```

If "No, done" → stop.

If "Yes, review it" → continue.

### 7a — Generate the review

1. Read the PR diff: `gh pr diff <pr-number>`
2. Produce findings: bugs, logic errors, security concerns, missing tests, style issues, improvement suggestions. For each finding capture: `id` (`F1`, `F2`, ...), `title`, `severity` (blocker / major / minor / nit), `file`, `line` (if applicable), `description`, `suggestion` (concrete fix or diff).

### 7b — Post to GitHub?

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

### 7c — Review format

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

### 7d — Attribution

```
Question: "Add attribution to each comment?"
Header: "Attribution"
Options:
  - label: "Yes, add attribution"
    description: "Prepend '> Reviewed by <AI model>' blockquote at the beginning of each comment"
  - label: "No attribution"
    description: "Skip — no model credit"
```

If "Yes" → prepend the blockquote at the **beginning** of every comment (overall, each inline, each top-level). Use the model name that is currently running the session.

### 7e — Add your reactions to each comment

After posting the review, ask the user to react to each comment. This adds a **GitHub reaction** (👍 / 👎 / 👀) on the corresponding comment using the Reactions API — it does **not** filter or remove findings.

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

Store the comment ID returned from posting. Add the reaction with:

```bash
gh api repos/{owner}/{repo}/issues/comments/<comment-id>/reactions \
  --method POST \
  --field 'content=+1'    # or "-1" or "eyes"
```

Reaction content values: `+1` (👍), `-1` (👎), `eyes` (👀).

### 7f — Post the review

**Comment format (markdown template):**

```
> Reviewed by <AI model>

### Finding F<n>: <title>

<short humanized description of the issue — see 7g for style rules>

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
gh pr comment <pr-number> --body "<overall-comment>"   # if attribution requested
gh pr comment <pr-number> --body "<finding-1>"
gh pr comment <pr-number> --body "<finding-2>"
```

Capture the comment ID from the response of each `gh pr comment` / `gh api` call. You'll need it for step 7e (reactions).

### 7g — Writing style for findings (humanized, not AI)

All review text must read like a teammate wrote it — not an AI. Apply these rules when writing each finding:

- **Tone:** direct, specific, conversational. Talk like a colleague leaving a code review over coffee.
- **No filler openers.** Never start a finding with "I'd suggest", "It would be better to", "Consider", "One thing to note", "Furthermore", "Additionally", "It is worth noting", or any hedge.
- **Short sentences, varied rhythm.** Mix one-word lines ("Won't work.") with longer explanations. Break up symmetry.
- **Name the problem first, then the fix.** Don't bury the issue in preamble.
- **Concrete over abstract.** Quote the actual line, name the actual function, reference the actual file path. No generic platitudes.
- **No meta-structure.** Don't say "Let me explain", "Here's why", "This demonstrates". Just say it.
- **No AI self-reference.** Never write "as an AI", "based on my training", "I'm a language model".
- **One-pass feel.** Mild asymmetry is fine — contractions, fragments, a personal aside. Don't over-polish.
- **Severity language:** use plain words (`bug`, `breaks`, `leaks`, `racy`, `dead code`, `duplicated`) — not corporate severity labels in prose.
- **Suggestion diffs:** keep them minimal and realistic. Only show the change, not the surrounding context.

Good finding example:

```markdown
> Reviewed by Claude Sonnet 5

### Finding F1: `fetchUser` drops the error on the floor

If the network call rejects, this swallows it and returns `null` as if the user just doesn't exist. Caller has no way to tell "not found" from "server down" — auth will silently break.

**File:** `src/lib/api.ts` · **Line:** 42 · **Severity:** major

<details>
<summary>Suggestion</summary>

```diff
- } catch {
-   return null;
- }
+ } catch (err) {
+   throw err;
+ }
```

</details>
```

Bad finding example (AI-tell, do not write this):

> As an AI reviewing this code, I would suggest that the error handling could potentially be improved. Furthermore, it is worth noting that the function in question appears to drop errors. Consider refactoring this to provide better error propagation. This demonstrates how defensive coding practices can enhance the overall robustness of the application.
