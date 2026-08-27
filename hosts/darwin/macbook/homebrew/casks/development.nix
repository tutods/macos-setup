{...}: {
  homebrew.casks = [
    # AI editors
    "trae"

    # API & dev tools
    "bruno"
    "responsively"

    # Containers
    "orbstack"

    # JetBrains (Homebrew instead of nixpkgs, avoids Nix wrapper issues)
    "datagrip"
    "webstorm"

    "antigravity-ide"
  ];
}
