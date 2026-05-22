{
  pkgs,
  pkgsUnstable,
  ...
}: {
  environment.systemPackages = with pkgs;
    [
      doppler
      terraform
      qbittorrent
    ]
    ++ (with pkgsUnstable; [
      jetbrains.webstorm
      jetbrains.datagrip
    ]);
}
