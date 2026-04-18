#!/usr/bin/env bash

set -euo pipefail

USERNAME=$(whoami)
FISH_BIN="/etc/profiles/per-user/${USERNAME}/bin/fish"

echo "Checking fish binary at: $FISH_BIN"

if [ ! -x "$FISH_BIN" ]; then
  echo "ERROR: fish binary not found at $FISH_BIN"
  echo "Make sure fish is installed via home-manager and rebuild your config first."
  exit 1
fi

if codesign -v "$FISH_BIN" 2>/dev/null; then
  echo "fish code signature is valid - no fix needed"
  exit 0
fi

echo "Invalid code signature detected on fish binary"
echo "This happens when macOS invalidates Nix binary signatures after store operations."
echo ""
echo "Re-signing fish binary..."

sudo codesign --force --sign - "$FISH_BIN"

if codesign -v "$FISH_BIN" 2>/dev/null; then
  echo "SUCCESS: fish binary re-signed successfully"
  echo "You can now run 'fish' normally"
else
  echo "ERROR: Re-signing failed. Try rebuilding your config:"
  echo "  ./nix.sh macbook --force"
  exit 1
fi