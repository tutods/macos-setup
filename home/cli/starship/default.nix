{ config, pkgs, ... }:

{

	home.packages = with pkgs; [
		starship
	];

	#      the standard path under ~/.config/ 
	#           to find the file       Where the file is located relative to this .nix file
	#                    |                             |
	#                    V                             V
	xdg.configFile."starship.toml".source = ./starship.toml;

  programs.starship = {
    enable = true;
		enableFishIntegration = true;
  };
  
}
