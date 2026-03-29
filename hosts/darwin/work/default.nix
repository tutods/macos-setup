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

  # home.activation runs as admin.daniel.a.sousa on this machine, so use
  # system.activationScripts (runs as root) to create the Developer folder
  # with the correct owner instead.
  system.activationScripts.createDeveloperDir.text = ''
    if [ ! -d "/Users/daniel.a.sousa/Developer" ]; then
      echo "↣ Create Developer directory for daniel.a.sousa"
      mkdir -p "/Users/daniel.a.sousa/Developer"
      chown daniel.a.sousa "/Users/daniel.a.sousa/Developer"
    fi
  '';
}
