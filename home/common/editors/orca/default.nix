{
  config,
  lib,
  ...
}: {
  # Orca writes its own settings UI changes back to ~/.orca/keybindings.json,
  # so it's seeded as a one-time copy, not a store symlink (see CLAUDE.md).
  home.activation.orcaSeedKeybindings = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p "${config.home.homeDirectory}/.orca"
    run install -m 0644 ${./keybindings.json} "${config.home.homeDirectory}/.orca/keybindings.json"
  '';
}
