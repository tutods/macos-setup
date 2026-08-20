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

    brews = [
      "mas"
    ];
  };
}
