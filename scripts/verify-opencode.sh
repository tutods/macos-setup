#!/usr/bin/env bash
# opencode setup verification: checks the deployed opencode state against what
# the flake declares, so a broken deploy surfaces as a failed check instead of
# a silently degraded session. Backs the /verify-setup opencode command.
#
# Checks (macbook / personal machine only):
#   1. binary + toolchain: opencode, rtk, code-review-graph on PATH/known path
#   2. opencode.json parses, MCP servers enabled, code-review-graph present
#   3. auth.json has the ollama-cloud provider entry
#   4. managed agents + commands deployed where the flake declares them
#   5. plugin bridge: ~/.claude/plugins skill dirs symlinked into
#      ~/.config/opencode/skills, no dangling links, no clobbered real dirs
#   6. opencode log: no plugin load errors, no duplicate-skill warnings
#
# Exit 1 on any failure, 0 when clean (warnings don't fail). Deps: jq, git.
# Read-only: prints, never fixes.
set -uo pipefail

home="${HOME}"
ocDir="$home/.config/opencode"
claudePlugins="$home/.claude/plugins"
logDir="$home/.local/share/opencode/log"
fail=0
warn() { printf '  warn: %s\n' "$1"; }
fail_() { printf '  FAIL: %s\n' "$1"; fail=1; }
ok() { printf '  ok: %s\n' "$1"; }

section() { printf '\n== %s ==\n' "$1"; }

section "binaries"
if command -v opencode >/dev/null 2>&1; then
  ok "opencode $(opencode --version 2>/dev/null || echo 'version unknown')"
else
  fail_ "opencode not on PATH"
fi
if command -v rtk >/dev/null 2>&1; then
  ok "rtk $(rtk --version 2>/dev/null | head -1)"
else
  fail_ "rtk not on PATH (rtk-rewrite and opencode-parity both degrade silently)"
fi
crg="$home/.local/bin/code-review-graph"
if [ -x "$crg" ] && "$crg" --version >/dev/null 2>&1; then
  ok "code-review-graph $("$crg" --version 2>/dev/null)"
else
  fail_ "code-review-graph missing or broken at $crg"
fi

section "opencode.json"
cfg="$ocDir/opencode.json"
if [ ! -f "$cfg" ]; then
  fail_ "$cfg missing"
elif jq -e . "$cfg" >/dev/null 2>&1; then
  ok "valid JSON"
  for server in filesystem github playwright postgres shadcn code-review-graph; do
    if jq -e --arg s "$server" '.mcp[$s].enabled == true' "$cfg" >/dev/null 2>&1; then
      ok "mcp.$server enabled"
    else
      fail_ "mcp.$server missing or disabled"
    fi
  done
  if jq -e '.subagent_depth == 2' "$cfg" >/dev/null 2>&1; then
    ok "subagent_depth = 2"
  else
    warn "subagent_depth != 2 (expected from config.nix)"
  fi
  if jq -e '.lsp == true' "$cfg" >/dev/null 2>&1; then
    ok "lsp enabled"
  else
    warn "lsp not enabled"
  fi
else
  fail_ "$cfg is not valid JSON"
fi

section "provider auth"
if jq -e 'has("ollama-cloud")' "$home/.local/share/opencode/auth.json" >/dev/null 2>&1; then
  ok "ollama-cloud entry present in auth.json"
else
  fail_ "ollama-cloud missing from auth.json (run opencode and /connect, every model call fails otherwise)"
fi

section "managed files"
expectedAgents="orchestrator code-reviewer dev-lifecycle vault-lint vault-search nix-architect"
for agent in $expectedAgents; do
  if [ -f "$ocDir/agents/$agent.md" ]; then
    ok "agents/$agent.md"
  else
    fail_ "agents/$agent.md missing"
  fi
done
expectedCommands="council deploy doctor nixcheck verify-setup"
for cmd in $expectedCommands; do
  if [ -f "$ocDir/commands/$cmd.md" ]; then
    ok "commands/$cmd.md"
  else
    fail_ "commands/$cmd.md missing"
  fi
