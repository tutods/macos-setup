{ config, pkgs, ... }:

{
	home.packages = with pkgs; [
		fish
	];

  programs.fish = {
    enable = true;
    shellAliases = import ./alias.nix;
    shellAbbrs = import ./abbrs.nix;
    functions = import ./extensions.nix;
  };
}
