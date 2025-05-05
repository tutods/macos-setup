{ config, pkgs, ... }:

{
  imports = [
    ./extra.nix
    ./plugins.nix
    ./completions.nix
  ];

  programs.fish = {
    enable = true;
    shellAliases = import ./alias.nix;
    shellAbbrs = import ./abbrs.nix;
    functions = import ./functions.nix;

    interactiveShellInit = ''
      bind \ew backward-kill-line
      bind \cf npm_scripts_autocomplete
    '';

    # Plugins are now defined in plugins.nix

    # plugins = [
    #   #   # fishPlugins.done
    #   # pkgs.fishPlugins.fzf-fish
    #   # pkgs.fishPlugins.pisces
    #   # fishPlugins.autopair
    #   # fishPlugins.hydro
    # ];

    # plugins = [
    #   # {
    #   #   name = "fzf-fish";
    #   #   src = pkgs.fishPlugins.fzf-fish;
    #   # }
    #   {
    #     name = "z";
    #     src = pkgs.fishPlugins.z.src;
    #   }
    #   {
    #     name = "pisces";
    #     src = pkgs.fishPlugins.pisces.src;
    #   }
    #   {
    #     name = "puffer";
    #     src = pkgs.fishPlugins.puffer.src;
    #   }
    # ];
  };
}
