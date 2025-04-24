{
  lib,
  pkgs,
  config,
  inputs,
  ...
}:
with lib;
with inputs; let
  cfg = config.roles.development;
in {
  imports = [
    catppuccin.homeManagerModules.catppuccin
  ];

  options.roles.development = {
    enable = mkEnableOption "Enable development configuration";
  };

  config = mkIf cfg.enable {
    colorscheme = nix-colors.colorSchemes.catppuccin-mocha;
    catppuccin = {
      enable = true;
      flavor = "mocha";
    };

    browsers.firefox.enable = true;

    system = {
      fonts.enable = true;
    };

    cli = {
      shells.fish.enable = true;
    };
    programs = {
      bat.enable = true;
      eza.enable = true;
      fzf.enable = true;
      git.enable = true;
      htop.enable = true;
      podman.enable = true;
      starship.enable = true;
      zoxide.enable = true;
    };

    security = {
      sops.enable = true;
    };
  };

}
