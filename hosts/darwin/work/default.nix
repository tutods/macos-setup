{
  mkHost,
  mkUser,
  ...
}: let
  sharedMasApps = import ../../../modules/darwin/homebrew/mas.nix;
in {
  networking.localHostName = "daniel.a.sousa";

  imports = [
    ./dock.nix
    ./homebrew
    ./packages.nix # Work-specific system packages
    # Note: networking.nix NOT imported — corporate DNS must resolve internal domains
    (mkHost {
      username = "daniel.a.sousa";
      hostname = "daniel.a.sousa";
      brewUser = "admin.daniel.a.sousa";
      homeConfig = mkUser {
        username = "daniel.a.sousa";
        role = "work";
      };
      masApps = sharedMasApps;
    })
  ];
}
