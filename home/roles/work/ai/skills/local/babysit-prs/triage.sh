#!/usr/bin/env bash
# Triage CI failures across the current user's open PRs.
#
# Emits a single compact JSON array on stdout; everything else goes to stderr.
# Each failing job is classified as:
#   infra   - self-hosted runner flake, safe to rerun
#   real    - genuine code failure, a rerun cannot fix it
#   unknown - treated as `real` by callers; never rerun on a guess
set -euo pipefail

# Resolved once: then passed explicitly to every gh call so the script works from
# any cwd - the loop should not care which worktree it happens to be sitting in.
REPO="${CI_TRIAGE_REPO:-$(gh repo view --json nameWithOwner -q .nameWithOwner)}"
PR_LIMIT="${CI_TRIAGE_LIMIT:-50}"

# Aggregate gates only ever fail because another job failed, so they carry no
# classification signal of their own.
SKIP_CHECKS='^(CI Status|PR Report)$'

# Order matters: a killed runner truncates test output in ways that can read as a
# real failure, so infra signals are matched first.
INFRA_PATTERNS=(
  'The operation was canceled'
  'Process completed with exit code (130|137|143)'
  'received a shutdown signal'
  'lost communication with the server'
  'Failed to restore cache'
  'require-cache-hit'
  'Unable to download artifact'
  'Cache service responded with'
)
# Most specific first - the first pattern that hits becomes the reported evidence,
# so `FAIL <path>` (names the test) is tried before the `Failed Tests N` banner.
REAL_PATTERNS=(
  'does not meet global threshold'
  'FAIL .*\.(test|spec)\.[jt]sx?'
  'error TS[0-9]+'
  'QUALITY GATE STATUS: FAILED'
  'Failed Tests [0-9]+'
  'Lint errors found'
)

ESC="$(printf '\033')"

# gh sanitises colour codes to the literal two-character sequence `^[` rather than
# emitting a real ESC byte, so both forms have to go. Done once at fetch time, which
# also lets the classification patterns stay readable.
clean_log() {
  sed -E "s/(${ESC}|\^\[)\[[0-9;]*[a-zA-Z]//g" | tr -d '\r'
}

# Log lines arrive as "<job>\t<step>\t<timestamp> <message>". Keep only the message,
# capped to something that fits on a report line.
trim_evidence() {
  rg -o '[^\t]*$' \
    | sed -E 's/^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:.]+Z[[:space:]]*//' \
    | head -1 \
    | cut -c1-200
}

# first_match <log> <pattern>... -> prints the trimmed matching line, exit 1 if none
first_match() {
  local log="$1" pattern hit
  shift
  for pattern in "$@"; do
    if hit="$(rg -N --max-count 1 -e "$pattern" <<<"$log" 2>/dev/null)"; then
      trim_evidence <<<"$hit"
      return 0
    fi
  done
  return 1
}

