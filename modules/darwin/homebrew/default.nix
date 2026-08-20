{...}: {
  imports = [
    ./casks/browsers.nix
    ./casks/communication.nix
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

    taps = [
      "stablyai/orca"
    ];

    brews = [
      "mas"
      "worktrunk" # `wt`, git-worktree wrapper. Prebuilt bottle, newer than nixpkgs.
    ];
  };
}
