{
  pkgs,
  mkHost,
  lib,
  ...
}: let
  sharedMasApps = import ../../../modules/darwin/homebrew/mas.nix;
  macbookMasApps = import ./homebrew/mas.nix;
in {
  imports = [
    ./dock.nix
    ./homebrew
    ./networking.nix
    (mkHost {
      username = "tutods";
      hostname = "tutods-macbook";
      brewUser = "tutods";
      homeConfig = import ../../../home/tutods/default.nix;
      masApps = sharedMasApps // macbookMasApps;
    })
  ];

  environment.systemPackages = [pkgs.pipx];
}