done
if [ -f "$ocDir/plugins/opencode-parity.js" ]; then
  ok "plugins/opencode-parity.js"
else
  fail_ "plugins/opencode-parity.js missing"
fi
if [ -f "$ocDir/AGENTS.md" ]; then
  ok "AGENTS.md generated"
else
  fail_ "AGENTS.md missing"
fi

section "plugin bridge (claude plugins -> opencode skills)"
skillsDir="$ocDir/skills"
if [ -d "$claudePlugins/cache" ]; then
  # Same walk the activation script does: any skills/ dir under the plugin
  # cache, one symlink per skill dir inside it. Names repeat across plugins
  # (frontend-design ships in three of them), so report per unique name.
  bridged=0
  dangling=0
  unbridged=""
  seen=" "
  for skillsSrc in $(find "$claudePlugins/cache" -type d -name skills 2>/dev/null); do
    for skill in "$skillsSrc"/*; do
      [ -d "$skill" ] || continue
      name="$(basename "$skill")"
      case "$seen" in *" $name "*) continue ;; esac
      seen="$seen$name "
      target="$skillsDir/$name"
      if [ -L "$target" ]; then
        if [ -e "$target" ]; then
          bridged=$((bridged + 1))
        else
          dangling=$((dangling + 1))
          fail_ "dangling bridge symlink: $target -> $(readlink "$target")"
        fi
      elif [ -e "$target" ]; then
        warn "$target is a real dir, not a bridge symlink (tool-installed or stale)"
      else
        unbridged="$unbridged $name"
      fi
    done
  done
  ok "$bridged bridge symlink(s) resolve"
  if [ -n "$(echo "$unbridged" | tr -d ' ')" ]; then
    count=$(printf '%s' "$unbridged" | wc -w | tr -d ' ')
    first5=$(printf '%s' "$unbridged" | awk '{print $1, $2, $3, $4, $5}')
    warn "$count plugin skill(s) not bridged yet (deploy to link), first 5:$first5"
  fi
else
  warn "no $claudePlugins/cache; nothing to bridge"
fi

section "opencode log"
logFile="$(ls -t "$logDir"/opencode.log 2>/dev/null | head -1 || true)"
if [ -n "$logFile" ] && [ -f "$logFile" ]; then
  # Only count warnings from this deploy onwards: the log is append-only
  # history, and pre-deploy entries describe the old config, not this one.
  deployTs="$(stat -f '%Sm' -t '%Y-%m-%dT%H:%M:%S' "$cfg" 2>/dev/null || true)"
  recent() {
    if [ -n "$deployTs" ]; then
      grep "$1" "$logFile" 2>/dev/null | while IFS= read -r line; do
        ts=${line#*timestamp=}; ts=${ts%%.*}
        [ -n "$ts" ] && [ "$ts" \< "$deployTs" ] && continue
        printf '%s\n' "$line"
      done
    else
      grep "$1" "$logFile" 2>/dev/null
    fi
  }
  dupes=$(recent "duplicate skill" | wc -l | tr -d ' ')
  if [ "${dupes:-0}" -gt 0 ]; then
    fail_ "$dupes duplicate-skill warning(s) since last deploy (bridge vs skills.paths collision?)"
  else
    ok "no duplicate-skill warnings since last deploy"
  fi
  # Targeted: opencode's actual plugin-load failure line, not any line that
  # happens to contain both words (permission logs quote whole heredocs).
  if grep -q 'failed to load plugin' "$logFile" 2>/dev/null; then
    fail_ "plugin load errors in $(basename "$logFile") (entries may predate the last deploy):"
    grep 'failed to load plugin' "$logFile" | tail -3 | cut -c1-200 | sed 's/^/    /'
  else
    ok "no plugin load errors in latest log"
  fi
else
  warn "no opencode log found at $logDir (run opencode once, then re-check)"
fi

printf '\n'
if [ "$fail" -eq 0 ]; then
  echo "verify-opencode: all checks passed"
else
  echo "verify-opencode: $fail check(s) failed"
fi
exit "$fail"