#!/usr/bin/env bash
# Installs Mac App Store apps via `mas`. Reads TSV lines "<id>\t<name>" from
# stdin. Skips apps already installed. Designed to be invoked from a Nix
# activation script that pipes in a generated TSV manifest.
#
# Usage:
#   install-mas-apps.sh <username> < /nix/store/.../mas-apps.tsv
set -euo pipefail

username="${1:?usage: install-mas-apps.sh <username>}"

[ -x /opt/homebrew/bin/mas ] || exit 0

echo "↣ App Store apps"

# One snapshot, matched as a variable: `mas list | grep -q` under pipefail can
# fail via SIGPIPE even when the app IS installed, causing spurious reinstalls.
installed=$(/opt/homebrew/bin/mas list 2>/dev/null || true)

failures=()

while IFS=$'\t' read -r app_id name; do
  [ -z "$app_id" ] && continue
  if printf '%s\n' "$installed" | grep -q "^${app_id} "; then
    echo "  ✓ ${name} already installed"
    continue
  fi
  echo "  ↣ Installing ${name}"
  if HOME="/Users/${username}" /opt/homebrew/bin/mas install "${app_id}" </dev/null; then
    echo "  ✓ ${name}"
  else
    echo "  ✗ ${name} failed"
    failures+=("${name}")
  fi
done

if [ ${#failures[@]} -gt 0 ]; then
  echo "warning: ${#failures[@]} Mac App Store app(s) failed to install: ${failures[*]}"
  echo "warning: re-run ./nix.sh or install them from the App Store"
fi