# classify <job_id> -> "<class>|<evidence>"
classify() {
  local job_id="$1" detail job_conclusion main_step hit

  if ! detail="$(gh api "repos/${REPO}/actions/jobs/${job_id}" 2>/dev/null)"; then
    printf 'unknown|job lookup failed for %s\n' "$job_id"
    return
  fi

  job_conclusion="$(jq -r '.conclusion // "unknown"' <<<"$detail")"
  if [[ "$job_conclusion" == "cancelled" ]]; then
    printf 'infra|run cancelled before the job finished\n'
    return
  fi

  # Last real step (ignoring the harness Set up / Post / Complete steps) that did
  # not succeed. A `cancelled` step under a `failure` job means the runner pod was
  # killed mid-step - the MP-4164 failure mode, always worth a rerun.
  main_step="$(jq -r '
    [.steps[]
     | select(.name | test("^(Set up job|Complete job|Post )") | not)
     | select(.conclusion != "success" and .conclusion != "skipped")]
    | (last // {conclusion: "none", name: "none"})
    | "\(.conclusion)\t\(.name)"' <<<"$detail")"

  if [[ "${main_step%%$'\t'*}" == "cancelled" ]]; then
    printf 'infra|step "%s" cancelled while job failed (runner killed)\n' "${main_step#*$'\t'}"
    return
  fi

  # Strongest discriminator available without reading a single log line: a job that
  # fails on its own merits still runs its `Post *` cleanup steps to success (they
  # are unconditional). If cleanup was skipped or cancelled, the job was killed from
  # the outside, whatever the last log line happens to say.
  local dead_cleanup
  dead_cleanup="$(jq -r '
    [.steps[] | select(.name | startswith("Post ")) | select(.conclusion != "success")]
    | if length > 0 then (.[0].conclusion) else "" end' <<<"$detail")"
  if [[ -n "$dead_cleanup" ]]; then
    printf 'infra|cleanup steps %s while job failed (job killed, not a code failure)\n' "$dead_cleanup"
    return
  fi

  # Only now touch the log. These are ANSI walls of coverage tables - grep for the
  # decisive line, never carry the whole thing anywhere.
  local log
  log="$(gh run view -R "$REPO" --job "$job_id" --log-failed 2>/dev/null | clean_log || true)"
  if [[ -z "$log" ]]; then
    printf 'unknown|no failure log available (step: %s)\n' "${main_step#*$'\t'}"
    return
  fi

  if hit="$(first_match "$log" "${INFRA_PATTERNS[@]}")"; then
    printf 'infra|%s\n' "$hit"
    return
  fi
  if hit="$(first_match "$log" "${REAL_PATTERNS[@]}")"; then
    printf 'real|%s\n' "$hit"
    return
  fi

  hit="$(first_match "$log" '##\[error\]' || echo 'unrecognised failure')"
  printf 'unknown|%s\n' "$hit"
}

prs="$(gh pr list -R "$REPO" --author '@me' --state open --limit "$PR_LIMIT" \
  --json number,title,headRefName,headRefOid)"

results='[]'

while IFS=$'\t' read -r pr sha branch title; do
  [[ -n "$pr" ]] || continue
  echo "triaging PR #${pr} (${branch})" >&2

  if ! checks="$(gh pr checks "$pr" -R "$REPO" --json name,state,link,bucket 2>/dev/null)"; then
    # No check runs at all - `pull-request.yml` has a `paths:` filter, so a
    # docs-only PR never gets checks and no rerun can create them.
    entry="$(jq -n --argjson pr "$pr" --arg sha "$sha" --arg branch "$branch" \
      --arg title "$title" '{pr:$pr,sha:$sha,branch:$branch,title:$title,status:"no-checks",jobs:[]}')"
    results="$(jq --argjson e "$entry" '. + [$e]' <<<"$results")"
    continue
  fi

  pending="$(jq '[.[] | select(.bucket == "pending")] | length' <<<"$checks")"
  failed="$(jq -c --arg skip "$SKIP_CHECKS" \
    '[.[] | select(.bucket == "fail") | select(.name | test($skip) | not)]' <<<"$checks")"
  failed_count="$(jq 'length' <<<"$failed")"

  if ((pending > 0)); then
    status="running"
  elif ((failed_count > 0)); then
    status="failed"
  else
    status="green"
  fi

  run_id="$(jq -r 'first(.[] | .link | capture("/runs/(?<r>[0-9]+)/") | .r) // ""' <<<"$checks")"

  jobs='[]'
  if [[ "$status" == "failed" ]]; then
    while IFS=$'\t' read -r name link; do
      [[ -n "$name" ]] || continue
      job_id="${link##*/job/}"
      verdict="$(classify "$job_id")"
      jobs="$(jq --arg n "$name" --argjson id "${job_id:-0}" \
        --arg c "${verdict%%|*}" --arg e "${verdict#*|}" \
        '. + [{name:$n,id:$id,class:$c,evidence:$e}]' <<<"$jobs")"
    done < <(jq -r '.[] | [.name, .link] | @tsv' <<<"$failed")
  fi

  entry="$(jq -n --argjson pr "$pr" --arg sha "$sha" --arg branch "$branch" \
    --arg title "$title" --arg status "$status" --arg run "$run_id" --argjson jobs "$jobs" \
    '{pr:$pr,sha:$sha,branch:$branch,title:$title,status:$status,runId:$run,jobs:$jobs}')"
  results="$(jq --argjson e "$entry" '. + [$e]' <<<"$results")"
done < <(jq -r '.[] | [.number, .headRefOid, .headRefName, .title] | @tsv' <<<"$prs")

# Per-PR verdict: all-infra runs are the only ones safe to rerun. A mixed run
# cannot go green anyway, so it waits for the user's fix + push.
jq -c 'map(. + {
  verdict: (
    if .status != "failed" then .status
    elif ([.jobs[].class] | all(. == "infra")) then "rerun"
    else "needs-you" end
  )
})' <<<"$results"
