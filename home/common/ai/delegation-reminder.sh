#!/usr/bin/env bash
# UserPromptSubmit hook: keeps the Delegation Contract in ~/.claude/rules/
# workflow.md alive across long sessions. The rules file alone drifts once the
# context fills, the same reason the caveman and ponytail modes re-announce
# themselves. Stdout is appended to the prompt as context, so keep it short.

set -euo pipefail

cat <<'EOF'
DELEGATION ACTIVE. Main thread orchestrates, it does not read/search/edit inline
unless the work is one known file. 2+ independent units = multiple Agent calls in
ONE message. Recon -> Explore. Multi-file edit -> general-purpose. Diff review ->
code-reviewer. Vault -> vault-search. Pass `model` on every dispatch. Not for
user decisions, commits/PRs, or destructive ops.
EOF

exit 0
