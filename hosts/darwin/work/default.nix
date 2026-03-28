{ mkHost, ... }:

{
  imports = [
    ./dock.nix
    ./homebrew
    (mkHost {
      username   = "daniel.a.sousa";
      hostname   = "daniel.a.sousa";
      brewUser   = "admin.daniel.a.sousa";
      homeConfig = import ../../../home/daniel.a.sousa/default.nix;
    })
  ];
}
