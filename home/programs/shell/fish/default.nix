{ config, pkgs, lib, ... }:

{
  imports = [ ./extra.nix ];

  programs.fish = {
    enable = true;
    shellAliases = import ./alias.nix;
    shellAbbrs = import ./abbrs.nix;
    functions = import ./functions.nix;

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
      set -g fish_complete_path $fish_complete_path ~/.config/fish/completions

      bind \ew backward-kill-line

      set fzf_preview_dir_cmd eza --all --color=always

      fnm env --use-on-cd --shell fish --corepack-enabled | source

      export PATH="$HOME/.local/bin:$PATH"
    '';
  };
}