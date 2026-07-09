#!/bin/sh
# PreToolUse(Bash) guard — installed by user request.
# Blocks any `git commit` / `gh pr create|edit|comment|review` / `gh api` (reviews
# & comments) whose message/title/body — inline (-m/--body/--title/-f/-F),
# heredoc, or a referenced file (-F/--file/--body-file/--input) — contains a
# co-author trailer, AI attribution, or a Claude Code PR-review attribution
# (e.g. "Automated cross-PR review by Claude Code, requested by @user").
# Ensures no such mentions reach commits, PRs, or PR reviews in any session.
# Intentionally overrides the default Co-Authored-By trailer.
#
# Degrades safe: anything it can't parse → allow (exit 0). It only ever blocks on
# a positive match in an actual commit/PR/review command.

input=$(cat)

# The bash command the model wants to run.
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)
[ -z "$cmd" ] && exit 0

# Only inspect commands that actually create a commit, a PR, or a PR review/comment.
# (A liberal match here is harmless — we still only block on a forbidden-pattern hit
# below — but scoping avoids touching unrelated commands like `git log` or `grep`.)
if ! printf '%s' "$cmd" | grep -Eq '(git[[:space:]]+(-C[[:space:]]+[^[:space:]]+[[:space:]]+)?commit)|(gh[[:space:]]+pr[[:space:]]+(create|edit|comment|review))|(gh[[:space:]]+api)'; then
  exit 0
fi

# Content to scan: the command itself (covers inline flags + heredoc bodies)...
content=$cmd

# ...plus any file referenced by -F / --file / --body-file / --input
# (git -F, gh --body-file, gh api --input).
files=$(printf '%s' "$cmd" | grep -oE '(--body-file|--input|--file|-F)(=|[[:space:]]+)[^[:space:]]+' | sed -E 's/^(--body-file|--input|--file|-F)(=|[[:space:]]+)//')
for f in $files; do
  f=$(printf '%s' "$f" | sed -E "s/^[\"']//; s/[\"']$//")
  if [ -f "$f" ]; then
    content="$content
$(cat "$f" 2>/dev/null)"
  fi
done

# Forbidden patterns (case-insensitive): any co-author trailer, AI attribution, or
# Claude Code PR-review attribution.
if printf '%s' "$content" | grep -iEq 'co-authored-by:|🤖|generated with claude code|claude\.com/claude-code|automated cross-pr review|review by claude code'; then
  cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Blocked by global policy: this commit/PR/review command contains a co-author trailer or AI attribution (e.g. 'Co-Authored-By:', the robot emoji, 'Generated with Claude Code', a claude.com/claude-code link, or an 'Automated cross-PR review by Claude Code' / 'review by Claude Code' attribution). Commits, PRs, and PR reviews must not include any co-author tags or AI attribution. Re-issue the command with those lines removed from the message/title/body and from any -F/--body-file/--input file."}}
JSON
  exit 0
fi

exit 0
