{ lib, ... }:

# App Store apps installed via mas.
# home.activation runs as the logged-in user (not root), so the App Store
# session is available — unlike masApps in the homebrew nix-darwin option
# which runs under sudo and always fails.
{
  home.activation.installMasApps = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mas=/run/current-system/sw/bin/mas

    if ! command -v "$mas" &>/dev/null; then
      echo "↣ mas not found — skipping App Store installs"
      return
    fi

    _mas_install() {
      local name="$1"
      local id="$2"
      if "$mas" list 2>/dev/null | grep -q "^$id "; then
        echo "  ✓ $name already installed"
      else
        echo "  ↣ Installing $name"
        "$mas" install "$id" 2>/dev/null \
          && echo "  ✓ $name" \
          || echo "  ✗ $name failed — install manually from the App Store"
      fi
    }

    echo "↣ App Store apps (shared)"
    _mas_install "Magnet"       441258766
    _mas_install "Baking Soda"  1601151613
    _mas_install "Vinegar"      1591303229
    _mas_install "PasteNow"     1552536109
    _mas_install "Xnip"         1221250572
    _mas_install "Tailscale"    1475387142
    _mas_install "Wireguard"    1451685025
  '';
}
