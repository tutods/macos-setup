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

# Activation runs as root, but the App Store session and the Spotlight index
# mas reads are per-user: run mas as the target user (mirroring nix-darwin's
# brew-bundle invocation), letting mas elevate itself via sudo when needed.
mas=(/opt/homebrew/bin/mas)
if [ "$(id -u)" -eq 0 ]; then
  mas=(sudo --user "${username}" --set-home /opt/homebrew/bin/mas)
fi

echo "↣ App Store apps"

# One snapshot, matched as a variable: `mas list | grep -q` under pipefail can
# fail via SIGPIPE even when the app IS installed, causing spurious reinstalls.
installed=$("${mas[@]}" list </dev/null 2>/dev/null || true)

failures=()

# `|| [ -n "$app_id" ]` keeps a final TSV line that lacks a trailing newline.
while IFS=$'\t' read -r app_id name || [ -n "$app_id" ]; do
  [ -z "$app_id" ] && continue
  # Pure-shell match (no pipe, so no SIGPIPE under pipefail): the id must sit
  # alone, space-delimited. mas 7 right-aligns ids with a leading space, so
  # `*" <id> "*` carries the padded lines.
  case "$installed" in
    "${app_id} "* | *" ${app_id} "* | *$'\n'"${app_id} "*)
      echo "  ✓ ${name} already installed"
      continue
      ;;
  esac
  echo "  ↣ Installing ${name}"
  # stdin is the manifest, so installs read the terminal instead: mas prompts
  # there for the sudo password it needs.
  if "${mas[@]}" install "${app_id}" </dev/tty; then
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
