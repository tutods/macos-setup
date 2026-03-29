{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    claude-code
    terraform

    # JetBrains
    jetbrains.webstorm
    jetbrains.datagrip
  ];
}
