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

    plugins = with pkgs; [
      fishPlugins.fzf-fish
      fishPlugins.z.src
      fishPlugins.pisces.src
      # fishPlugins.puffer.src
    ];
  };
}
