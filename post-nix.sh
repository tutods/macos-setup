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

# Install App Store apps via mas
# mas requires a logged-in App Store session — must run as the normal user, not root.
if command -v mas &>/dev/null; then
  echo "↣ Installing App Store apps"

  mas_install() {
    local name="$1"
    local id="$2"
    if mas list | grep -q "^$id "; then
      echo "  ✓ $name already installed"
    else
      echo "  ↣ Installing $name ($id)"
      mas install "$id" && echo "  ✓ $name installed" || echo "  ✗ $name failed — install manually from the App Store"
    fi
  }

  # Shared (all machines)
  mas_install "Magnet"       441258766
  mas_install "Baking Soda"  1601151613
  mas_install "Vinegar"      1591303229
  mas_install "PasteNow"     1552536109
  mas_install "Xnip"         1221250572
  mas_install "Tailscale"    1475387142
  mas_install "Wireguard"    1451685025

  # macbook only
  if [ "$(scutil --get ComputerName 2>/dev/null || true)" != "daniel.a.sousa" ]; then
    mas_install "Numbers"              409203825
    mas_install "Pages"               409201541
    mas_install "Keynote"             409183694
    mas_install "PhotoBulk"           537211143
    mas_install "Elmedia Video Player" 1044549675
    mas_install "SnippetsLab"         1006087419
    mas_install "Velja"               1607635845
    mas_install "Hidden Bar"          1452453066
    # Amphetamine (937984704) — install manually if desired
    # 1Blocker (1365531024) — install manually if desired
    # 1Password-Safari (1569813296) — install after 1Password cask is set up
  fi
else
  echo "↣ mas not found — skipping App Store installs"
fi

# Install VSCode extensions not available in nixpkgs
if command -v code &>/dev/null; then
  echo "↣ Installing VSCode extensions (marketplace only)"
  sh ./install-vscode-extensions.sh
else
  echo "↣ VSCode not found — skipping extension install"
fi
