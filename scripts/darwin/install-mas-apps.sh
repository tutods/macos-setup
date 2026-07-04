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

while IFS=$'\t' read -r app_id name; do
  [ -z "$app_id" ] && continue
  if /opt/homebrew/bin/mas list 2>/dev/null | grep -q "^${app_id} "; then
    echo "  ✓ ${name} already installed"
    continue
  fi
  echo "  ↣ Installing ${name}"
  if HOME="/Users/${username}" /opt/homebrew/bin/mas install "${app_id}" </dev/null; then
    echo "  ✓ ${name}"
  else
    echo "  ✗ ${name} failed — install manually from App Store"
  fi
done
