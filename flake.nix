{
  description = "Multi-device, multi-user Nix Darwin + Home Manager setup";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-25.11-darwin";
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    # Homebrew package manager
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager, nix-homebrew, ... }:
    let
      system = "aarch64-darwin";
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          allowBroken = true;
        };
      };

      # Common configuration for all Darwin systems
      darwinCommonModules = [
        # Base darwin configuration
        ./modules/common.nix
        ./modules/darwin

        # Home-manager module
        home-manager.darwinModules.home-manager

        # Homebrew module
        nix-homebrew.darwinModules.nix-homebrew
      ];

      mkDarwin = hostFile: nix-darwin.lib.darwinSystem {
        inherit system;
        modules = darwinCommonModules ++ [
          # Host-specific configuration
          (import (./. + "/${hostFile}"))
        ];

        specialArgs = {
          inherit pkgs nixpkgs nix-darwin home-manager nix-homebrew;
        };
      };
    in {
      darwinConfigurations = {
        "macbook" = mkDarwin "./hosts/darwin/macbook";
        "mindera" = mkDarwin "./hosts/darwin/mindera.nix";
      };
    };
}
