#!/usr/bin/env bash
set -uo pipefail

guard="$(dirname "$0")/destructive-guard.sh"
fail=0

check() {
  local want=$1 cmd=$2 out got
  out=$(jq -cn --arg c "$cmd" '{tool_input: {command: $c}}' | bash "$guard")
  got=allow
  [[ "$out" == *'"ask"'* ]] && got=ask
  if [ "$got" = "$want" ]; then
    printf 'ok   %-5s %s\n' "$want" "$cmd"
  else
    printf 'FAIL want %s got %s: %s\n' "$want" "$got" "$cmd"
    fail=1
  fi
}

check allow 'rm -rf /tmp/build'
check allow 'rm -rf /tmp/a /tmp/b'
check allow 'rm -rf $TMPDIR/x'
check allow 'rm file.txt'
check ask 'rm -rf node_modules'
check ask 'rm -rf /tmp/a node_modules'
check ask 'rm -rf ./x # /tmp/'
check ask 'rm -rf /tmp/../etc'
check ask 'rm --recursive dist'
check allow 'rm --recursive /tmp/x'
check ask 'ls && rm -r build'
check ask 'git -C ../repo push --force origin main'
check ask 'git -C ../repo push origin main -f'
check ask 'git push --force-with-lease'
check ask 'git push origin +main'
check ask 'git push origin +HEAD:main'
check allow 'git push origin main'
check allow 'git push -u origin feature/a+b'
check allow 'git status'
check ask 'git reset --hard HEAD~1'

exit "$fail"
