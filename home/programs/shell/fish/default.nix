{ config, pkgs, ... }:

{
  imports = [
    ./extra.nix
  ];

	home.packages = with pkgs; [
		fish
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

    plugins = [
      # {
      #   name = "fzf-fish";
      #   src = pkgs.fishPlugins.fzf-fish;
      # }
      {
        name = "z";
        src = pkgs.fishPlugins.z.src;
      }
      {
        name = "pisces";
        src = pkgs.fishPlugins.pisces.src;
      }
      {
        name = "puffer";
        src = pkgs.fishPlugins.puffer.src;
      }
    ];
  };
}
