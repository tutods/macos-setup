{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    # nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    # homebrew-core = { url = "github:homebrew/homebrew-core"; flake = false; };
    # homebrew-cask = { url = "github:homebrew/homebrew-cask"; flake = false; };
    # homebrew-bundle = { url = "github:homebrew/homebrew-bundle"; flake = false; };
    # Homebrew package manager
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
  };

  outputs = { ... }@inputs:
    with inputs;
    let
      inherit (self) outputs;

      # stateVersion = "24.05";
      libx = import ./lib { inherit inputs outputs stateVersion; };

    in {
      
      darwinConfigurations = {
        # personal
        macbook = libx.mkDarwin { hostname = "macbook"; };
        # work
        mindera = libx.mkDarwin { hostname = "work"; };
      };

    };
}
