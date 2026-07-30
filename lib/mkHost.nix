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
  trustedTaps ? [],
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

  # Homebrew 6.0.13+ refuses non-official tap formulae unless trusted.
  # Seeded into brewUser's ~/.homebrew/trust.json before the activation bundle runs.
  trustManifest = pkgs.writeText "homebrew-trust.json" (
    builtins.toJSON {trustedtaps = trustedTaps;}
  );
  trustFile = "/Users/${brewUser}/.homebrew/trust.json";
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
    # Seed-once: never clobber taps the user added manually via `brew trust`.
    + lib.optionalString (trustedTaps != []) ''
      if [ ! -f "${trustFile}" ]; then
        install -d -m 0755 -o "${brewUser}" -g staff "/Users/${brewUser}/.homebrew"
        install -m 0644 -o "${brewUser}" -g staff "${trustManifest}" "${trustFile}"
      fi
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
