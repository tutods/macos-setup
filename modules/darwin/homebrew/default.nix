{...}: {
  imports = [
    ./casks/development.nix
    ./casks/utils.nix
  ];

  homebrew = {
    enable = true;

    onActivation = {
      cleanup = "uninstall";
      autoUpdate = true;
      upgrade = true;
      extraFlags = ["--force-cleanup"];
    };

    brews = [
      "mas"
      "worktrunk" # `wt`, git-worktree wrapper. Prebuilt bottle, newer than nixpkgs.
    ];

    # Homebrew 6 requires explicit trust for non-official taps before it will
    # load them (docs/Tap-Trust.md). `brew bundle` has no prompt to grant that
    # non-interactively, so it must be declared here. `trusted: true` on a
    # `cask`/`brew`/`tap` line is Homebrew Bundle syntax this nix-darwin
    # module predates and has no typed option for, hence raw `extraConfig`.
    extraConfig = ''
      cask "stablyai/orca/orca", trusted: true
    '';
  };
}
