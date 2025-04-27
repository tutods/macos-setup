{ pkgs, ...}:

{
  programs.oh-my-posh = {
    enable = true;
    settings = pkgs.lib.importTOML ./base.toml;
  };
}