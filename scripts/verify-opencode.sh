#!/usr/bin/env bash
# opencode setup verification: checks the deployed opencode state against what
# the flake declares, so a broken deploy surfaces as a failed check instead of
# a silently degraded session. Backs the /verify-setup opencode command.
# macbook / personal machine only. Exit 1 on any failure, 0 when clean
# (warnings don't fail). Deps: jq. Read-only: prints, never fixes.
set -uo pipefail

home="${HOME}"
ocDir="$home/.config/opencode"
logDir="$home/.local/share/opencode/log"
fail=0
warn() { printf '  warn: %s\n' "$1"; }
fail_() { printf '  FAIL: %s\n' "$1"; fail=$((fail + 1)); }
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

section "opencode.json"
cfg="$ocDir/opencode.json"
if [ ! -f "$cfg" ]; then
  fail_ "$cfg missing"
elif jq -e . "$cfg" >/dev/null 2>&1; then
  ok "valid JSON"
  if jq -e '(.mcp | keys) == ["shadcn"] and .mcp.shadcn.enabled == true' "$cfg" >/dev/null 2>&1; then
    ok "mcp is exactly shadcn, enabled"
  else
    fail_ "mcp must be exactly {shadcn: enabled}; config.nix declares no other server"
  fi
  if jq -e '.subagent_depth == 1' "$cfg" >/dev/null 2>&1; then
    ok "subagent_depth = 1"
  else
    fail_ "subagent_depth != 1 (expected from config.nix)"
  fi
  if jq -e '.lsp == true' "$cfg" >/dev/null 2>&1; then
    ok "lsp enabled"
  else
    fail_ "lsp not enabled"
  fi
  if jq -e '.skills.paths | index("~/.claude/skills") != null' "$cfg" >/dev/null 2>&1; then
    ok "skills.paths includes ~/.claude/skills"
  else
    fail_ "skills.paths missing ~/.claude/skills"
  fi
  if jq -e '.skills.paths | index("~/.agents/skills") == null' "$cfg" >/dev/null 2>&1; then
    ok "skills.paths excludes ~/.agents/skills (npx skills tree retired)"
  else
    fail_ "skills.paths still lists ~/.agents/skills, retired with the npx skills tree"
  fi
  if jq -e '.agent["vault-lint"] and .agent["vault-search"]' "$cfg" >/dev/null 2>&1; then
    ok "agent has vault-lint and vault-search"
  else
    fail_ "agent missing vault-lint or vault-search"
  fi
  if jq -e '(.agent | has("orchestrator") or has("code-reviewer") or has("dev-lifecycle")) | not' "$cfg" >/dev/null 2>&1; then
    ok "no orchestrator/code-reviewer/dev-lifecycle agent"
  else
    fail_ "orchestrator/code-reviewer/dev-lifecycle agent present, should have been dropped"
  fi
  if jq -e 'has("default_agent") | not' "$cfg" >/dev/null 2>&1; then
    ok "no default_agent key"
  else
    fail_ "default_agent key present, config.nix declares none"
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
for f in agents/vault-search.md agents/vault-lint.md commands/council.md commands/nixcheck.md commands/verify-setup.md plugins/opencode-parity.js AGENTS.md; do
  if [ -f "$ocDir/$f" ]; then
    ok "$f"
  else
    fail_ "$f missing"
  fi
done

section "AGENTS.md byte budget"
agentsMd="$ocDir/AGENTS.md"
if [ -f "$agentsMd" ]; then
  bytes=$(wc -c <"$agentsMd" | tr -d ' ')
  if [ "$bytes" -le 7000 ]; then
    ok "AGENTS.md is $bytes bytes (<= 7000)"
  else
    fail_ "AGENTS.md is $bytes bytes, over the 7000 byte budget, the whole point of the rebuild"
  fi
else
  fail_ "$agentsMd missing"
fi

section "skill bridge (retired)"
skillsDir="$ocDir/skills"
if [ -d "$skillsDir" ]; then
  bridged=""
  for link in "$skillsDir"/*; do
    [ -L "$link" ] || continue
    case "$(readlink "$link")" in
      "$home"/.claude/plugins/*) bridged="$bridged $(basename "$link")" ;;
    esac
  done
  if [ -n "$(echo "$bridged" | tr -d ' ')" ]; then
    fail_ "leftover bridge symlink(s) into ~/.claude/plugins (should be gone):$bridged"
  else
    ok "no symlinks into ~/.claude/plugins under $skillsDir"
  fi
else
  ok "no $skillsDir (nothing to check)"
fi

section "plugins directory"
# Mirrors managedPlugins/toleratedPlugins in default.nix; keep in sync.
managedPlugins="opencode-parity.js"
toleratedPlugins="supacode-presence.js"
pluginsDir="$ocDir/plugins"
if [ -d "$pluginsDir" ]; then
  unexpected=""
  for f in "$pluginsDir"/*; do
    [ -e "$f" ] || continue
    name="$(basename "$f")"
    case " $managedPlugins $toleratedPlugins " in
      *" $name "*) ;;
      *) unexpected="$unexpected $name" ;;
    esac
  done
  if [ -n "$(echo "$unexpected" | tr -d ' ')" ]; then
    fail_ "unmanaged plugin(s) in $pluginsDir (the deploy prunes these, so the prune hasn't run or something re-added them):$unexpected"
  else
    ok "plugins dir holds only the managed + tolerated set"
  fi
else
  warn "$pluginsDir missing"
fi

section "opencode log"
logFile="$(ls -t "$logDir"/opencode.log 2>/dev/null | head -1 || true)"
if [ -n "$logFile" ] && [ -f "$logFile" ]; then
  # Only count warnings since this deploy: log is append-only, timestamps
  # UTC, BSD stat has no UTC output so convert the local mtime instead.
  deployTs="$(date -u -j -f '%b %d %H:%M:%S %Y' "$(stat -f '%Sm' "$cfg" 2>/dev/null)" '+%Y-%m-%dT%H:%M:%S' 2>/dev/null || true)"
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
    fail_ "$dupes duplicate-skill warning(s) since last deploy (~/.claude/skills vs project .claude/skills collision?)"
  else
    ok "no duplicate-skill warnings since last deploy"
  fi
  # Targeted phrase, not any line containing both words (permission logs
  # quote whole heredocs).
  pluginErrs=$(recent 'failed to load plugin' | wc -l | tr -d ' ')
  if [ "${pluginErrs:-0}" -gt 0 ]; then
    fail_ "plugin load errors since last deploy in $(basename "$logFile"):"
    recent 'failed to load plugin' | tail -3 | cut -c1-200 | sed 's/^/    /'
  else
    ok "no plugin load errors since last deploy"
  fi
else
  warn "no opencode log found at $logDir (run opencode once, then re-check)"
fi

printf '\n'
if [ "$fail" -eq 0 ]; then
  echo "verify-opencode: all checks passed"
  exit 0
else
  echo "verify-opencode: $fail check(s) failed"
  exit 1
fi
