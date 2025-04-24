{ config, inputs, pkgs, lib, ... }:
{
  home.stateVersion = "23.11";
  home.homeDirectory = lib.mkForce "/Users/daniel.a.sousa";

  imports = [
    ./apps/vscode
    ./cli/fzf.nix
    ./cli/eza.nix
    ./cli/htop.nix
    ./cli/oh-my-posh
  ];

  # list of programs
  # https://mipmip.github.io/home-manager-option-search

  programs.git = {
    enable = true;
    userEmail = "daniel.a.sousa@mindera.com";
    userName = "Daniel Sousa";
    diff-so-fancy.enable = true;
    lfs.enable = true;
    extraConfig = {
      init = {
        defaultBranch = "main";
      };
      # merge = {
      #   conflictStyle = "diff3";
      #   tool = "meld";
      # };
      pull = {
        rebase = true;
      };
    };
  };

  # aerospace config
  # home.file = lib.mkMerge [
  #   (lib.mkIf pkgs.stdenv.isDarwin {
  #     ".config/aerospace/aerospace.toml".text = builtins.readFile ./aerospace/aerospace.toml;
  #   })
  # ];

  programs.gpg.enable = true;

  # programs.direnv = {
  #   enable = true;
  #   nix-direnv.enable = true;
  # };

  
  programs.lf.enable = true;

  # programs.starship = {
  #   enable = true;
  #   enableZshIntegration = true;
  #   enableBashIntegration = true;
  #   settings = pkgs.lib.importTOML ./starship/starship.toml;
  # };

  # programs.bash.enable = true;

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    initContent = (builtins.readFile ../data/mac-dot-zshrc);
  };

  programs.home-manager.enable = true;
  programs.nix-index.enable = true;

  programs.bat = {
    enable = true;
    # config.theme = "Catppuccin Mocha";
  };

  programs.zoxide.enable = true;
}
