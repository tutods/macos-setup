{
  mkHost,
  mkUser,
  ...
}: let
  sharedMasApps = import ../../../modules/darwin/homebrew/mas.nix;
  macbookMasApps = import ./homebrew/mas.nix;
in {
  imports = [
    ./dock.nix
    ./homebrew
    ./networking.nix
    ./packages.nix
    (mkHost {
      username = "tutods";
      hostname = "tutods-macbook";
      brewUser = "tutods";
      homeConfig = mkUser {
        username = "tutods";
        extraImports = [../../../home/programs/personal];
      };
      masApps = sharedMasApps // macbookMasApps;
    })
  ];
}
