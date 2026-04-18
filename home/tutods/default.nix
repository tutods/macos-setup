{lib, ...}: {
  home.username = "tutods";
  home.homeDirectory = lib.mkForce "/Users/tutods";
  home.stateVersion = "23.11";

  imports = [../programs];

  home.activation.installMacbookMasApps = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mas=/run/current-system/sw/bin/mas

    if [ -x "$mas" ]; then
      echo "↣ App Store apps (macbook)"
      "$mas" install 537211143   2>/dev/null && echo "  ✓ PhotoBulk"            || echo "  ✗ PhotoBulk failed — install manually"
      "$mas" install 1044549675  2>/dev/null && echo "  ✓ Elmedia Video Player" || echo "  ✗ Elmedia Video Player failed — install manually"
      "$mas" install 1006087419  2>/dev/null && echo "  ✓ SnippetsLab"          || echo "  ✗ SnippetsLab failed — install manually"
    fi
  '';
}
