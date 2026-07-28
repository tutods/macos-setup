{...}: {
  homebrew.casks = [
    # AI editors
    "trae"
    "supacode"

    # API & dev tools
    "bruno"
    "responsively"

    # Containers
    "podman-desktop"

    # JetBrains (Homebrew instead of nixpkgs — avoids Nix wrapper issues)
    "datagrip"
  ];
}
