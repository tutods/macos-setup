{...}: {
  imports = [
    ./casks/browsers.nix
    ./casks/communication.nix
    ./casks/development.nix
    ./casks/fonts.nix
    ./casks/utils.nix
  ];

  homebrew.brews = [
    "podman"
    "docker-compose"
  ];
}
