{
  mkHost,
  mkUser,
  ...
}: let
  sharedMasApps = import ../../../modules/darwin/homebrew/mas.nix;
in {
  imports = [
    ./dock.nix
    ./homebrew
    (mkHost {
      username = "daniel.a.sousa";
      hostname = "daniel.a.sousa";
      brewUser = "admin.daniel.a.sousa";
      homeConfig = mkUser {
        username = "daniel.a.sousa";
        extraImports = [../../../home/programs/work];
      };
      masApps = sharedMasApps;
    })
  ];
}
