{ config, pkgs, lib, ... }:

{
  imports = [
    ./extra.nix
  ];

  programs.fish = {
    enable = true;
    shellAliases = import ./alias.nix;
    shellAbbrs = import ./abbrs.nix;
    functions = import ./functions.nix;
    
    # Set environment variables for all fish shells (including non-interactive)
    shellInit = ''
      if test -f ~/.config/fish/secrets.fish
        source ~/.config/fish/secrets.fish
      end
    '';

    plugins = [
      {
        name = "plugin-git";
        src = pkgs.fishPlugins.plugin-git.src;
      }
      {
        name = "pisces";
        src = pkgs.fishPlugins.pisces.src;
      }
    ];

    interactiveShellInit = ''
      bind \ew backward-kill-line

      # Set directory preview command for fzf
      set fzf_preview_dir_cmd eza --all --color=always

      # FNM
      fnm env --use-on-cd --shell fish --corepack-enabled | source
    '';
  };
}
