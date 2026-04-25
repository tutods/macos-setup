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
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nix-darwin,
    home-manager,
    nix-homebrew,
    ...
  }: let
    system = "aarch64-darwin";
    pkgs = import nixpkgs {
      inherit system;
      config = {
        allowUnfree = true;
      };
    };

    mkHost = import ./lib/mkHost.nix;
    mkUser = import ./lib/mkUser.nix;

    # Common modules applied to every host
    darwinCommonModules = [
      ./modules/common.nix
      ./modules/darwin
      home-manager.darwinModules.home-manager
      nix-homebrew.darwinModules.nix-homebrew
    ];

    mkDarwin = hostPath:
      nix-darwin.lib.darwinSystem {
        inherit system;
        modules =
          darwinCommonModules
          ++ [
            hostPath
          ];
        specialArgs = {
          inherit pkgs nixpkgs nix-darwin home-manager nix-homebrew mkHost mkUser;
        };
      };
  in {
    formatter.${system} = pkgs.alejandra;

    darwinConfigurations = {
      macbook = mkDarwin ./hosts/darwin/macbook;
      work = mkDarwin ./hosts/darwin/work;
    };
  };
}
