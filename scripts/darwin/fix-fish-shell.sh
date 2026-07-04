#!/usr/bin/env bash
# Re-signs the fish binary if macOS invalidated its signature, ensures it is
# listed in /etc/shells, and sets it as the default shell for the given user.
#
# Idempotent — safe to run on every darwin-rebuild activation.
# Replaces the previous scripts/fix-fish-codesign.sh (manual escape hatch)
# and the inline bash that lived in lib/mkHost.nix.
set -euo pipefail

username="${1:?usage: fix-fish-shell.sh <username>}"

fish_bin="/etc/profiles/per-user/${username}/bin/fish"
sys_fish="/run/current-system/sw/bin/fish"

# 1. Re-sign fish if macOS invalidated the code signature.
if [ -x "$fish_bin" ] && ! codesign -v "$fish_bin" 2>/dev/null; then
  echo "Re-signing fish binary (invalid code signature detected)"
  codesign --force --sign - "$fish_bin" 2>/dev/null || true
fi

# 2. Ensure fish is registered in /etc/shells.
if [ -x "$fish_bin" ] && ! grep -qx "$fish_bin" /etc/shells 2>/dev/null; then
  echo "Adding $fish_bin to /etc/shells"
  echo "$fish_bin" >> /etc/shells
fi

# 3. Pick the best available fish binary and set it as the user's default shell.
target_shell="$sys_fish"
[ -x "$fish_bin" ] && target_shell="$fish_bin"

current=$(dscl . -read "/Users/${username}" UserShell 2>/dev/null | awk '{print $2}')
if [ "$current" != "$target_shell" ]; then
  echo "Setting default shell for ${username} from ${current:-default} to $target_shell"
  dscl . -create "/Users/${username}" UserShell "$target_shell"
else
  echo "Default shell for ${username} is already set to $target_shell"
fi
