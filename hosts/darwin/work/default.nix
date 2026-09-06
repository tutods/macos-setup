{
  mkHost,
  mkUser,
  ...
}: let
  sharedMasApps = import ../../../modules/darwin/homebrew/mas.nix;
in {
  networking.localHostName = "daniel-a-sousa";

  imports = [
    ./dock.nix
    ./homebrew
    # Note: no networking.nix here, DNS/search/knownNetworkServices are
    # macbook-only so deploys never touch the corporate/VPN DNS this machine
    # needs to resolve internal domains.
    (mkHost {
      username = "daniel.a.sousa";
      hostname = "daniel.a.sousa";
      brewUser = "admin.daniel.a.sousa";
      homeConfig = mkUser {
        username = "daniel.a.sousa";
        role = "work";
      };
      masApps = sharedMasApps;
      trustedTaps = ["atlassian/acli"];
      extraShellUsers = ["admin.daniel.a.sousa"];
    })
  ];

  # The admin account (deploys, Homebrew owner) gets the same shell
  # experience, fish, aliases, prompt, CLI tools, without editors or AI.
  home-manager.users."admin.daniel.a.sousa" = mkUser {
    username = "admin.daniel.a.sousa";
    profile = "shell";
  };
}
