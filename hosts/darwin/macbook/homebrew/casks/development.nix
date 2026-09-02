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
    # Google's official replacement for gemini-cli (nixpkgs deprecated it,
    # removal 2026-12-18); not in nixpkgs, so Homebrew is the only source.
    "antigravity-cli"
  ];
}
