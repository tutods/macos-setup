# Shared host configuration factory.
# Each host passes its unique values; fish setup, home-manager wiring,
# and nix-homebrew flags are identical across all hosts.
#
# Usage in a host default.nix:
#   { mkHost, mkUser, ... }:
#   {
#     imports = [
#       ./dock.nix
#       ./homebrew
#       (mkHost {
#         username   = "tutods";
#         hostname   = "tutods-macbook";
#         brewUser   = "tutods";
#         homeConfig = mkUser { username = "tutods"; role = "personal"; };
#         masApps    = sharedMasApps // macbookMasApps;
#       })
#     ];
#   }
{
  username,
  hostname,
  brewUser,
  homeConfig,
  masApps ? {},
}: {
  pkgs,
  pkgsUnstable,
  lib,
  ...
}: let
  fixFishShell = "${pkgs.bash}/bin/bash ${../scripts/darwin/fix-fish-shell.sh}";
  installMasApps = "${pkgs.bash}/bin/bash ${../scripts/darwin/install-mas-apps.sh}";

  masManifest = pkgs.writeText "mas-apps.tsv" (
    lib.concatStringsSep "\n" (
      lib.mapAttrsToList (name: id: "${toString id}\t${name}") masApps
    )
  );
in {
  networking.hostName = hostname;
  system.primaryUser = username;
  homebrew.user = brewUser;

  environment.shells = [pkgs.fish];
  programs.fish.enable = true;

  users.users.${username} = {
    ignoreShellProgramCheck = true;
  };

  system.activationScripts.extraActivation.text =
    ''
      ${fixFishShell} "${username}"
    ''
    + lib.optionalString (masApps != {}) ''
      ${installMasApps} "${username}" < "${masManifest}"
    '';

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit pkgs pkgsUnstable;
    };
    backupFileExtension = "backup";
    users.${username} = homeConfig;
  };

  # Homebrew is owned by brewUser (may differ from the normal user on work machines)
  nix-homebrew = {
    enable = true;
    user = brewUser;
    enableRosetta = true;
    autoMigrate = true;
    mutableTaps = true;
  };
}
