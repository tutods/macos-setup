{...}: {
  homebrew.casks = [
    # Dev tools
    "beekeeper-studio"
    "zed"
    # orca (stablyai/orca/orca) is declared via `homebrew.extraConfig` in
    # ../default.nix, not here: Homebrew 6's tap-trust feature needs `trusted:
    # true` on the entry, which this nix-darwin module's `casks` option can't
    # express.
    "ghostty"
    "google-gemini"
  ];
}
