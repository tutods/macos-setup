{ inputs, outputs, stateVersion, ... }:
{
  mkDarwin = { hostname, username ? "tutods", system ? "aarch64-darwin",}:
  let
    inherit (inputs.nixpkgs) lib;
    unstablePkgs = inputs.pkgs.legacyPackages.${system};
    customConfPath = ./../hosts/darwin/${hostname}/default.nix;
    # To check if have custom dock config or not to import the default one
    customDockConfPath = ./../hosts/darwin/${hostname}/custom-dock.nix;
    dockConf = if ! builtins.pathExists (customDockConfPath) then ./../hosts/common/darwin/dock.nix else null;
  in 
    inputs.nix-darwin.lib.darwinSystem {
      specialArgs = { inherit system inputs username unstablePkgs; };
      #extraSpecialArgs = { inherit inputs; }
      modules = [
        ../hosts/common/common-packages.nix
        ../hosts/common/darwin
        customConfPath
        dockConf
        inputs.home-manager.darwinModules.home-manager {
            networking.hostName = hostname;
            home-manager.backupFileExtension = "bkp";
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs; };
            #home-manager.sharedModules = [ inputs.nixvim.homeManagerModules.nixvim ];
            home-manager.users.${username} = {
              imports = [ ./../home/${username}.nix ]; 
            };
            # home-manager.users.${username}.home = "/Users/${username}/";
        }
        inputs.nix-homebrew.darwinModules.nix-homebrew {
          nix-homebrew = {
            enable = true;
            enableRosetta = true;
            autoMigrate = true;
            mutableTaps = true;
            user = "${username}";
            # taps = with inputs; {
            #   "homebrew/homebrew-core" = homebrew-core;
            #   "homebrew/homebrew-cask" = homebrew-cask;
            #   "homebrew/homebrew-bundle" = homebrew-bundle;
            # };
          };
        }

      ];
      # ] ++ lib.optionals (builtins.pathExists ./../hosts/darwin/${hostname}/default.nix) [
      #     (import ./../hosts/darwin/${hostname}/default.nix)
      #   ];
    };
}
