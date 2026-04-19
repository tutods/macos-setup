{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    terraform
    # JetBrains
    jetbrains.webstorm
    jetbrains.datagrip
  ];
}
