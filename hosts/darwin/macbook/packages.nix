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
      nixd
    ])
    ++ [
      # fast-moving AI CLI, stable lags too far — same rationale as claude-code
      pkgsUnstable.opencode
    ];
}
