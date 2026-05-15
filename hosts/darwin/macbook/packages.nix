{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    doppler
    terraform
    # JetBrains
    jetbrains.webstorm
    jetbrains.datagrip
  ];
}
