# Shared host configuration factory.
# Each host passes its unique values; fish setup, home-manager wiring,
# and nix-homebrew flags are identical across all hosts.
#
# Usage in a host default.nix:
#   { pkgs, mkHost, ... }:
#   {
#     imports = [
#       ./dock.nix
#       ./homebrew
#       (mkHost {
#         username   = "tutods";
#         hostname   = "tutods-macbook";
#         brewUser   = "tutods";
#         homeConfig = import ../../../home/tutods/default.nix;
#       })
#     ];
#   }

{ username, hostname, brewUser, homeConfig }:
{ pkgs, ... }: {
  networking.hostName = hostname;
  system.primaryUser  = username;

  environment.shells = [ pkgs.fish ];
  programs.fish.enable = true;

  users.users.${username} = {
    shell = pkgs.fish;
    ignoreShellProgramCheck = true;
  };

  home-manager = {
    useGlobalPkgs     = true;
    useUserPackages   = true;
    extraSpecialArgs  = { inherit pkgs; };
    backupFileExtension = "backup";
    users.${username} = homeConfig;
  };

  # Homebrew is owned by brewUser (may differ from the normal user on work machines)
  nix-homebrew = {
    enable        = true;
    user          = brewUser;
    enableRosetta = true;
    autoMigrate   = true;
    mutableTaps   = true;
  };
}
