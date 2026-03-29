#!/usr/bin/env bash

set -euo pipefail

# Set fish as default shell
echo "↣ Setting fish as default shell"
FISH_PATH=""
for candidate in \
  "/run/current-system/sw/bin/fish" \
  "/etc/profiles/per-user/$USER/bin/fish" \
  "$(command -v fish 2>/dev/null || true)"; do
  if [ -x "$candidate" ]; then
    FISH_PATH="$candidate"
    break
  fi
done

if [ -z "$FISH_PATH" ]; then
  echo "  ✗ fish not found — skipping shell change"
else
  if ! grep -qF "$FISH_PATH" /etc/shells; then
    echo "$FISH_PATH" | sudo tee -a /etc/shells > /dev/null
  fi
  chsh -s "$FISH_PATH"
  echo "  ✓ Default shell set to $FISH_PATH"
fi

