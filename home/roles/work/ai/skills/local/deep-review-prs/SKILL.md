---
name: deep-review-prs
description: One deep-review pass over the user's open non-draft PRs in a target repo (Mindera-People/frontend or Mindera-People/workspace), multi-agent review per new head SHA, confirmed findings posted to GitHub as an inline review with fix suggestions, reason, and the reviewing model. Use when the user asks to "deep review my PRs", "review my open PRs", or starts a review loop. Designed to be driven by /loop in dynamic mode.
---

# Deep-review PRs

One pass. Review what hasn't been reviewed at its current head SHA, post one inline review per PR, touch nothing else.

## Target repo

The skill argument names the repo. Bare `/deep-review-prs` or `frontend` → frontend; `workspace` → workspace. `both` → run the whole pass for frontend, then for workspace. Every `<repo>` below is the row's full name.

| Arg | `<repo>` | Base | Live checkout | Conventions the reviewer must read |
|---|---|---|---|---|
| `frontend` (default) | `Mindera-People/frontend` | `dev` | `~/Developer/frontend` | `CLAUDE.md`, `.claude/rules/`, `.claude/lessons.md` |
| `workspace` | `Mindera-People/workspace` | `main` | `~/Developer/workspace` | `CONTRIBUTING.md`, `documentation/*.md`, `.cursor/rules/*.mdc` |

