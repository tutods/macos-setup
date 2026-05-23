{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    doppler
    terraform
    qbittorrent
  ];
}
