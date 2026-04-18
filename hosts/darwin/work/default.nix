{mkHost, ...}: let
  sharedMasApps = import ../../../modules/darwin/homebrew/mas.nix;
in {
  imports = [
    ./dock.nix
    ./homebrew
    (mkHost {
      username = "daniel.a.sousa";
      hostname = "daniel.a.sousa";
      brewUser = "admin.daniel.a.sousa";
      homeConfig = import ../../../home/daniel.a.sousa/default.nix;
      masApps = sharedMasApps;
    })
  ];

  system.activationScripts.extraActivation.text = ''
    if [ ! -d "/Users/daniel.a.sousa/Developer" ]; then
      echo "↣ Create Developer directory for daniel.a.sousa"
      mkdir -p "/Users/daniel.a.sousa/Developer"
      chown daniel.a.sousa "/Users/daniel.a.sousa/Developer"
    fi
  '';
}
