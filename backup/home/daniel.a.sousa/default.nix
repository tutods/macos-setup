{ config, inputs, pkgs, lib, ... }:
{
  home.stateVersion = "23.11";
  home.homeDirectory = lib.mkForce "/Users/daniel.a.sousa";

  imports = [
    # Apps
    ../programs/apps/vscode
    # CLI tools
    ../programs/cli/bat.nix
    ../programs/cli/htop.nix
    ../programs/cli/oh-my-posh
    ./git.nix
    # Shell
    ../programs/shell/zsh
  ];

  # list of programs
  # https://mipmip.github.io/home-manager-option-search
}
