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
  # Additional accounts that should also get fish as their default shell
  # (fix-fish-shell.sh runs for each). Pair with a home-manager.users entry
  # in the host file so the per-user fish profile actually exists.
  extraShellUsers ? [],
}: {
  pkgs,
  pkgsUnstable,
  lib,
  ...
}: let
  fixFishShell = "${pkgs.bash}/bin/bash ${../scripts/darwin/fix-fish-shell.sh}";

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
    + lib.concatMapStringsSep "" (u: ''
      ${fixFishShell} "${u}"
    '')
    extraShellUsers
    # Seed-once: never clobber taps the user added manually via `brew trust`.
    + lib.optionalString (trustedTaps != []) ''
      if [ ! -f "${trustFile}" ]; then
        install -d -m 0755 -o "${brewUser}" -g staff "/Users/${brewUser}/.homebrew"
        install -m 0644 -o "${brewUser}" -g staff "${trustManifest}" "${trustFile}"
      fi
    '';

  # nix.sh installs these as the user after switch: from root activation
  # `mas list` returns a partial list, so installed apps re-prompted for sudo.
  environment.etc."mas-apps.tsv" = lib.mkIf (masApps != {}) {source = masManifest;};

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    # aiLib is passed in rather than imported per module: it used to be
    # `import ../../../../lib/ai.nix` in five files, which silently encoded the
    # depth of each one and had to be recounted on every directory move.
    extraSpecialArgs = {
      inherit pkgs pkgsUnstable;
      aiLib = import ./ai.nix {inherit pkgs;};
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
