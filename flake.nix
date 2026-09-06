{
  description = "Multi-device, multi-user Nix Darwin + Home Manager setup";

  inputs = {
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
      inputs.brew-src.url = "github:Homebrew/brew/6.0.13";
    };

    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
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
    pkgsUnstable = import nixpkgs-unstable {
      inherit system;
      config = {
        allowUnfree = true;
      };
    };

    mkHost = import ./lib/mkHost.nix;
    mkUser = import ./lib/mkUser.nix;
    mkDock = import ./lib/mkDock.nix;

    hosts = import ./hosts.nix;

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
          inherit pkgs pkgsUnstable mkHost mkUser mkDock;
        };
      };
  in {
    # `pkgs.alejandra` directly would exec with no path arg on bare `nix fmt`,
    # so it reads (and fails on) stdin instead of formatting the tree.
    formatter.${system} = pkgs.writeShellApplication {
      name = "fmt";
      runtimeInputs = [pkgs.alejandra];
      text = ''alejandra "''${@:-.}"'';
    };

    checks.${system} =
      (builtins.mapAttrs (name: _: self.darwinConfigurations.${name}.system) hosts)
      // {
        fmt = pkgs.runCommand "fmt-check" {} ''
          ${pkgs.alejandra}/bin/alejandra --check ${self}
          touch $out
        '';
      };

    darwinConfigurations = builtins.mapAttrs (_: host: mkDarwin host.hostPath) hosts;
  };
}
