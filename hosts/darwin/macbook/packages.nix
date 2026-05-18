{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    doppler
    terraform
    qbittorrent
    # JetBrains
    jetbrains.webstorm
    jetbrains.datagrip
  ];
}
