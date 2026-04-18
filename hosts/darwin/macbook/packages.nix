{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    pipx
    terraform
    # JetBrains
    jetbrains.webstorm
    jetbrains.datagrip
  ];
}
