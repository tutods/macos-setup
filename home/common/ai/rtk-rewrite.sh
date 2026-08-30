#!/usr/bin/env bash
# PreToolUse (Bash): transparently rewrite commands through rtk
# (github.com/rtk-ai/rtk) so filtered, token-cheap output reaches the model.
# All rewrite logic lives in the rtk binary (`rtk hook claude` reads the hook
# JSON on stdin and answers with updatedInput); this wrapper only finds the
# binary and stays silent when it is absent, so a machine without rtk loses
# the savings, never the session.
set -uo pipefail

RTK=$(command -v rtk 2>/dev/null || true)
[ -x "$RTK" ] || RTK=/opt/homebrew/bin/rtk
[ -x "$RTK" ] || exit 0

exec "$RTK" hook claude
