{ lib, ... }:

{
  home.username      = "tutods";
  home.homeDirectory = lib.mkForce "/Users/tutods";
  home.stateVersion  = "23.11";

  imports = [ ../programs ];

  home.activation.installMacbookMasApps = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mas=/run/current-system/sw/bin/mas

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

    if [ -x "$mas" ]; then
      echo "↣ App Store apps (macbook)"
      _mas_install "Numbers"               361304891
      _mas_install "Pages"                 361309726
      _mas_install "Keynote"               361285480
      _mas_install "PhotoBulk"             537211143
      _mas_install "Elmedia Video Player"  1044549675
      _mas_install "SnippetsLab"           1006087419
      # Amphetamine (937984704) — replaced by `caf` (caffeinate) abbreviation
      # 1Blocker (1365531024) — install manually if desired
      # 1Password-Safari (1569813296) — install after 1Password cask is set up
    fi
  '';
}