Workspace notes that change the review:
- Don't cite frontend's `CLAUDE.md` rules as binding here, check whether workspace has one of its own, and otherwise cite `CONTRIBUTING.md` and `documentation/`.
- It ships the shared libraries frontend consumes (`packages/components`, `design-tokens`, `shared`, `biome-config`, `tsconfig`, `dynamic-federation`, `react-webix-jet`, `nest-utils`) plus `apps/storybook`. A breaking change to a published package's public API is a blocker-severity finding, downstream repos pin it.
- **Stacked PRs are normal here** (a PR whose `base.ref` isn't `main`). `gh pr diff <n>` already diffs against its own base, so use it as-is and never flag content that came in from the parent branch. Check `base.ref` before reviewing and say so in the review body.

## Hard guardrails

Non-negotiable, this runs unattended.

- **Own PRs only**: resolve the login once with `gh api user --jq '.login'` and match on it; one target repo per pass, drafts skipped.
- **No file edits, no commits, no `git checkout` in any live checkout.** Both `~/Developer/frontend` and `~/Developer/workspace` are the user's working trees.
- **One review per `<pr>:<sha>`.** Never post twice for the same head SHA. A new push (new SHA) gets a fresh review of the new diff.
- Review event is always `COMMENT`, never `APPROVE`, never `REQUEST_CHANGES`.
- Max 15 inline comments per review, most severe first; overflow goes into the review body as a list.
- Posted text must not contain the phrases the `block-ai-attribution` hook rejects: no robot emoji, no "review by Claude Code", no "generated with Claude Code", no co-author trailers, no claude.com/claude-code links. The model id footer (`_Model: <id>_`) is required and passes the hook, keep it exactly in that form.

## Step 1: Enumerate

Use the REST endpoint, not `gh pr list`. Anything `--json`-flavoured goes through GitHub's GraphQL API, which returns `HTTP 503: No server is currently available` often enough to break an unattended tick (hit four times in one session); REST stayed up throughout.

```bash
me=$(gh api user --jq '.login')
gh api "repos/<repo>/pulls?state=open&per_page=100" --paginate \
  --jq --arg me "$me" '.[] | select(.draft == false and .user.login == $me)
        | "\(.number):\(.head.sha) base=\(.base.ref)"'
```

Same substitution elsewhere: `gh api repos/<repo>/pulls/<n>` gives `mergeable` and `mergeable_state`, and `gh api repos/<repo>/pulls/<n>/commits` gives the commit list.

## Step 2: State

One state file per repo, both under the frontend project dir so a single loop session owns them:

| `<repo>` | State file |
|---|---|
| `Mindera-People/frontend` | `~/.claude/projects/-Users-daniel-a-sousa-Developer-frontend/deep-review-prs-state.json` |
| `Mindera-People/workspace` | `~/.claude/projects/-Users-daniel-a-sousa-Developer-frontend/deep-review-prs-state-workspace.json` |

Keyed `"<pr>:<sha>"`:

```json
{ "441:a1b2c3d": { "reviewed": true, "findings": 4 } }
```

Create as `{}` if missing. Key present → skip that PR this tick. Key absent → new head SHA → review it. Drop stale keys for the same PR number once a newer SHA is recorded, and drop a PR's keys entirely once it merges or closes.

**A `declined` map is binding.** When a commit reverts a fix you suggested, or the author says no, add the finding to `declined[<pr>]` with the stated reason and never raise it again on that PR, not on a new SHA, not from a different dimension, not because a sibling line in the same file does it the other way. Re-litigating a settled decision is the failure mode this map exists to prevent, so pass the PR's declined list into every reviewer subagent's prompt as explicit do-not-report instructions. A revert whose message gives a rationale ("team decision", "not applicable here") is a settled decision, not a regression to flag.

## Step 3: Deep review (per unreviewed PR)

**First: full review or delta review?** If state holds an older SHA for this PR, the new head is usually a fix commit answering the last review. Don't re-run four dimensions over the whole diff, review the delta:

```bash
gh api "repos/<repo>/pulls/<n>/commits" \
  --jq '.[] | "\(.sha[0:7]) \(.commit.message | split("\n")[0])"'
gh api repos/<repo>/commits/<new-sha> --jq '.files[] | .filename, .patch'
```

Use the PR's commit list, not `compare/<old>...<new>`, a force-push/rebase makes the old SHA unreachable and `compare` 404s.

**A `Merge branch '<base>'` head is not new work.** These branches merge the base forward often (one PR had six such merges). `gh api .../commits/<sha>` on a merge shows the diff against its first parent, that is the base's incoming content, authored by other people, not this PR. Confirm with `gh pr diff <n> --name-only`: if the PR's own file set is unchanged from the last review, record the new SHA and skip. Only re-review when the merge brought dev changes into files this PR also touches (real conflict-resolution risk). Verify each fix actually resolves the finding it claims (including whether a rename left stragglers), and check for residual gaps in the lines the fix touched. Post only new findings; the resolved ones need no comment. Fall back to a full review when the delta is substantive new feature work rather than fixes.

1. Context: `gh pr diff <n> -R <repo>` and `gh api repos/<repo>/pulls/<n> --jq '{title, body, base: .base.ref}'` (REST, not `gh pr view --json`, see Step 1).
2. **Fan out reviewer subagents in parallel** (Agent tool, one message per PR, 3-4 agents, not every PR's agents at once; a 16-agent batch is a single interruptible unit and loses all of its work if cancelled), `run_in_background: false`, each given the full diff, the PR title/body, and told to return findings as a JSON list of `{file, line, severity, title, reason, fix, fixIsExactReplacement}`, `line` must be a line on the **new** (RIGHT) side of the diff, `severity` one of blocker/major/minor/nit, `fix` the concrete replacement code or diff. Dimensions:
   - **Correctness/bugs**: general-purpose: logic errors, edge cases, race conditions, broken behavior. The agent needs a Bash tool to fetch the diff from a private repo, so don't substitute an agent type that lacks one.
   - **Repo conventions**: general-purpose: the agent reads the target repo's own convention docs (the table at the top of this file lists them per repo) and checks the diff against those. For workspace, add public-API stability of the published packages, that isn't written down in its docs.
   - **Tests**: general-purpose: missing/weak behavioral coverage for the changed code, violations of `.claude/rules/testing.md` (vi.mock of internals, hardcoded IDs, snapshot tests, missing MSW handlers).
   - **Security & error handling**: general-purpose: injection, authz gaps, swallowed errors, unsafe payload construction (raw Webix rows), 204-body traps.
   - **Comment hygiene**: fold into the conventions agent's prompt, not a fifth agent: apply "No explanatory comments in code" from `~/.claude/rules/workflow.md` to *added* comment lines only. Comments narrating what the code does, narrating the change/fix, restating signatures, or referencing files by line are `major`; multi-line comment blocks are automatic findings; the fix is always deletion (move the content to the PR body if it's worth keeping).
3. **Dedupe** by `file:line` across dimensions (keep the highest severity, merge reasons).
4. **Verify pass:** fan out one adversarial verifier per surviving finding (general-purpose, parallel, cheap model tier is fine, `model: haiku` for simple ones), prompted to **refute** the finding against the actual diff and surrounding source; uncertain → refuted. Only confirmed findings survive.
5. **Anchor check (main thread):** for each confirmed finding, confirm `file` + `line` appear in the diff's RIGHT-side hunks. Non-anchorable findings move to the review body instead of inline comments.

Zero confirmed findings → post nothing (a "looks good" review every tick is noise); record state and move on.

## Step 4: Post one inline review

Build the comments array and post a single review:

```bash
gh api repos/<repo>/pulls/<n>/reviews --method POST --input /path/to/review.json
```

`review.json` (write it in the session scratchpad, not the repo):

```json
{
  "event": "COMMENT",
  "body": "<summary: 1-3 sentences on overall shape, then any non-anchorable/overflow findings, then the model footer>",
  "comments": [
    { "path": "apps/x/src/y.tsx", "line": 42, "side": "RIGHT", "body": "<comment>" }
  ]
}
```

Inline comment body template:

```markdown
**<severity>: <one-line problem>**

<reason, why this breaks or matters, 1-3 sentences, plain words>

```suggestion
<exact replacement for the commented line(s)>
```

_Model: <your model id>_
```

- Use a ` ```suggestion ` block only when `fixIsExactReplacement`, the block replaces exactly the commented line(s) on one click, so the content must be the full new line(s), correct indentation, nothing else. Otherwise use a ` ```diff ` block.
- Multi-line replacements: add `"start_line": <first>, "start_side": "RIGHT"` to the comment object and suggest the whole range.
- The model footer carries the **actual model id you are running as**, read from your own system prompt, never a hardcoded one. Same footer once at the end of the review body.
- **422 fallback:** if the API rejects the array (a line not in the diff), drop the offending comment(s) into the review body as `**path:line**, <comment>` and re-post once. Never loop on 422s.

## Step 5: Record + report

Mark `"<pr>:<sha>": { "reviewed": true, "findings": <n> }` in that repo's state file, **after each PR, not once at the end.** A pass over many PRs can be interrupted; state written incrementally means the next tick resumes instead of re-reviewing.

Report one compact table, no preamble, naming the repo:

| PR | sha | result |
|---|---|---|
| 441 | a1b2c3d | 4 findings posted (1 major, 3 minor) |
| 438 | 9f8e7d6 | already reviewed, skipped |
| 445 |, | draft, skipped |

## Step 6: Pace (for /loop dynamic mode)

- Reviewed something this tick, or a PR is mid-review → `ScheduleWakeup` ~900s, `noop: false`.
- Nothing new (every open PR's `<pr>:<sha>` already in state) → ~1800s heartbeat, `noop: true`.
- Never self-stop, new pushes and new PRs can always arrive; the user stops the loop.
