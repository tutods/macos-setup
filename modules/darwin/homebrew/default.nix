{...}: {
  imports = [
    ./casks/development.nix
    ./casks/utils.nix
  ];

  homebrew = {
    enable = true;

    # Blast radius (applies to BOTH machines, this module is shared): every
    # deploy runs `brew bundle --cleanup --force-cleanup`, which
    #   - force-uninstalls any formula, cask, or tap not in the generated
    #     Brewfile, without prompting — anything installed by hand with
    #     `brew install` dies on the next deploy unless it's declared here,
    #     in the host's homebrew/, or in extraConfig below;
    #   - auto-updates Homebrew itself and upgrades every unpinned
    #     formula/cask (autoUpdate + upgrade), so deploys can pull new
    #     app versions as a side effect.
    # `./scripts/deploy-doctor.sh <host>` previews exactly what the next
    # deploy's cleanup would uninstall (only on the target machine itself —
    # brew's live state is per-machine).
    onActivation = {
      cleanup = "uninstall";
      autoUpdate = true;
      upgrade = true;
      extraFlags = ["--force-cleanup"];
    };

    brews = [
      "mas"
      "antigravity-cli"
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
