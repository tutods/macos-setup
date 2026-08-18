---
name: babysit-prs
description: One triage pass over the user's open PRs — reruns self-hosted-runner flakes, and for real code failures diagnoses them locally and reports without editing anything. Use when the user asks to rerun failing CI, babysit PRs, watch CI, or check why PRs are red. Designed to be driven by /loop in dynamic mode.
---

# Babysit PRs

One pass. Rerun what a rerun can actually fix, diagnose what it can't, edit nothing.

## Hard guardrails

These are not negotiable — the whole point of the skill is that it can run unattended.

- **No file edits.** Not source, not tests, not config. Diagnosis produces a proposed diff as *text* only.
- **No commit, no push, no `git checkout` in the main working tree.** `/Users/daniel.a.sousa/Developer/frontend` is the user's live checkout (on `dev`) — never touch its working state.
- **Max 2 reruns per PR per head SHA.** These are self-hosted `fe-runner-large` pods, not free GitHub minutes. A "flake" that survives two reruns is not a flake.
- **Own PRs only** (`--author '@me'`).

## Step 1 — Triage

```bash
bash ~/.claude/skills/babysit-prs/triage.sh
```

Takes ~25s, emits one JSON array. Per PR you get `pr`, `sha`, `branch`, `runId`, `status`, `jobs[]` (each with `name`, `id`, `class`, `evidence`) and a `verdict`:

| verdict | meaning | action |
|---|---|---|
| `green` | all checks pass | nothing |
| `running` | a check is still pending | nothing, wait |
| `no-checks` | `pull-request.yml` `paths:` filter skipped the workflow (docs-only PR) | nothing, ever — a rerun cannot create checks that were never queued |
| `rerun` | every failure classified `infra` | rerun, if under the cap |
| `needs-you` | at least one `real`/`unknown` failure | diagnose + report, no rerun |

Never re-derive the classification yourself from raw logs — the script's signals are checked against known causes and the raw logs are ANSI walls of coverage tables that will eat the context window.

## Step 2 — State

State lives at `~/.claude/projects/-Users-daniel-a-sousa-Developer-frontend/ci-triage-state.json`, keyed `"<pr>:<sha>"`:

```json
{ "378:5b22503": { "reruns": 1, "blocked": true, "reported": true } }
```

Create it as `{}` if missing. A key not present means a fresh head SHA — new commit, new code, fresh rerun budget. Old keys for the same PR can be dropped.

## Step 3 — Rerun the flakes

For each PR with `verdict: "rerun"` and `reruns < 2`:

```bash
gh run rerun <runId> -R Mindera-People/frontend --failed
```

Then `reruns += 1`.

At `reruns == 2` with the run still red, reclassify the PR as `needs-you` and report it — two consecutive identical infra failures is a pattern, not luck.

**Mixed runs get no rerun.** When a run has both infra and real failures the run cannot go green until the real failure is fixed, and the user's fix push triggers a fresh full run anyway — rerunning the infra jobs first would burn two 15–25 min heavy runners for information that gets thrown away. Report instead.

## Step 4 — Diagnose what needs a local fix

For each PR with `verdict: "needs-you"` and `reported != true`. Read-only, and cheapest route first:

**Coverage threshold failures** — no test run needed at all. The evidence line names the file and the metric:

```
ERROR: Coverage for branches (75%) does not meet global threshold (80%) for src/.../MinderListItem.tsx
```

Read that file plus its test, and identify which branches are unexercised. Propose the missing test cases as text.

**Test failures** — the evidence line names the spec and the test. Reproduce in a detached worktree so no branch is checked out twice and the user's tree is untouched:

```bash
git -C /Users/daniel.a.sousa/Developer/frontend worktree add --detach \
  /Users/daniel.a.sousa/Developer/frontend/.claude/worktrees/ci-triage <sha>
cd /Users/daniel.a.sousa/Developer/frontend/.claude/worktrees/ci-triage
pnpm install --frozen-lockfile
pnpm exec nx run <nx_project>:test -- <failing test file>
```

`--detach` matters: some PR branches already have their own worktree (`git worktree list`), and git refuses the same branch in two. Run only the failing file, never the whole target. Reuse the `ci-triage` worktree across ticks; `git -C ... worktree remove` it when the loop ends.

Nx project names come from the app/package `package.json` `name` field (e.g. `module_people_allocation` for `apps/allocation`, `@mindera-people/feedback` for the feedback package).

**Typecheck / lint failures** — reproduce with `pnpm exec nx run <project>:typecheck` or `:lint` in the same worktree.

**If the local reproduction passes, the failure was a flake after all.** The classifier is deliberately conservative — it cannot tell a genuine assertion failure from one caused by a starved runner, so it calls both `real`. Local reproduction is what settles it. Seen in the wild: PR 378's `Tests (allocation)` failed on `expect(await screen.findByText('Timesheet was successfully unlocked')).toBeVisible()` — the toast existed but hadn't finished animating in, on a job whose own summary reported `setup 1164.50s`. All 13 tests passed locally in 31s. When this happens: reclassify as `infra`, note the timing evidence, and rerun once (still under the 2-per-SHA cap). Do not propose a code change for a test that passes locally.

**`unknown` class** — say so honestly. Point at the job URL and the last `##[error]` line rather than guessing a cause.

Output per finding: root cause, the file(s) involved, and a proposed diff. **Apply nothing.** Then set `reported: true`.

## Step 5 — Report

One compact table, no preamble:

| PR | job | class | action | next |
|---|---|---|---|---|
| 352 | Tests (administration) | infra | rerun 1/2 | waiting |
| 375 | Package Tests (feedback) | real | diagnosed | 3 uncovered branches in `MinderListItem.tsx` — proposed tests below |

Then the diagnosis details for anything new. Skip PRs already `reported` — don't repeat findings every tick.

## Step 6 — Pace or stop

Pick `delaySeconds` from what is actually in flight, not a fixed guess:

- `Tests (allocation)` or `Tests (administration)` rerunning → **~1500s** (they run 21–24 min)
- only `Quality Scan` (~4 min) or `Static Checks` (2–6 min) pending → **~400s**
- everything blocked on the user → **1800s** heartbeat

Stop the loop (`ScheduleWakeup({stop: true})`) once every PR is `green`, `no-checks`, or `blocked` **and** already reported — there is nothing left that a rerun can change.
