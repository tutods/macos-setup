{
  pkgs,
  mkHost,
  ...
}: {
  imports = [
    ./dock.nix
    ./homebrew
    ./networking.nix
    (mkHost {
      username = "tutods";
      hostname = "tutods-macbook";
      brewUser = "tutods";
      homeConfig = import ../../../home/tutods/default.nix;
    })
  ];

  environment.systemPackages = [pkgs.pipx];
}
