{ config, inputs, pkgs, lib, ... }:
{
  home.stateVersion = "23.11";
  home.homeDirectory = lib.mkForce "/Users/tutods";
  
  imports = [
    # Apps
    ../programs/apps/vscode
    # CLI tools
    ../programs/cli/eza.nix
    ../programs/cli/bat.nix
    ../programs/cli/git.nix
    ../programs/cli/htop.nix
    ../programs/cli/oh-my-posh
    # Shell
    ../programs/shell/zsh
  ];

  # list of programs
  # https://mipmip.github.io/home-manager-option-search
  
  programs.lf.enable = true;

  # programs.home-manager.enable = true;
  # programs.nix-index.enable = true;
}
