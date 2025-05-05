{ config, pkgs, ... }:

{
  imports = [
    ./extra.nix
  ];

  programs.fish = {
    enable = true;
    shellAliases = import ./alias.nix;
    shellAbbrs = import ./abbrs.nix;
    functions = import ./functions.nix;

    plugins = [
      {
        name = "plugin-git";
        src = pkgs.fishPlugins.plugin-git.src;
      }
      {
        name = "pisces";
        src = pkgs.fishPlugins.pisces.src;
      }
      {
        name = "fzf.fish";
        src = pkgs.fetchFromGitHub {
          owner = "PatrickF1";
          repo = "fzf.fish";
          rev = "8920367cf85eee5218cc25a11e209d46e2591e7a";
          sha256 = "T8KYLA/r/gOKvAivKRoeqIwE2pINlxFQtZJHpOy9GMM=";
        };
      }
      {
        name = "fish-abbreviation-tips";
        src = pkgs.fetchFromGitHub {
          owner = "gazorby";
          repo = "fish-abbreviation-tips";
          rev = "8ed76a62bb044ba4ad8e3e6832640178880df485";
          sha256 = "T8KYLA/r/gOKvAivKRoeqIwE2pINlxFQtZJHpOy9GMM=";
        };
      }
    ];

    interactiveShellInit = ''
      bind \ew backward-kill-line

      # Configure fzf.fish bindings
      fzf_configure_bindings
      
      # Bind Tab key to our custom fzf cd completion function
      #bind \t '__fzf_cd_completion; or commandline -f complete'

      # Set directory preview command for fzf
      set fzf_preview_dir_cmd eza --all --color=always
    '';
  };
}
