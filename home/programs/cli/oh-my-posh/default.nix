{ pkgs, ... }:

{
  programs.oh-my-posh = {
    enable = true;
    enableFishIntegration = true;
    settings = pkgs.lib.importTOML ./base.toml;
  };
}
