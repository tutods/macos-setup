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
    ];

    interactiveShellInit = ''
      bind \ew backward-kill-line

      # Set directory preview command for fzf
      set fzf_preview_dir_cmd eza --all --color=always
    '';
  };
}
