{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    # Homebrew package manager
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";

    # Home manager
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { ... }@inputs:
    with inputs;
    let
      inherit (self) outputs;
      libx = import ./lib { inherit inputs outputs stateVersion; };

    in {
      # macOS Configurations
      darwinConfigurations = {
        # personal
        macbook = libx.mkDarwin { 
          hostname = "macbook"; 
        };
        # work
        mindera = libx.mkDarwin { 
          hostname = "work"; 
          username = "daniel.a.sousa"; 
        };
      };

    };
}
