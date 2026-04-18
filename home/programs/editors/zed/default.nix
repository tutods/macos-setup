{ config, pkgs, ... }:

{
  home.file.".config/zed/settings.json".source = ./settings.json;
}