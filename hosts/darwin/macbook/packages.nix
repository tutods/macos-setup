{
  pkgs,
  pkgsUnstable,
  ...
}: {
  environment.systemPackages =
    (with pkgs; [
      doppler
      terraform
      qbittorrent
    ])
    ++ [
      pkgsUnstable.opencode
    ];
}
