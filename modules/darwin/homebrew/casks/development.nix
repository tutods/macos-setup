{...}: {
  homebrew.casks = [
    # Dev tools
    "beekeeper-studio"
    "zed"
    "ghostty"
    "copilot-cli"

    # JetBrains (Homebrew instead of nixpkgs — avoids Nix wrapper issues)
    "webstorm"
  ];
}
